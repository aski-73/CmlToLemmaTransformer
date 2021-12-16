package de.fhdo.lemma.cml_transformer.factory.context_map;

import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.ComplexTypeFeature;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
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
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

/**
 * Adds a translator into the domain data model {@link DataModel}.
 * The translator translates between an exposed aggregate X of the upstream context and a domain object Y of
 * the downstream stream context (ACL). The domain object Y needs in the CML Model the keyword "hint" with a value conforming to
 * "ACL:EXPOSED_AGGREGATE_NAME" in order to tell the translator who X is.
 */
@SuppressWarnings("all")
public class AnticorruptionLayerGenerator extends AbstractRelationshipGenerator {
  /**
   * Container class that contains X and Y (see class description)
   * source = X
   * target = Y
   */
  @Data
  public static class FromTo {
    protected final DataStructure source;
    
    protected final DataStructure target;
    
    public FromTo(final DataStructure source, final DataStructure target) {
      super();
      this.source = source;
      this.target = target;
    }
    
    @Override
    @Pure
    public int hashCode() {
      final int prime = 31;
      int result = 1;
      result = prime * result + ((this.source== null) ? 0 : this.source.hashCode());
      return prime * result + ((this.target== null) ? 0 : this.target.hashCode());
    }
    
    @Override
    @Pure
    public boolean equals(final Object obj) {
      if (this == obj)
        return true;
      if (obj == null)
        return false;
      if (getClass() != obj.getClass())
        return false;
      AnticorruptionLayerGenerator.FromTo other = (AnticorruptionLayerGenerator.FromTo) obj;
      if (this.source == null) {
        if (other.source != null)
          return false;
      } else if (!this.source.equals(other.source))
        return false;
      if (this.target == null) {
        if (other.target != null)
          return false;
      } else if (!this.target.equals(other.target))
        return false;
      return true;
    }
    
    @Override
    @Pure
    public String toString() {
      ToStringBuilder b = new ToStringBuilder(this);
      b.add("source", this.source);
      b.add("target", this.target);
      return b.toString();
    }
    
    @Pure
    public DataStructure getSource() {
      return this.source;
    }
    
    @Pure
    public DataStructure getTarget() {
      return this.target;
    }
  }
  
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  /**
   * Checks if the given {@link ComplexType} already exists in the {@link Context}.
   * If not it will be added to the {@link Context}.
   * 
   * @return Found or newly created {@link ComplexType} of the given {@link Context}
   */
  public static ComplexType findComplexTypeAndCreateIfNotExisting(final ComplexType cType, final Context ctx) {
    EList<ComplexType> _complexTypes = ctx.getComplexTypes();
    for (final ComplexType c : _complexTypes) {
      boolean _equals = cType.getName().equals(c.getName());
      if (_equals) {
        return c;
      }
    }
    final ComplexType copyComplexType = EcoreUtil.<ComplexType>copy(cType);
    copyComplexType.setContext(ctx);
    ctx.getComplexTypes().add(copyComplexType);
    return copyComplexType;
  }
  
  private List<String> errors;
  
  public AnticorruptionLayerGenerator(final Context context, final ContextMap map, final List<DataModel> dataModels) {
    super(context, map, dataModels);
    this.errors = CollectionLiterals.<String>newLinkedList();
  }
  
