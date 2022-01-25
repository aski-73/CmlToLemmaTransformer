package de.fhdo.lemma.cml_transformer.factory.context_map;

import de.fhdo.lemma.cml_transformer.Util;
import de.fhdo.lemma.cml_transformer.factory.TechnologyModelFactory;
import de.fhdo.lemma.cml_transformer.technologies.CustomTechnology;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.PrimitiveType;
import de.fhdo.lemma.service.Endpoint;
import de.fhdo.lemma.service.Import;
import de.fhdo.lemma.service.ImportType;
import de.fhdo.lemma.service.ImportedProtocolAndDataFormat;
import de.fhdo.lemma.service.ImportedServiceAspect;
import de.fhdo.lemma.service.ImportedType;
import de.fhdo.lemma.service.Interface;
import de.fhdo.lemma.service.Microservice;
import de.fhdo.lemma.service.Operation;
import de.fhdo.lemma.service.Parameter;
import de.fhdo.lemma.service.ReferredOperation;
import de.fhdo.lemma.service.ServiceFactory;
import de.fhdo.lemma.service.ServiceModel;
import de.fhdo.lemma.technology.CommunicationType;
import de.fhdo.lemma.technology.ExchangePattern;
import de.fhdo.lemma.technology.Technology;
import java.util.LinkedList;
import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Pair;

/**
 * Upstream implementation of an OHS
 * 
 * Adds service {@link Interface} for every Application Service that exposes an aggregate.
 * The {@link ApplicationService} must follow the naming rule "ExposedAggregate"+"API".
 * If such an {@link ApplicationService} is not defined nothing will be done.
 */
@SuppressWarnings("all")
public class OpenHostServiceUpstreamGenerator extends AbstractRelationshipGenerator {
  private static final ServiceFactory SERVICE_FACTORY = ServiceFactory.eINSTANCE;
  
  /**
   * List of LEMMA {@link Technology}-Model. Newly created technologies that are identified
   * by the implementationTechnology key word will be put in here
   */
  private List<Technology> technologies;
  
  /**
   * The service model that contains the microservice. Needed in order to add the imports
   */
  private ServiceModel serviceModel;
  
  /**
   * LEMMA {@link Microservice} that will get a new {@link ServiceInterface}. Either Api or Accessor. Depends on if its a upstream/downstream context.
   */
  private Microservice service;
  
  private String domainDataModelPath;
  
  private String technologyModelPath;
  
  private final TechnologyModelFactory techFactory;
  
  public OpenHostServiceUpstreamGenerator(final Context context, final ServiceModel serviceModel, final Microservice service, final ContextMap map, final String domainDataModelPath, final String technologyModelPath, final List<Technology> technologies) {
    super(context, map, CollectionLiterals.<DataModel>newLinkedList());
    this.serviceModel = serviceModel;
    this.service = service;
    this.domainDataModelPath = domainDataModelPath;
    this.technologyModelPath = technologyModelPath;
    this.technologies = technologies;
    TechnologyModelFactory _technologyModelFactory = new TechnologyModelFactory(technologyModelPath);
    this.techFactory = _technologyModelFactory;
  }
  
  /**
   * The OHS upstream context receives service {@link Interface}s for every Application Service that is
   * responsible for exposing the exposed aggregate.
   * The Application Service must follow the naming rule "ExposedAggregateName"+"Api".
   * The service {@link Interface} will have equivalent operations like the Application Service of the {@link DataModel}
   */
  @Override
  public void map() {
    final List<Relationship> rr = this.filter();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    for (final Relationship rel : rr) {
      final Consumer<Aggregate> _function = (Aggregate agg) -> {
        final Predicate<ComplexType> _function_1 = (ComplexType cType) -> {
          String _name = cType.getName();
          String _name_1 = agg.getName();
          String _plus = (_name_1 + "Api");
          return _name.equals(_plus);
        };
        final Optional<ComplexType> appService = this.targetCtx.getComplexTypes().stream().filter(_function_1).findFirst();
        boolean _isPresent = appService.isPresent();
        if (_isPresent) {
          final CustomTechnology cTechnology = this.techFactory.generateTechnologymodel(rel.getImplementationTechnology());
          ComplexType _get = appService.get();
          final Pair<Interface, List<Import>> interfaceImportPair = this.mapApplicationServiceToServiceInterface(((DataStructure) _get), cTechnology);
          this.service.getInterfaces().add(interfaceImportPair.getKey());
          this.serviceModel.getImports().addAll(interfaceImportPair.getValue());
          boolean _technologyExists = Util.technologyExists(this.technologies, cTechnology.getTechnology());
          boolean _not = (!_technologyExists);
          if (_not) {
            this.technologies.add(cTechnology.getTechnology());
          }
        }
      };
      ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates().stream().forEach(_function);
    }
  }
  
