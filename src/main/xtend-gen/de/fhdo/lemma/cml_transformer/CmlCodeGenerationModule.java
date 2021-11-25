package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.cml_transformer.code_generators.DataDslExtractor;
import de.fhdo.lemma.cml_transformer.code_generators.ServiceDslExtractor;
import de.fhdo.lemma.cml_transformer.code_generators.TechnologyDslExtractor;
import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory;
import de.fhdo.lemma.cml_transformer.factory.LemmaServiceModelFactory;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.model_processing.annotations.CodeGenerationModule;
import de.fhdo.lemma.model_processing.builtin_phases.code_generation.AbstractCodeGenerationModule;
import de.fhdo.lemma.service.ServiceModel;
import de.fhdo.lemma.technology.Technology;
import java.io.File;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;
import kotlin.Pair;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingDSLPackage;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
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
  @NotNull
  @Override
  public Map<String, Pair<String, Charset>> execute(@NotNull final String[] phaseArguments, @NotNull final String[] moduleArguments) {
    final Map<String, String> resultMap = new HashMap<String, String>();
    EObject _get = this.getResource().getContents().get(0);
    final ContextMappingModel cmlModel = ((ContextMappingModel) _get);
    final LemmaDomainDataModelFactory factory = new LemmaDomainDataModelFactory(cmlModel);
    final DataModel lemmaDataModel = factory.generateDataModel();
    final DataDslExtractor dataExtractor = new DataDslExtractor();
    System.out.println(dataExtractor.extractToString(lemmaDataModel));
    EList<Context> _contexts = lemmaDataModel.getContexts();
    for (final Context ctx : _contexts) {
      {
        StringConcatenation _builder = new StringConcatenation();
        String _targetFolder = this.getTargetFolder();
        _builder.append(_targetFolder);
        _builder.append(File.separator);
        _builder.append("domain");
        _builder.append(File.separator);
        String _name = ctx.getName();
        _builder.append(_name);
        _builder.append(".data");
        final String ctxPath = _builder.toString();
        final String ctxCode = dataExtractor.extractToString(ctx);
        resultMap.put(ctxPath, ctxCode);
      }
    }
    final LinkedList<Technology> technologies = CollectionLiterals.<Technology>newLinkedList();
    EList<Context> _contexts_1 = lemmaDataModel.getContexts();
    for (final Context ctx_1 : _contexts_1) {
      {
        final LemmaServiceModelFactory serviceModelFactory = new LemmaServiceModelFactory(cmlModel, ctx_1, technologies);
        final ServiceModel serviceModel = serviceModelFactory.buildServiceModel();
        final ServiceDslExtractor serviceExtractor = new ServiceDslExtractor();
        StringConcatenation _builder = new StringConcatenation();
        String _targetFolder = this.getTargetFolder();
        _builder.append(_targetFolder);
        _builder.append(File.separator);
        _builder.append("microservices");
        _builder.append(File.separator);
        String _name = ctx_1.getName();
        _builder.append(_name);
        _builder.append(".services");
        final String servicePath = _builder.toString();
        final String serviceCode = serviceExtractor.extractToString(serviceModel);
        resultMap.put(servicePath, serviceCode);
        System.out.println(serviceCode);
      }
    }
    final TechnologyDslExtractor technologyExtractor = new TechnologyDslExtractor();
    for (final Technology technology : technologies) {
      {
        StringConcatenation _builder = new StringConcatenation();
        String _targetFolder = this.getTargetFolder();
        _builder.append(_targetFolder);
        _builder.append(File.separator);
        _builder.append("technology");
        _builder.append(File.separator);
        String _name = technology.getName();
        _builder.append(_name);
        _builder.append(".technology");
        final String technologyPath = _builder.toString();
        final String technologyCode = technologyExtractor.extractToString(technology).toString();
        resultMap.put(technologyPath, technologyCode);
        System.out.println(technologyCode);
      }
    }
    return this.withCharset(resultMap, StandardCharsets.UTF_8.name());
  }
}
