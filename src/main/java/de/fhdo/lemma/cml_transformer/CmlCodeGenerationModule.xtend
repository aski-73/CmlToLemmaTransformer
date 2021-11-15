package de.fhdo.lemma.cml_transformer

import de.fhdo.lemma.cml_transformer.code_generators.DomainDataModelCodeGenerator
import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.datadsl.extractor.DataDslExtractor
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
	 * This method performs the actual code generation. Note that LEMMA's model
	 * processing does not assume a specific type of code generation. For instance,
	 * this simple implementation uses simple Java {@link String}s to store the
	 * generated code. However, you may use any mechanism to facilitate code
	 * generation, e.g., template engines. The only requirement posed by LEMMA's
	 * model processing framework is that the{@link AbstractCodeGenerationModule#execute(String[], String[])}implementation of a code generation module returns a map with entries as
	 * follows: - Key: Path of a generated file. By default, the file must reside in
	 * the folder passed to the model processor in the "--target_model" commandline
	 * option (see below). - Value: A {@link Pair} instance, whose first
	 * component contains the generated file's content and whose second component
	 * identifies the content's {@link Charset}. From the map
	 * entries, LEMMA's code generation framework will write the generated files to
	 * the filesystem of the model processor user.
	 * The method generates a file called "results.txt" in the given target folder
	 * (cf. the "run.sh" script). It will contain: - Per modeled microservice the
	 * count of modeled interfaces - Per modeled microservice the count of
	 * interfaces, which are "fully synchronous" (i.e., that contain only operations
	 * with synchronous parameters) - Per modeled microservice the count of
	 * interfaces, which are "fully asynchronous" (i.e., that contain only
	 * operations with asynchronous parameters) You can find the specifications for
	 * intermediate domain and service models here: - Intermediate Domain Model
	 * Specification:
	 * https://github.com/SeelabFhdo/lemma/tree/main/de.fhdo.lemma.data.intermediate.metamodel/doc/build/html
	 * - Intermediate Service Model Specification:
	 * https://github.com/SeelabFhdo/lemma/tree/main/de.fhdo.lemma.service.intermediate.metamodel/doc/build/html
	 */
	@NotNull override Map<String, Pair<String, Charset>> execute(@NotNull String[] phaseArguments,
		@NotNull String[] moduleArguments) {
		var StringBuilder resultFileContents = new StringBuilder()
		/*
		 * Retrieve the passed cml source model to work with (the above implementation
		 * of {@link getLanguageNamespace} tells the framework that this module shall
		 * work on cml source models).
		 */
		var ContextMappingModel cmlModel = (getResource().getContents().get(0) as ContextMappingModel)
		/* Instantiate Lemma DML by using a factory */
		var LemmaDomainDataModelFactory factory = new LemmaDomainDataModelFactory(cmlModel)
		var DataModel lemmaDataModel = factory.generateDataModel()
		// System.out.println(DomainDataModelCodeGenerator.printDataModel(lemmaDataModel))
		val dataExtractor = new DataDslExtractor()
		System.out.println(dataExtractor.extractToString(lemmaDataModel))
		/* Prepare the path of the generated file */
		var String resultFilePath = '''«getTargetFolder()»«File::separator»results.txt'''.toString
		var Map<String, String> resultMap = new HashMap()
		resultMap.put(resultFilePath, resultFileContents.toString())
		return withCharset(resultMap, StandardCharsets::UTF_8.name())
	}

}
