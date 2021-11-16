package de.fhdo.lemma.cml_transformer.factory;

import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.service.Import;
import de.fhdo.lemma.service.ImportType;
import de.fhdo.lemma.service.ImportedType;
import de.fhdo.lemma.service.Interface;
import de.fhdo.lemma.service.Microservice;
import de.fhdo.lemma.service.Operation;
import de.fhdo.lemma.service.Parameter;
import de.fhdo.lemma.service.ReferredOperation;
import de.fhdo.lemma.service.ServiceFactory;
import de.fhdo.lemma.technology.CommunicationType;
import de.fhdo.lemma.technology.ExchangePattern;
import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole;
import org.eclipse.emf.common.util.EList;

/**
 * Upstream implementation of an OHS
 * 
 * Adds service {@link Interface} for every Application Service that exposes an aggregate.
 * The {@link ApplicationService} must follow the naming rule "ExposedAggregate"+"API".
 * If such an {@link ApplicationService} is not defined nothing will be done.
 */
@SuppressWarnings("all")
public class OpenHostServiceServiceModelGenerator {
  private static final String SERVICE_MODEL_IMPORT_ALIAS = "Services";
  
  private static final ServiceFactory SERVICE_FACTORY = ServiceFactory.eINSTANCE;
  
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  /**
   * Mapped LEMMA DML {@link Context} for which a Microservice will be generated
   */
  private Context context;
  
  /**
   * LEMMA {@link Microservice} that will get a new {@link ServiceInterface}. Either Api or Accessor. Depends on if its a upstream/downstream context.
   */
  private Microservice service;
  
  /**
   * Context Map of the CML Model which contains  OHS-relations of the LEMMA DML {@link Context}. The {@link Context} must have the same name
   * as the {@link BoundedContext} in the Context Map in order to map them.
   */
  private ContextMap map;
  
  private String domainDataModelPath;
  
  private String technologyModelPath;
  
  public OpenHostServiceServiceModelGenerator(final Context context, final Microservice service, final ContextMap map, final String domainDataModelPath, final String technologyModelPath) {
    this.context = context;
    this.service = service;
    this.map = map;
    this.domainDataModelPath = domainDataModelPath;
    this.technologyModelPath = technologyModelPath;
  }
  
