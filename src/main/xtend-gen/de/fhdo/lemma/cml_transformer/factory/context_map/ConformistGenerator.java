package de.fhdo.lemma.cml_transformer.factory.context_map;

import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataModel;
import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

/**
 * Implements the Conformist relationship by inserting the exposed aggregates of the upstream context into the domain
 * of the downstream context.
 */
@SuppressWarnings("all")
public class ConformistGenerator extends AbstractRelationshipGenerator {
  public ConformistGenerator(final Context context, final ContextMap map) {
    super(context, map, CollectionLiterals.<DataModel>newLinkedList());
  }
  
  /**
   * Creates new domain objects (Data Modeling Language) for every exposed aggregate of the upstream context in the downstream context
   */
  @Override
  public void map() {
    final List<Relationship> rr = this.filter();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    final Consumer<Relationship> _function = (Relationship rel) -> {
      final Consumer<Aggregate> _function_1 = (Aggregate agg) -> {
        final List<ComplexType> cTypes = DomainDataModelFactory.mapAggregate2ComplexType(agg);
        for (final ComplexType cType : cTypes) {
          {
            final Predicate<ComplexType> _function_2 = (ComplexType checkMe) -> {
              return checkMe.getName().equals(cType.getName());
            };
            final Optional<ComplexType> checkComplexType = this.targetCtx.getComplexTypes().stream().filter(_function_2).findAny();
            boolean _isPresent = checkComplexType.isPresent();
            boolean _not = (!_isPresent);
            if (_not) {
              this.targetCtx.getComplexTypes().add(cType);
            }
          }
        }
      };
      ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates().stream().forEach(_function_1);
    };
    rr.stream().forEach(_function);
  }
  
  /**
   * Filter the context maps where the targetBc is the downstream context since a Conformist is placed in a downstream context and the context mapping is CF
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
      return ((UpstreamDownstreamRelationship) rel).getDownstreamRoles().contains(DownstreamRole.CONFORMIST);
    };
    return this.inputMap.getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
