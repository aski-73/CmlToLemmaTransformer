package de.fhdo.lemma.cml_transformer.factory.context_map;

import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import java.util.List;
import java.util.function.Consumer;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;

/**
 * Implements the Conformist relationship by inserting the exposed aggregates of the upstream context into the domain
 * of the downstream context.
 */
@SuppressWarnings("all")
public class ConformistGenerator {
  /**
   * CML Model that contains a context Map of the CML Model. Itcontains  ACL-relations of the LEMMA DML {@value context}.
   * The {@link Context} must have the same name as the {@link BoundedContext} in the Context Map in order to map them.
   */
  private ContextMappingModel cmlModel;
  
  /**
   * Mapped LEMMA DML {@link Context} which receives an Translator
   */
  private Context context;
  
  private LemmaDomainDataModelFactory dmlFactory;
  
  public ConformistGenerator(final Context context, final ContextMappingModel cmlModel, final LemmaDomainDataModelFactory dmlFactory) {
    this.context = context;
    this.cmlModel = cmlModel;
    this.dmlFactory = dmlFactory;
  }
  
  /**
   * Creates new domain objects (Data Modeling Language) for every exposed aggregate of the upstream context in the downstream context
   */
  public void mapCof() {
    final List<Relationship> rr = this.filter();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    final Consumer<Relationship> _function = (Relationship rel) -> {
      final Consumer<Aggregate> _function_1 = (Aggregate agg) -> {
        final List<ComplexType> cTypes = LemmaDomainDataModelFactory.mapAggregate2ComplexType(this.cmlModel, agg);
        this.context.getComplexTypes().addAll(cTypes);
        this.context.getComplexTypes().addAll(this.dmlFactory.getListsToGenerate());
      };
      ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates().stream().forEach(_function_1);
    };
    rr.stream().forEach(_function);
  }
  
  /**
   * Filter the context maps where the targetBc is the downstream context since a Conformist is placed in a downstream context and the context mapping is CF
   */
  private List<Relationship> filter() {
    final Predicate<Relationship> _function = (Relationship rel) -> {
      return (rel instanceof UpstreamDownstreamRelationship);
    };
    final Predicate<Relationship> _function_1 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getDownstream().getName().equals(this.context.getName());
    };
    final Predicate<Relationship> _function_2 = (Relationship rel) -> {
      return ((UpstreamDownstreamRelationship) rel).getDownstreamRoles().contains(DownstreamRole.CONFORMIST);
    };
    return this.cmlModel.getMap().getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
