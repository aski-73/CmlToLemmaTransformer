package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.datadsl.extractor.DataDslExtractor;
import de.fhdo.lemma.model_processing.annotations.CodeGenerationModule;
import de.fhdo.lemma.model_processing.builtin_phases.code_generation.AbstractCodeGenerationModule;
import java.io.File;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import kotlin.Pair;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingDSLPackage;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.jetbrains.annotations.NotNull;

/**
 * LEMMA's model processing framework supports model-based structuring of code
 * generators. This class implements a code generation module as expected by the
 * framework, i.e., the class receives the{@link CodeGenerationModule}annotation and extends{@link AbstractCodeGenerationModule}.
 */
@CodeGenerationModule(name = "main")
@SuppressWarnings("all")
public class CmlCodeGenerationModule extends AbstractCodeGenerationModule {
  /**
   * Return the namespace of the modeling language, from whose models code can be
   * generated
   */
  @NotNull
  @Override
  public String getLanguageNamespace() {
    return ContextMappingDSLPackage.eNS_URI;
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
  @NotNull
  @Override
  public Map<String, Pair<String, Charset>> execute(@NotNull final String[] phaseArguments, @NotNull final String[] moduleArguments) {
    StringBuilder resultFileContents = new StringBuilder();
    EObject _get = this.getResource().getContents().get(0);
    ContextMappingModel cmlModel = ((ContextMappingModel) _get);
    LemmaDomainDataModelFactory factory = new LemmaDomainDataModelFactory(cmlModel);
    DataModel lemmaDataModel = factory.generateDataModel();
    final DataDslExtractor dataExtractor = new DataDslExtractor();
    System.out.println(dataExtractor.extractToString(lemmaDataModel));
    StringConcatenation _builder = new StringConcatenation();
    String _targetFolder = this.getTargetFolder();
    _builder.append(_targetFolder);
    _builder.append(File.separator);
    _builder.append("results.txt");
    String resultFilePath = _builder.toString();
    Map<String, String> resultMap = new HashMap<String, String>();
    resultMap.put(resultFilePath, resultFileContents.toString());
    return this.withCharset(resultMap, StandardCharsets.UTF_8.name());
  }
}