  /**
   * TODO Must also use the CML Application Service in order to get the visibilty of the operations
   * 
   * Maps a LEMMA Application Service to a LEMMA SML {@link Interface}
   * See sml/metamodel-interfaces-operations.uxf and sml/metamodel-endpoints.uxf for reference
   * 
   * @return Pair: Mapped Interface -> List with the used imports
   */
  private Pair<Interface, List<Import>> mapApplicationServiceToServiceInterface(final DataStructure appService, final CustomTechnology cTechnology) {
    final Interface interface_ = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createInterface();
    interface_.setName(appService.getName());
    final LinkedList<Import> imports = CollectionLiterals.<Import>newLinkedList();
    EList<DataOperation> _operations = appService.getOperations();
    if (_operations!=null) {
      final Consumer<DataOperation> _function = (DataOperation appServiceOp) -> {
        final Operation serviceOp = this.mapDataOperationToServiceOperation(appServiceOp, imports);
        if ((cTechnology != null)) {
          final ImportedServiceAspect importedServiceAspect = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createImportedServiceAspect();
          importedServiceAspect.setImportedAspect(cTechnology.mapMethodNamesToServiceAspect(serviceOp.getName()));
          importedServiceAspect.setImport(Util.returnImportForTechnology(cTechnology.getTechnology(), this.technologyModelPath));
          final ImportedProtocolAndDataFormat importedProtocol = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createImportedProtocolAndDataFormat();
          importedProtocol.setDataFormat(cTechnology.getTechnology().getProtocols().get(0).getDataFormats().get(0));
          importedProtocol.setImportedProtocol(cTechnology.getTechnology().getProtocols().get(0));
          importedProtocol.setImport(Util.returnImportForTechnology(cTechnology.getTechnology(), this.technologyModelPath));
          final Endpoint endpoint = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createEndpoint();
          EList<String> _addresses = endpoint.getAddresses();
          String _name = interface_.getName();
          String _plus = ("/" + _name);
          _addresses.add(_plus);
          endpoint.getProtocols().add(importedProtocol);
          serviceOp.getEndpoints().add(endpoint);
          serviceOp.getAspects().add(importedServiceAspect);
          final Import technologyImport = Util.returnImportForTechnology(cTechnology.getTechnology(), this.technologyModelPath);
          boolean _importExists = Util.importExists(imports, technologyImport);
          boolean _not = (!_importExists);
          if (_not) {
            imports.add(technologyImport);
          }
        }
        interface_.getOperations().add(serviceOp);
      };
      _operations.forEach(_function);
    }
    return Pair.<Interface, List<Import>>of(interface_, imports);
  }
  
  /**
   * Maps LEMMA {@link DataOperation} to a {@link ReferredOperation] of a {@link ServiceInterface}
   */
  private ReferredOperation mapDataOperationToReferredOperation(final DataOperation dataOperation, final List<Import> imports) {
    final ReferredOperation referredOperation = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createReferredOperation();
    referredOperation.setOperation(this.mapDataOperationToServiceOperation(dataOperation, imports));
    return referredOperation;
  }
  
