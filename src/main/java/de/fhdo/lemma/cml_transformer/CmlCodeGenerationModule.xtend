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
		
		/*
		 * Retrieve the passed cml source model to work with (the above implementation
		 * of {@link getLanguageNamespace} tells the framework that this module shall
		 * work on cml source models).
		 */
		val ContextMappingModel cmlModel = (getResource().getContents().get(0) as ContextMappingModel)
		
		/* Instantiate Lemma DML by using a factory */
		val factory = new LemmaDomainDataModelFactory(cmlModel)
		val lemmaDataModel = factory.generateDataModel()
		// System.out.println(DomainDataModelCodeGenerator.printDataModel(lemmaDataModel))
		val dataExtractor = new DataDslExtractor()
		System.out.println(dataExtractor.extractToString(lemmaDataModel))
		for (ctx: lemmaDataModel.contexts) {
			val ctxPath = '''«getTargetFolder()»«File::separator»domain«File::separator»«ctx.name».data'''.toString
			val ctxCode = dataExtractor.extractToString(ctx)
			resultMap.put(ctxPath, ctxCode)
		}
		
		/* 
		 * Technologies are created with the {@link LemmaTechnologyFactory} which is used
		 * in the {@link LemmaServiceModelFactory}. 
		 * This list keeps track of all created technologies in order to put them into separate files.
		 */
		 val technologies = <Technology> newLinkedList
		
		/* For every context of the dataModel instantiate a Lemma SML by using a factory */
		for (ctx: lemmaDataModel.contexts) {
			val serviceModelFactory = new LemmaServiceModelFactory(cmlModel, ctx, technologies)
			val serviceModel = serviceModelFactory.buildServiceModel()
			val serviceExtractor = new ServiceDslExtractor()
			
			val servicePath = '''«getTargetFolder()»«File::separator»microservices«File::separator»«ctx.name».services'''.toString
			val serviceCode = serviceExtractor.extractToString(serviceModel)
			resultMap.put(servicePath, serviceCode)
			System.out.println(serviceCode)
		}
		
		/* Every created Technology Model will be put in a separate file */
		val technologyExtractor = new TechnologyDslExtractor()
		for (technology: technologies) {
			val technologyPath = '''«getTargetFolder()»«File::separator»technology«File::separator»«technology.name».technology'''.toString
			val technologyCode = technologyExtractor.extractToString(technology).toString
			resultMap.put(technologyPath, technologyCode)
			System.out.println(technologyCode)
		}
		
		return withCharset(resultMap, StandardCharsets::UTF_8.name())
	}

}