  @Override
  public void map() {
    final List<Relationship> rr = this.filter();
    int _size = rr.size();
    boolean _equals = (_size == 0);
    if (_equals) {
      return;
    }
    Relationship _get = rr.get(0);
    final BoundedContext cmlDownstreamContext = ((UpstreamDownstreamRelationship) _get).getDownstream();
    final Consumer<Relationship> _function = (Relationship rel) -> {
      final BoundedContext cmlUpstreamContext = ((UpstreamDownstreamRelationship) rel).getUpstream();
      final Function<DataModel, Stream<Context>> _function_1 = (DataModel dataModel) -> {
        return dataModel.getContexts().stream();
      };
      final Stream<Context> allContexts = this.mappedDataModels.stream().<Context>flatMap(_function_1);
      final Predicate<Context> _function_2 = (Context ctx) -> {
        return ctx.getName().equals(cmlUpstreamContext.getName());
      };
      final Optional<Context> lemmaUpstreamContext = allContexts.filter(_function_2).findAny();
      boolean _isEmpty = lemmaUpstreamContext.isEmpty();
      if (_isEmpty) {
        StringConcatenation _builder = new StringConcatenation();
        _builder.append("Mapping Error: A Mapping of the CML context ");
        String _name = cmlUpstreamContext.getName();
        _builder.append(_name);
        _builder.append(" was not found.");
        this.errors.add(_builder.toString());
        return;
      }
      final Function<Aggregate, Stream<SimpleDomainObject>> _function_3 = (Aggregate agg) -> {
        return agg.getDomainObjects().stream();
      };
      final Predicate<SimpleDomainObject> _function_4 = (SimpleDomainObject obj) -> {
        return ((obj.getHint() != null) && obj.getHint().startsWith((DownstreamRole.ANTICORRUPTION_LAYER.getLiteral() + ":")));
      };
      final Function<SimpleDomainObject, SimpleDomainObject> _function_5 = (SimpleDomainObject obj) -> {
        String _hint = obj.getHint();
        String _literal = DownstreamRole.ANTICORRUPTION_LAYER.getLiteral();
        String _plus = (_literal + ":");
        obj.setHint(_hint.replace(_plus, ""));
        return obj;
      };
      final Function<SimpleDomainObject, AnticorruptionLayerGenerator.FromTo> _function_6 = (SimpleDomainObject obj) -> {
        boolean check = false;
        EList<Aggregate> _upstreamExposedAggregates = ((UpstreamDownstreamRelationship) rel).getUpstreamExposedAggregates();
        for (final Aggregate exposedAgg : _upstreamExposedAggregates) {
          boolean _equals_1 = exposedAgg.getName().equals(obj.getHint());
          if (_equals_1) {
            final Predicate<ComplexType> _function_7 = (ComplexType cType) -> {
              String _name_1 = cType.getName();
              String _name_2 = exposedAgg.getName();
              String _plus = (_name_2 + "Dto");
              return _name_1.equals(_plus);
            };
            final ComplexType x = lemmaUpstreamContext.get().getComplexTypes().stream().filter(_function_7).findAny().get();
            final Predicate<ComplexType> _function_8 = (ComplexType cType) -> {
              return cType.getName().equals(obj.getName());
            };
            final ComplexType y = this.targetCtx.getComplexTypes().stream().filter(_function_8).findAny().get();
            return new AnticorruptionLayerGenerator.FromTo(((DataStructure) x), ((DataStructure) y));
          }
        }
        if ((!check)) {
          String _hint = obj.getHint();
          String _plus = (_hint + " is not an exposed aggregate");
          this.errors.add(_plus);
        }
        return null;
      };
      final Predicate<AnticorruptionLayerGenerator.FromTo> _function_7 = (AnticorruptionLayerGenerator.FromTo fromTo) -> {
        return (fromTo != null);
      };
      final Consumer<AnticorruptionLayerGenerator.FromTo> _function_8 = (AnticorruptionLayerGenerator.FromTo fromTo) -> {
        final DataStructure aclTranslator = AnticorruptionLayerGenerator.DATA_FACTORY.createDataStructure();
        String _name_1 = fromTo.source.getName();
        String _plus = (_name_1 + "Translator");
        aclTranslator.setName(_plus);
        aclTranslator.getFeatures().add(ComplexTypeFeature.DOMAIN_SERVICE);
        final DataOperationParameter opParam = AnticorruptionLayerGenerator.DATA_FACTORY.createDataOperationParameter();
        opParam.setName(String.valueOf(fromTo.source.getName().charAt(0)).toLowerCase());
        opParam.setComplexType(AnticorruptionLayerGenerator.findComplexTypeAndCreateIfNotExisting(fromTo.source, this.targetCtx));
        final DataOperation op = AnticorruptionLayerGenerator.DATA_FACTORY.createDataOperation();
        StringConcatenation _builder_1 = new StringConcatenation();
        _builder_1.append("transform");
        String _name_2 = fromTo.source.getName();
        _builder_1.append(_name_2);
        _builder_1.append("To");
        String _name_3 = fromTo.target.getName();
        _builder_1.append(_name_3);
        op.setName(_builder_1.toString());
        op.setComplexReturnType(EcoreUtil.<DataStructure>copy(fromTo.target));
        op.getParameters().add(opParam);
        aclTranslator.getOperations().add(op);
        this.targetCtx.getComplexTypes().add(aclTranslator);
      };
      cmlDownstreamContext.getAggregates().stream().<SimpleDomainObject>flatMap(_function_3).filter(_function_4).<SimpleDomainObject>map(_function_5).<AnticorruptionLayerGenerator.FromTo>map(_function_6).filter(_function_7).forEach(_function_8);
    };
    rr.stream().forEach(_function);
  }
  
  /**
   * Filter the context maps where the {@value context} is the downstream context since an ACL is placed in a downstream context
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
      return ((UpstreamDownstreamRelationship) rel).getDownstreamRoles().contains(DownstreamRole.ANTICORRUPTION_LAYER);
    };
    return this.inputMap.getRelationships().stream().filter(_function).filter(_function_1).filter(_function_2).collect(Collectors.<Relationship>toList());
  }
}
