package de.fhdo.lemma.cml_transformer

import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory
import de.fhdo.lemma.model_processing.annotations.CodeGenerationModule
import de.fhdo.lemma.model_processing.builtin_phases.code_generation.AbstractCodeGenerationModule
import java.io.File
import java.nio.charset.Charset
import java.nio.charset.StandardCharsets
import java.util.HashMap
import java.util.Map
import kotlin.Pair
import org.contextmapper.dsl.contextMappingDSL.ContextMappingDSLPackage
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
import org.jetbrains.annotations.NotNull
import de.fhdo.lemma.cml_transformer.factory.LemmaServiceModelFactory
import de.fhdo.lemma.cml_transformer.code_generators.ServiceDslExtractor
import de.fhdo.lemma.cml_transformer.code_generators.DataDslExtractor
import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.cml_transformer.code_generators.TechnologyDslExtractor
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceDownstreamGenerator
import de.fhdo.lemma.cml_transformer.factory.context_map.AnticorruptionLayerGenerator
import de.fhdo.lemma.cml_transformer.factory.context_map.ConformistGenerator
import org.eclipse.emf.ecore.util.EcoreUtil

/** 
 * LEMMA's model processing framework supports model-based structuring of code
 * generators. This class implements a code generation module as expected by the
 * framework, i.e., the class receives the{@link CodeGenerationModule}annotation and extends{@link AbstractCodeGenerationModule}.
 */
@CodeGenerationModule(name="main") class CmlCodeGenerationModule extends AbstractCodeGenerationModule {
	/** 
	 * Return the namespace of the modeling language, from whose models code can be
	 * generated
	 */
	@NotNull override String getLanguageNamespace() {
		return ContextMappingDSLPackage::eNS_URI
	}

	/** 
	 * This method performs the actual code generation. The only requirement posed by LEMMA's
	 * model processing framework is that the{@link AbstractCodeGenerationModule#execute(String[], String[])}implementation of a code generation module returns a map with entries as
	 * follows: - Key: Path of a generated file. By default, the file must reside in
	 * the folder passed to the model processor in the "--target_model" commandline
	 * option (see below). - Value: A {@link Pair} instance, whose first
	 * component contains the generated file's content and whose second component
	 * identifies the content's {@link Charset}. From the map
	 * entries, LEMMA's code generation framework will write the generated files to
	 * the filesystem of the model processor user.
	 */
	@NotNull override Map<String, Pair<String, Charset>> execute(@NotNull String[] phaseArguments,
		@NotNull String[] moduleArguments) {
		val Map<String, String> resultMap = new HashMap()
		val serviceModelPath = '''«getTargetFolder()»«File::separator»microservices'''
		val dataModelPath = '''«getTargetFolder()»«File::separator»domain'''
		val technologyModelPath = '''«getTargetFolder()»«File::separator»technology'''

		/* 
		 * Technologies are created with the {@link LemmaTechnologyFactory} which is used
		 * in the {@link LemmaServiceModelFactory}. 
		 * This list keeps track of all created technologies in order to put them into separate files.
		 */
		val technologies = <Technology>newLinkedList

		/*
		 * Retrieve the passed cml source model to work with (the above implementation
		 * of {@link getLanguageNamespace} tells the framework that this module shall
		 * work on cml source models).
		 */
		val ContextMappingModel cmlModel = (getResource().getContents().get(0) as ContextMappingModel)

		/*
		 * Instantiate LEMMA DataModels by using a factory for each CML BoundedContext
		 */
		val dataModels = <DataModel>newLinkedList
		for (bc : cmlModel.boundedContexts) {
			val factory = new LemmaDomainDataModelFactory(cmlModel)
			val dataModel = factory.generateDataModel(bc)
			dataModels.add(dataModel)
		}

		/*
		 * Add Context Map Implementation for each Data Model. A single Context needs
		 * references to all created Context in order to implement the context map
		 * relations.
		 * E. g. a conformist (downstream) needs to know about the upstream context in order to 
		 * copy the exposed aggregates.
		 */
		for (dataModel : dataModels) {
			// Since a DataModels contains only one context get the first element of the list
			val ctx = dataModel.contexts.get(0)

			// Add Accessor for OHS API in the contexts which are OHS downstream contexts
			val ohsGenerator = new OpenHostServiceDownstreamGenerator(ctx, dataModels, cmlModel.map)
			ohsGenerator.mapOhsDownstream()

			// Add Anticorruption Layer if needed
			val errors = <String>newLinkedList
			val aclGenerator = new AnticorruptionLayerGenerator(ctx, dataModels, cmlModel.map, errors)
			aclGenerator.mapAcl()

			// Add Conformist if needed
			val cofGenerator = new ConformistGenerator(ctx, cmlModel, new LemmaDomainDataModelFactory(cmlModel))
			cofGenerator.mapCof()

			/* 
			 * Instantiate a Lemma ServiceModel by using a factory for the previously created Context.
			 * At the same time Technologies will be created if a specific one is identified in the CML Model 
			 */
			val serviceModelFactory = new LemmaServiceModelFactory(cmlModel, EcoreUtil.copy(ctx), technologies)
			val serviceModel = serviceModelFactory.buildServiceModel(dataModelPath, serviceModelPath,
				technologyModelPath)

			/*
			 * Code Generation DML
			 */
			val dataExtractor = new DataDslExtractor()
			System.out.println(dataExtractor.extractToString(dataModel))
			val ctxPath = '''«dataModelPath»«File::separator»«ctx.name».data'''.toString
			val ctxCode = dataExtractor.extractToString(ctx)
			resultMap.put(ctxPath, ctxCode)

			/*
			 * Code Generation SML
			 */
			val serviceExtractor = new ServiceDslExtractor()
			val servicePath = '''«serviceModelPath»«File::separator»«ctx.name».services'''.toString
			val serviceCode = serviceExtractor.extractToString(serviceModel)
			resultMap.put(servicePath, serviceCode)
			System.out.println(serviceCode)
		}

		/*
		 * Code Generation TML
		 */
		val technologyExtractor = new TechnologyDslExtractor()
		for (technology : technologies) {
			val technologyPath = '''«technologyModelPath»«File::separator»«technology.name».technology'''.toString
			val technologyCode = technologyExtractor.extractToString(technology).toString
			resultMap.put(technologyPath, technologyCode)
			System.out.println(technologyCode)
		}

		return withCharset(resultMap, StandardCharsets::UTF_8.name())
	}

}
