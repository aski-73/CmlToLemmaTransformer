package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.cml_transformer.code_generators.DataDslExtractor;
import de.fhdo.lemma.cml_transformer.code_generators.ServiceDslExtractor;
import de.fhdo.lemma.cml_transformer.code_generators.TechnologyDslExtractor;
import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory;
import de.fhdo.lemma.cml_transformer.factory.ServiceModelFactory;
import de.fhdo.lemma.cml_transformer.factory.context_map.AnticorruptionLayerGenerator;
import de.fhdo.lemma.cml_transformer.factory.context_map.ConformistGenerator;
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceDownstreamGenerator;
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceUpstreamGenerator;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.model_processing.annotations.CodeGenerationModule;
import de.fhdo.lemma.model_processing.builtin_phases.code_generation.AbstractCodeGenerationModule;
import de.fhdo.lemma.service.Microservice;
import de.fhdo.lemma.service.ServiceModel;
import de.fhdo.lemma.technology.Technology;
import java.io.File;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
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
public class LemmaCodeGenerationModule extends AbstractCodeGenerationModule {
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
        final DomainDataModelFactory factory = new DomainDataModelFactory();
        final DataModel dataModel = factory.generateDataModel(bc);
        dataModels.add(dataModel);
      }
    }
    int _size = dataModels.size();
    final ArrayList<ServiceModel> serviceModels = new ArrayList<ServiceModel>(_size);
    for (final DataModel dataModel : dataModels) {
      {
        final Context ctx = dataModel.getContexts().get(0);
        ContextMap _map = cmlModel.getMap();
        final OpenHostServiceDownstreamGenerator ohsDownStreamGenerator = new OpenHostServiceDownstreamGenerator(ctx, _map, dataModels);
        ohsDownStreamGenerator.map();
        ContextMap _map_1 = cmlModel.getMap();
        final AnticorruptionLayerGenerator aclGenerator = new AnticorruptionLayerGenerator(ctx, _map_1, dataModels);
        aclGenerator.map();
        ContextMap _map_2 = cmlModel.getMap();
        final ConformistGenerator cofGenerator = new ConformistGenerator(ctx, _map_2);
        cofGenerator.map();
        Context _copy = EcoreUtil.<Context>copy(ctx);
        final ServiceModelFactory serviceModelFactory = new ServiceModelFactory(cmlModel, _copy);
        final ServiceModel serviceModel = serviceModelFactory.generateServiceModel(dataModelPath, serviceModelPath, technologyModelPath);
        Microservice _get_1 = serviceModel.getMicroservices().get(0);
        ContextMap _map_3 = cmlModel.getMap();
        final OpenHostServiceUpstreamGenerator ohsUpstreamGenerator = new OpenHostServiceUpstreamGenerator(ctx, serviceModel, _get_1, _map_3, dataModelPath, technologyModelPath, technologies);
        ohsUpstreamGenerator.map();
        serviceModels.add(serviceModel);
      }
    }
    for (final ServiceModel serviceModel : serviceModels) {
      {
        Util.addRequiredStatementIfDownstream(serviceModel, serviceModels, cmlModel.getMap(), serviceModelPath);
        Util.addInterfaceWithNoOpToEmptyMicroservice(serviceModel.getMicroservices().get(0));
      }
    }
    for (final DataModel dataModel_1 : dataModels) {
      {
        final Context ctx = dataModel_1.getContexts().get(0);
        final DataDslExtractor dataExtractor = new DataDslExtractor();
        System.out.println(dataExtractor.extractToString(dataModel_1));
        StringConcatenation _builder_3 = new StringConcatenation();
        _builder_3.append(dataModelPath);
        _builder_3.append(File.separator);
        String _name = ctx.getName();
        _builder_3.append(_name);
        _builder_3.append(".data");
        final String ctxPath = _builder_3.toString();
        final String ctxCode = dataExtractor.extractToString(ctx);
        resultMap.put(ctxPath, ctxCode);
      }
    }
    for (final ServiceModel serviceModel_1 : serviceModels) {
      {
        final Microservice service = serviceModel_1.getMicroservices().get(0);
        final ServiceDslExtractor serviceExtractor = new ServiceDslExtractor();
        StringConcatenation _builder_3 = new StringConcatenation();
        _builder_3.append(serviceModelPath);
        _builder_3.append(File.separator);
        String _returnSimpleNameOfMicroservice = Util.returnSimpleNameOfMicroservice(service);
        _builder_3.append(_returnSimpleNameOfMicroservice);
        _builder_3.append(".services");
        final String servicePath = _builder_3.toString();
        final String serviceCode = serviceExtractor.extractToString(serviceModel_1);
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