  /**
   * The OHS upstream context receives service {@link Interface}s for every Application Service that is
   * responsible for exposing the exposed aggregate.
   * The Application Service must follow the naming rule "ExposedAggregateName"+"Api".
   * The service {@link Interface} will have equivalent operations like the Application Service of the {@link DataModel}
   */
  public void mapOhsUpstream() {
    final List<Relationship> rr = this.filterUpstreamRelationships();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    final Function<Relationship, Stream<Aggregate>> _function = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates().stream();
    };
    final Consumer<Aggregate> _function_1 = (Aggregate agg) -> {
      final Predicate<ComplexType> _function_2 = (ComplexType cType) -> {
        String _name = cType.getName();
        String _name_1 = agg.getName();
        String _plus = (_name_1 + "Api");
        return _name.equals(_plus);
      };
      final Optional<ComplexType> appService = this.context.getComplexTypes().stream().filter(_function_2).findFirst();
      boolean _isPresent = appService.isPresent();
      if (_isPresent) {
        ComplexType _get = appService.get();
        final Interface interface_ = this.mapApplicationServiceToServiceInterface(((DataStructure) _get));
        this.service.getInterfaces().add(interface_);
      }
    };
    rr.stream().<Aggregate>flatMap(_function).forEach(_function_1);
  }
  
  /**
   * Maps a LEMMA Application Service to a LEMMA SML {@link Interface}
   */
  private Interface mapApplicationServiceToServiceInterface(final DataStructure appService) {
    final Interface interface_ = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createInterface();
    interface_.setName(appService.getName());
    EList<DataOperation> _operations = appService.getOperations();
    if (_operations!=null) {
      final Consumer<DataOperation> _function = (DataOperation appServiceOp) -> {
        final Operation serviceOp = this.mapDataOperationToServiceOperation(appServiceOp);
        interface_.getOperations().add(serviceOp);
      };
      _operations.forEach(_function);
    }
    return interface_;
  }
  
  /**
   * Maps LEMMA {@link DataOperation} to a {@link ReferredOperation] of a {@link ServiceInterface}
   */
  private ReferredOperation mapDataOperationToReferredOperation(final DataOperation dataOperation) {
    final ReferredOperation referredOperation = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createReferredOperation();
    referredOperation.setOperation(this.mapDataOperationToServiceOperation(dataOperation));
    return referredOperation;
  }
  
  /**
   * Maps LEMMA {@link DataOperation} to a {@link Operation] of a {@link ServiceInterface}
   */
  private Operation mapDataOperationToServiceOperation(final DataOperation dataOperation) {
    final Operation operation = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createOperation();
    operation.setName(dataOperation.getName());
    boolean _isHasNoReturnType = dataOperation.isHasNoReturnType();
    boolean _not = (!_isHasNoReturnType);
    if (_not) {
      final Parameter returnParam = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createParameter();
      returnParam.setName("returnParam");
      ComplexType _complexReturnType = dataOperation.getComplexReturnType();
      boolean _tripleNotEquals = (_complexReturnType != null);
      if (_tripleNotEquals) {
        returnParam.setCommunicationType(CommunicationType.SYNCHRONOUS);
        final ImportedType importedType = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createImportedType();
        importedType.setImport(this.returnImportForComplexType(dataOperation.getComplexReturnType()));
        returnParam.setImportedType(importedType);
      } else {
        returnParam.setPrimitiveType(dataOperation.getPrimitiveReturnType());
      }
      returnParam.setExchangePattern(ExchangePattern.OUT);
      operation.getParameters().add(returnParam);
    }
    final Consumer<DataOperationParameter> _function = (DataOperationParameter param) -> {
      final Parameter serviceOpParam = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createParameter();
      serviceOpParam.setName(param.getName());
      ComplexType _complexType = param.getComplexType();
      boolean _tripleNotEquals_1 = (_complexType != null);
      if (_tripleNotEquals_1) {
        serviceOpParam.setCommunicationType(CommunicationType.SYNCHRONOUS);
        final ImportedType importedType_1 = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createImportedType();
        importedType_1.setImport(this.returnImportForComplexType(param.getComplexType()));
        serviceOpParam.setImportedType(importedType_1);
        ImportedType _importedType = serviceOpParam.getImportedType();
        _importedType.setType(param.getComplexType());
      } else {
        serviceOpParam.setPrimitiveType(param.getPrimitiveType());
      }
      operation.getParameters().add(serviceOpParam);
    };
    dataOperation.getParameters().forEach(_function);
    return operation;
  }
  
  /**
   * Builds a {@link Import for a {@link ComplexType} of the {@link DataModel}
   */
  private Import returnImportForComplexType(final ComplexType cType) {
    final Import import_ = OpenHostServiceServiceModelGenerator.SERVICE_FACTORY.createImport();
    import_.setName(cType.getName());
    String _name = cType.getName();
    String _plus = ((this.technologyModelPath + "/") + _name);
    String _plus_1 = (_plus + ".data");
    import_.setImportURI(_plus_1);
    import_.setImportType(ImportType.DATATYPES);
    import_.setT_relatedImportAlias(cType.getName());
    return import_;
  }
  
  /**
   * Filter the relations where {@link Context} is the upstream of a OHS relation. The {@link Context} must have the same name
   * as the {@link BoundedContext} in the relation in order to map them.
   */
  private List<Relationship> filterUpstreamRelationships() {
    final Predicate<Relationship> _function = (Relationship rel) -> {
      return (rel instanceof UpstreamDownstreamRelationship);
    };
    final Predicate<Relationship> _function_1 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstream().getName().equals(this.context.getName());
    };
    final Predicate<Relationship> _function_2 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstreamRoles().contains(UpstreamRole.OPEN_HOST_SERVICE);
    };
    return this.map.getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
