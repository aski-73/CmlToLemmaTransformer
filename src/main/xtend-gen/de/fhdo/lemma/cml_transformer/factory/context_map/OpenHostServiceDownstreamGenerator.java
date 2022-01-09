package de.fhdo.lemma.cml_transformer.factory.context_map;

import de.fhdo.lemma.cml_transformer.Util;
import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataModel;
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
import org.contextmapper.tactic.dsl.tacticdsl.Service;
import org.eclipse.emf.common.util.EList;

/**
 * Downstream implementation of an OHS
 * 
 * Adds a new Application Service in the {@link DataModel} that represents an "Accessor". Its task is to communicate with
 * the Api of the OHS upstream that exposes an aggregate
 */
@SuppressWarnings("all")
public class OpenHostServiceDownstreamGenerator extends AbstractRelationshipGenerator {
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  public OpenHostServiceDownstreamGenerator(final Context context, final ContextMap map, final List<DataModel> dataModels) {
    super(context, map, dataModels);
  }
  
  @Override
  public void map() {
    final List<Relationship> rr = this.filter();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    for (final Relationship rel : rr) {
      {
        final BoundedContext upstreamBoundedContext = ((UpstreamDownstreamRelationship) rel).getUpstream();
        final Function<DataModel, Stream<Context>> _function = (DataModel dataModel) -> {
          return dataModel.getContexts().stream();
        };
        final Stream<Context> allContexts = this.mappedDataModels.stream().<Context>flatMap(_function);
        final Predicate<Context> _function_1 = (Context context) -> {
          return context.getName().equals(upstreamBoundedContext.getName());
        };
        final Consumer<Context> _function_2 = (Context upstreamContext) -> {
          EList<Aggregate> _upstreamExposedAggregates = ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates();
          for (final Aggregate exposedAggregate : _upstreamExposedAggregates) {
            {
              final Predicate<Service> _function_3 = (Service cmlAppService) -> {
                String _name = cmlAppService.getName();
                String _name_1 = exposedAggregate.getName();
                String _plus = (_name_1 + "Api");
                return _name.equals(_plus);
              };
              final Optional<Service> appService = upstreamBoundedContext.getApplication().getServices().stream().filter(_function_3).findAny();
              final Predicate<ComplexType> _function_4 = (ComplexType cType) -> {
                String _name = cType.getName();
                String _name_1 = exposedAggregate.getName();
                String _plus = (_name_1 + "Accessor");
                return _name.equals(_plus);
              };
              final Optional<ComplexType> accessorService = this.targetCtx.getComplexTypes().stream().filter(_function_4).findFirst();
              if ((appService.isPresent() && accessorService.isEmpty())) {
                this.addAccessor(appService.get());
              }
            }
          }
        };
        allContexts.filter(_function_1).findFirst().ifPresent(_function_2);
      }
    }
  }
  
  /**
   * Maps an Application Service that represents the API exposing an Aggregate to another Application Service that
   * represents an Accessor accessing the API.
   * If the exposed aggregate is not in the
   * 
   * @param appService DML application service representing the upstream Api
   * @param exposedAggregate CML aggregate representing the aggregate that is accessed by the Accessor.
   */
  private void addAccessor(final Service apiService) {
    apiService.setName(apiService.getName().replace("Api", "Accessor"));
    final List<ComplexType> cTypes = DomainDataModelFactory.mapServiceToComplexType(apiService, false);
    Util.addComplexTypesIntoContext(this.targetCtx, cTypes);
  }
  
  /**
   * Filter the relations where {@link Context} is the downstream of a OHS relation. The {@link Context} must have the same name
   * as the {@link BoundedContext} in the relation in order to map them.
   */
  @Override
  public List<Relationship> filter() {
    final Predicate<Relationship> _function = (Relationship rel) -> {
      return (rel instanceof UpstreamDownstreamRelationship);
    };
    final Predicate<Relationship> _function_1 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getDownstream().getName().equals(this.targetCtx.getName());
    };
    final Predicate<Relationship> _function_2 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getUpstreamRoles().contains(UpstreamRole.OPEN_HOST_SERVICE);
    };
    return this.inputMap.getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
