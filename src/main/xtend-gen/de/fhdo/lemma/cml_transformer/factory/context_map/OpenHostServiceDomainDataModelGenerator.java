package de.fhdo.lemma.cml_transformer.factory.context_map;

import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.ComplexTypeFeature;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.PrimitiveType;
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
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

/**
 * Downstream implementation of an OHS
 * 
 * Adds a new Application Service in the {@link DataModel} that represents an "Accessor". Its task is to communicate with
 * the Api of the OHS upstream that exposes an aggregate
 */
@SuppressWarnings("all")
public class OpenHostServiceDomainDataModelGenerator {
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  /**
   * Mapped LEMMA DML {@link Context} which receives an Accessor
   */
  private Context context;
  
  /**
   * The whole LEMMA DML Model in order to find the upstream part of the OHS relation.
   */
  private DataModel dataModel;
  
  /**
   * Context Map of the CML Model which contains  OHS-relations of the LEMMA DML {@link Context}. The {@link Context} must have the same name
   * as the {@link BoundedContext} in the Context Map in order to map them.
   */
  private ContextMap map;
  
  public OpenHostServiceDomainDataModelGenerator(final Context context, final DataModel dataModel, final ContextMap map) {
    this.context = context;
    this.dataModel = dataModel;
    this.map = map;
  }
  
  public void mapOhsDownstream() {
    final List<Relationship> rr = this.filterDownstreamRelationships();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    for (final Relationship rel : rr) {
      {
        final BoundedContext upstreamBoundedContext = ((UpstreamDownstreamRelationship) rel).getUpstream();
        final Predicate<Context> _function = (Context context) -> {
          return context.getName().equals(upstreamBoundedContext.getName());
        };
        final Consumer<Context> _function_1 = (Context upstreamContext) -> {
          EList<Aggregate> _upstreamExposedAggregates = ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates();
          for (final Aggregate exposedAggregate : _upstreamExposedAggregates) {
            {
              final Predicate<ComplexType> _function_2 = (ComplexType cType) -> {
                String _name = cType.getName();
                String _name_1 = exposedAggregate.getName();
                String _plus = (_name_1 + "Api");
                return _name.equals(_plus);
              };
              final Optional<ComplexType> appService = upstreamContext.getComplexTypes().stream().filter(_function_2).findFirst();
              final Predicate<ComplexType> _function_3 = (ComplexType cType) -> {
                String _name = cType.getName();
                String _name_1 = exposedAggregate.getName();
                String _plus = (_name_1 + "Accessor");
                return _name.equals(_plus);
              };
              final Optional<ComplexType> accessorService = this.context.getComplexTypes().stream().filter(_function_3).findFirst();
              if ((appService.isPresent() && (!accessorService.isPresent()))) {
                ComplexType _get = appService.get();
                final DataStructure newAccessorService = this.mapApplicationServiceToAccessor(((DataStructure) _get));
                this.context.getComplexTypes().add(newAccessorService);
              }
            }
          }
        };
        this.dataModel.getContexts().stream().filter(_function).findFirst().ifPresent(_function_1);
      }
    }
  }
  
  /**
   * Maps an Application Service that represents the API exposing an Aggregate to another Application Service that
   * represents an Accessor accessing the API
   */
  private DataStructure mapApplicationServiceToAccessor(final DataStructure appService) {
    final DataStructure accessor = OpenHostServiceDomainDataModelGenerator.DATA_FACTORY.createDataStructure();
    accessor.setName(appService.getName().replace("Api", "Accessor"));
    accessor.getFeatures().add(ComplexTypeFeature.APPLICATION_SERVICE);
    final Consumer<DataOperation> _function = (DataOperation appServiceOp) -> {
      final Function1<DataOperationParameter, Boolean> _function_1 = (DataOperationParameter param) -> {
        return Boolean.valueOf(((param.getComplexType() != null) && param.getComplexType().getName().contains("Dto")));
      };
      final Iterable<DataOperationParameter> dto = IterableExtensions.<DataOperationParameter>filter(appServiceOp.getParameters(), _function_1);
      int _size = IterableExtensions.size(dto);
      int _size_1 = appServiceOp.getParameters().size();
      boolean _equals = (_size == _size_1);
      if (_equals) {
        accessor.getOperations().add(EcoreUtil.<DataOperation>copy(appServiceOp));
      } else {
        final Predicate<DataOperationParameter> _function_2 = (DataOperationParameter param) -> {
          PrimitiveType _primitiveType = param.getPrimitiveType();
          return (_primitiveType != null);
        };
        final List<DataOperationParameter> primitives = appServiceOp.getParameters().stream().filter(_function_2).collect(Collectors.<DataOperationParameter>toList());
        int _size_2 = primitives.size();
        int _size_3 = appServiceOp.getParameters().size();
        boolean _equals_1 = (_size_2 == _size_3);
        if (_equals_1) {
          accessor.getOperations().add(EcoreUtil.<DataOperation>copy(appServiceOp));
        }
      }
    };
    appService.getOperations().forEach(_function);
    return accessor;
  }
  
  /**
   * Filter the relations where {@link Context} is the downstream of a OHS relation. The {@link Context} must have the same name
   * as the {@link BoundedContext} in the relation in order to map them.
   */
  private List<Relationship> filterDownstreamRelationships() {
    final Predicate<Relationship> _function = (Relationship rel) -> {
      return (rel instanceof UpstreamDownstreamRelationship);
    };
    final Predicate<Relationship> _function_1 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getDownstream().getName().equals(this.context.getName());
    };
    final Predicate<Relationship> _function_2 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstreamRoles().contains(UpstreamRole.OPEN_HOST_SERVICE);
    };
    return this.map.getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
