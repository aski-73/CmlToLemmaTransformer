package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.cml_transformer.code_generators.DataDslExtractor;
import de.fhdo.lemma.cml_transformer.code_generators.ServiceDslExtractor;
import de.fhdo.lemma.cml_transformer.code_generators.TechnologyDslExtractor;
import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory;
import de.fhdo.lemma.cml_transformer.factory.LemmaServiceModelFactory;
import de.fhdo.lemma.cml_transformer.factory.context_map.AnticorruptionLayerGenerator;
import de.fhdo.lemma.cml_transformer.factory.context_map.ConformistGenerator;
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceDownstreamGenerator;
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
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingDSLPackage;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;
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
    StringConcatenation _builder = new StringConcatenation();
    String _targetFolder = this.getTargetFolder();
    _builder.append(_targetFolder);
    _builder.append(File.separator);
    _builder.append("microservices");
    final String serviceModelPath = _builder.toString();
    StringConcatenation _builder_1 = new StringConcatenation();
    String _targetFolder_1 = this.getTargetFolder();
    _builder_1.append(_targetFolder_1);
    _builder_1.append(File.separator);
    _builder_1.append("domain");
    final String dataModelPath = _builder_1.toString();
    StringConcatenation _builder_2 = new StringConcatenation();
    String _targetFolder_2 = this.getTargetFolder();
    _builder_2.append(_targetFolder_2);
    _builder_2.append(File.separator);
    _builder_2.append("technology");
    final String technologyModelPath = _builder_2.toString();
    final LinkedList<Technology> technologies = CollectionLiterals.<Technology>newLinkedList();
    EObject _get = this.getResource().getContents().get(0);
    final ContextMappingModel cmlModel = ((ContextMappingModel) _get);
    final LinkedList<DataModel> dataModels = CollectionLiterals.<DataModel>newLinkedList();
    EList<BoundedContext> _boundedContexts = cmlModel.getBoundedContexts();
    for (final BoundedContext bc : _boundedContexts) {
      {
        final LemmaDomainDataModelFactory factory = new LemmaDomainDataModelFactory(cmlModel);
        final DataModel dataModel = factory.generateDataModel(bc);
        dataModels.add(dataModel);
      }
    }
    for (final DataModel dataModel : dataModels) {
      {
        final Context ctx = dataModel.getContexts().get(0);
        ContextMap _map = cmlModel.getMap();
        final OpenHostServiceDownstreamGenerator ohsGenerator = new OpenHostServiceDownstreamGenerator(ctx, dataModels, _map);
        ohsGenerator.mapOhsDownstream();
        final LinkedList<String> errors = CollectionLiterals.<String>newLinkedList();
        ContextMap _map_1 = cmlModel.getMap();
        final AnticorruptionLayerGenerator aclGenerator = new AnticorruptionLayerGenerator(ctx, dataModels, _map_1, errors);
        aclGenerator.mapAcl();
        LemmaDomainDataModelFactory _lemmaDomainDataModelFactory = new LemmaDomainDataModelFactory(cmlModel);
        final ConformistGenerator cofGenerator = new ConformistGenerator(ctx, cmlModel, _lemmaDomainDataModelFactory);
        cofGenerator.mapCof();
        Context _copy = EcoreUtil.<Context>copy(ctx);
        final LemmaServiceModelFactory serviceModelFactory = new LemmaServiceModelFactory(cmlModel, _copy, technologies);
        final ServiceModel serviceModel = serviceModelFactory.buildServiceModel(dataModelPath, serviceModelPath, technologyModelPath);
        final DataDslExtractor dataExtractor = new DataDslExtractor();
        System.out.println(dataExtractor.extractToString(dataModel));
        StringConcatenation _builder_3 = new StringConcatenation();
        _builder_3.append(dataModelPath);
        _builder_3.append(File.separator);
        String _name = ctx.getName();
        _builder_3.append(_name);
        _builder_3.append(".data");
        final String ctxPath = _builder_3.toString();
        final String ctxCode = dataExtractor.extractToString(ctx);
        resultMap.put(ctxPath, ctxCode);
        final ServiceDslExtractor serviceExtractor = new ServiceDslExtractor();
        StringConcatenation _builder_4 = new StringConcatenation();
        _builder_4.append(serviceModelPath);
        _builder_4.append(File.separator);
        String _name_1 = ctx.getName();
        _builder_4.append(_name_1);
        _builder_4.append(".services");
        final String servicePath = _builder_4.toString();
        final String serviceCode = serviceExtractor.extractToString(serviceModel);
        resultMap.put(servicePath, serviceCode);
        System.out.println(serviceCode);
      }
    }
    final TechnologyDslExtractor technologyExtractor = new TechnologyDslExtractor();
    for (final Technology technology : technologies) {
      {
        StringConcatenation _builder_3 = new StringConcatenation();
        _builder_3.append(technologyModelPath);
        _builder_3.append(File.separator);
        String _name = technology.getName();
        _builder_3.append(_name);
        _builder_3.append(".technology");
        final String technologyPath = _builder_3.toString();
        final String technologyCode = technologyExtractor.extractToString(technology).toString();
        resultMap.put(technologyPath, technologyCode);
        System.out.println(technologyCode);
      }
    }
    return this.withCharset(resultMap, StandardCharsets.UTF_8.name());
  }
}
