package de.fhdo.lemma.cml_transformer.factory;

import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.ComplexTypeFeature;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.Enumeration;
import de.fhdo.lemma.data.EnumerationField;
import de.fhdo.lemma.data.ListType;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.function.Consumer;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.contextmapper.tactic.dsl.tacticdsl.DomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.Entity;
import org.contextmapper.tactic.dsl.tacticdsl.EnumValue;
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.ValueObject;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

@SuppressWarnings("all")
public class LemmaDomainDataModelFactory {
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  /**
   * Maps CML Model {@link ContextMappingModel} to LEMMA DML Model {@link DataModel}
   */
  public DataModel generateDataModel(final ContextMappingModel cmlModel) {
    final DataModel dataModel = LemmaDomainDataModelFactory.DATA_FACTORY.createDataModel();
    final Consumer<BoundedContext> _function = (BoundedContext bc) -> {
      final Context ctx = this.mapBoundedContext2Context(bc);
      ctx.setDataModel(dataModel);
      dataModel.getContexts().add(ctx);
      dataModel.getComplexTypes().addAll(ctx.getComplexTypes());
    };
    cmlModel.getBoundedContexts().forEach(_function);
    return dataModel;
  }
  
  /**
   * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
   */
  private Context mapBoundedContext2Context(final BoundedContext bc) {
    final Context ctx = LemmaDomainDataModelFactory.DATA_FACTORY.createContext();
    final Consumer<Aggregate> _function = (Aggregate agg) -> {
      final List<ComplexType> dataStructures = this.mapAggregate2ComplexType(agg);
      final Consumer<ComplexType> _function_1 = (ComplexType struct) -> {
        struct.setContext(ctx);
        ctx.getComplexTypes().add(struct);
      };
      dataStructures.forEach(_function_1);
    };
    bc.getAggregates().forEach(_function);
    return ctx;
  }
  
  /**
   * Maps CML {@link Aggregate} to LEMMA DML {@link ComplexType}s.
   * 
   * Since CML aggregates all Domain Services, Entities and Value Objects, we need to extract those and put
   * them in a list in order to add them into the Lemma {@link Context}
   */
  private List<ComplexType> mapAggregate2ComplexType(final Aggregate agg) {
    final LinkedList<ComplexType> dataStructures = CollectionLiterals.<ComplexType>newLinkedList();
    final DataStructure lemmaAggregate = this.createDataStructure(agg.getName());
    dataStructures.add(lemmaAggregate);
    EList<SimpleDomainObject> _domainObjects = agg.getDomainObjects();
    for (final SimpleDomainObject obj : _domainObjects) {
      {
        final ComplexType lemmaStructure = this.mapSimpleDomainObject2ComplexType(obj);
        dataStructures.add(lemmaStructure);
      }
    }
    return dataStructures;
  }
  
  /**
   * Maps CML {@link SimpleDomainObject} (super class of {@link DomainObject} and {@link Enum})
   * to a LEMMA {@link ComplexType}.
   * In other words it creates DataStructures and Enums depending on the given {@link SimpleDomainObject}
   */
  private ComplexType mapSimpleDomainObject2ComplexType(final SimpleDomainObject sObj) {
    return this.mapDomainObject2ConcreteComplexType(sObj);
  }
  
  /**
   * Maps CML {@link ValueObject} and {@link Entity} to LEMMA DML {@link DataStructure}
   */
  private ComplexType _mapDomainObject2ConcreteComplexType(final DomainObject obj) {
    final DataStructure lemmaStructure = this.createDataStructure(obj.getName());
    ComplexTypeFeature _xifexpression = null;
    if ((obj instanceof Entity)) {
      _xifexpression = ComplexTypeFeature.ENTITY;
    } else {
      ComplexTypeFeature _xifexpression_1 = null;
      if ((obj instanceof ValueObject)) {
        _xifexpression_1 = ComplexTypeFeature.VALUE_OBJECT;
      } else {
        _xifexpression_1 = ComplexTypeFeature.DOMAIN_EVENT;
      }
      _xifexpression = _xifexpression_1;
    }
    final ComplexTypeFeature feature = _xifexpression;
    lemmaStructure.getFeatures().add(feature);
    return lemmaStructure;
  }
  
  /**
   * Maps CML {@link org.contextmapper.tactic.dsl.tacticdsl.Enum} to LEMMA DML {@link Enumeration}
   */
  private ComplexType _mapDomainObject2ConcreteComplexType(final org.contextmapper.tactic.dsl.tacticdsl.Enum obj) {
    final Enumeration lemmaEnum = this.createEnumeration(obj.getName());
    final Consumer<EnumValue> _function = (EnumValue enumValue) -> {
      lemmaEnum.getFields().add(this.createEnumerationField(enumValue.getName()));
    };
    obj.getValues().forEach(_function);
    return lemmaEnum;
  }
  
  /**
   * Create a new LEMMA DataModel from the given EObject instances
   */
  private DataModel createDataModel(final List<EObject> eObjects) {
    final DataModel dataModel = LemmaDomainDataModelFactory.DATA_FACTORY.createDataModel();
    return dataModel;
  }
  
  /**
   * Create a LEMMA Enumeration instance
   */
  private Enumeration createEnumeration(final String name) {
    final Enumeration enumeration = LemmaDomainDataModelFactory.DATA_FACTORY.createEnumeration();
    enumeration.setName(name);
    return enumeration;
  }
  
  /**
   * Create a LEMMA EnumerationField instance
   */
  private EnumerationField createEnumerationField(final String name) {
    final EnumerationField enumerationField = LemmaDomainDataModelFactory.DATA_FACTORY.createEnumerationField();
    enumerationField.setName(name);
    return enumerationField;
  }
  
  /**
   * Create a LEMMA DataStructure with the given name, and a version and context
   */
  private DataStructure createDataStructure(final String name) {
    final DataStructure structure = LemmaDomainDataModelFactory.DATA_FACTORY.createDataStructure();
    structure.setName(name);
    return structure;
  }
  
  /**
   * Create a LEMMA List with the given name
   */
  private ListType createListType(final String name) {
    final ListType listType = LemmaDomainDataModelFactory.DATA_FACTORY.createListType();
    listType.setName(name);
    return listType;
  }
  
  private ComplexType mapDomainObject2ConcreteComplexType(final SimpleDomainObject obj) {
    if (obj instanceof DomainObject) {
      return _mapDomainObject2ConcreteComplexType((DomainObject)obj);
    } else if (obj instanceof org.contextmapper.tactic.dsl.tacticdsl.Enum) {
      return _mapDomainObject2ConcreteComplexType((org.contextmapper.tactic.dsl.tacticdsl.Enum)obj);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(obj).toString());
    }
  }
}