  /**
   * Maps LEMMA {@link DataOperation} to a {@link Operation} of a {@link ServiceInterface}
   */
  private Operation mapDataOperationToServiceOperation(final DataOperation dataOperation, final List<Import> imports) {
    final Operation operation = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createOperation();
    operation.setName(dataOperation.getName());
    boolean _isHasNoReturnType = dataOperation.isHasNoReturnType();
    boolean _not = (!_isHasNoReturnType);
    if (_not) {
      final Parameter returnParam = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createParameter();
      returnParam.setName("returnParam");
      ComplexType _complexReturnType = dataOperation.getComplexReturnType();
      boolean _tripleNotEquals = (_complexReturnType != null);
      if (_tripleNotEquals) {
        returnParam.setCommunicationType(CommunicationType.SYNCHRONOUS);
        final ImportedType importedType = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createImportedType();
        final Import paramTypeImport = this.returnImportForComplexType(dataOperation.getComplexReturnType());
        importedType.setImport(paramTypeImport);
        returnParam.setImportedType(importedType);
        ImportedType _importedType = returnParam.getImportedType();
        _importedType.setType(EcoreUtil.<ComplexType>copy(dataOperation.getComplexReturnType()));
        final Import paramTypeImportClone = EcoreUtil.<Import>copy(paramTypeImport);
        boolean _importExists = Util.importExists(imports, paramTypeImportClone);
        boolean _not_1 = (!_importExists);
        if (_not_1) {
          imports.add(paramTypeImportClone);
        }
      } else {
        returnParam.setPrimitiveType(EcoreUtil.<PrimitiveType>copy(dataOperation.getPrimitiveReturnType()));
      }
      returnParam.setExchangePattern(ExchangePattern.OUT);
      operation.getParameters().add(returnParam);
    }
    final Consumer<DataOperationParameter> _function = (DataOperationParameter param) -> {
      final Parameter serviceOpParam = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createParameter();
      serviceOpParam.setName(param.getName());
      ComplexType _complexType = param.getComplexType();
      boolean _tripleNotEquals_1 = (_complexType != null);
      if (_tripleNotEquals_1) {
        serviceOpParam.setCommunicationType(CommunicationType.SYNCHRONOUS);
        final ImportedType importedType_1 = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createImportedType();
        final Import complexTypeImport = this.returnImportForComplexType(param.getComplexType());
        importedType_1.setImport(complexTypeImport);
        serviceOpParam.setImportedType(importedType_1);
        ImportedType _importedType_1 = serviceOpParam.getImportedType();
        _importedType_1.setType(EcoreUtil.<ComplexType>copy(param.getComplexType()));
        final Import complexTypeImportClone = EcoreUtil.<Import>copy(complexTypeImport);
        boolean _importExists_1 = Util.importExists(imports, complexTypeImportClone);
        boolean _not_2 = (!_importExists_1);
        if (_not_2) {
          imports.add(complexTypeImportClone);
        }
      } else {
        serviceOpParam.setPrimitiveType(EcoreUtil.<PrimitiveType>copy(param.getPrimitiveType()));
      }
      operation.getParameters().add(serviceOpParam);
    };
    dataOperation.getParameters().forEach(_function);
    return operation;
  }
  
  /**
   * Builds a {@link Import} for a {@link ComplexType} which must be located in targetCtx.
   * A microservice can only import types from the own data model since one team is responsible
   * for all of their domain concepts.
   */
  private Import returnImportForComplexType(final ComplexType cType) {
    final Import import_ = OpenHostServiceUpstreamGenerator.SERVICE_FACTORY.createImport();
    import_.setName(this.targetCtx.getName());
    String _name = this.targetCtx.getName();
    String _plus = ((this.domainDataModelPath + "/") + _name);
    String _plus_1 = (_plus + ".data");
    import_.setImportURI(_plus_1);
    import_.setImportType(ImportType.DATATYPES);
    import_.setT_relatedImportAlias(this.targetCtx.getName());
    final Predicate<ComplexType> _function = (ComplexType tempComplexType) -> {
      return tempComplexType.getName().equals(cType.getName());
    };
    final Optional<ComplexType> check = this.targetCtx.getComplexTypes().stream().filter(_function).findAny();
    boolean _isEmpty = check.isEmpty();
    if (_isEmpty) {
      String _name_1 = cType.getName();
      String _plus_2 = ("Complex Type " + _name_1);
      String _plus_3 = (_plus_2 + " doesn\'t exist in context ");
      String _name_2 = this.targetCtx.getName();
      String _plus_4 = (_plus_3 + _name_2);
      System.out.println(_plus_4);
    }
    return import_;
  }
  
  /**
   * Filter the relations where {@link Context} is the upstream of a OHS relation. The {@link Context} must have the same name
   * as the {@link BoundedContext} in the relation in order to map them.
   */
  @Override
  public List<Relationship> filter() {
    final Predicate<Relationship> _function = (Relationship rel) -> {
      return (rel instanceof UpstreamDownstreamRelationship);
    };
    final Predicate<Relationship> _function_1 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstream().getName().equals(this.targetCtx.getName());
    };
    final Predicate<Relationship> _function_2 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstreamRoles().contains(UpstreamRole.OPEN_HOST_SERVICE);
    };
    return this.inputMap.getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
