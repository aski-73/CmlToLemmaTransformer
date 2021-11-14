package de.fhdo.lemma.cml_transformer.factory;

import com.google.common.base.Objects;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.ComplexTypeFeature;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataField;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.Enumeration;
import de.fhdo.lemma.data.EnumerationField;
import de.fhdo.lemma.data.ListType;
import de.fhdo.lemma.data.PrimitiveType;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.function.Consumer;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.contextmapper.tactic.dsl.tacticdsl.Attribute;
import org.contextmapper.tactic.dsl.tacticdsl.DomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.DomainObjectOperation;
import org.contextmapper.tactic.dsl.tacticdsl.Entity;
import org.contextmapper.tactic.dsl.tacticdsl.EnumValue;
import org.contextmapper.tactic.dsl.tacticdsl.Parameter;
import org.contextmapper.tactic.dsl.tacticdsl.Reference;
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.ValueObject;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

@SuppressWarnings("all")
public class LemmaDomainDataModelFactory {
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  private static final List<String> PRIMITIVE_LEMMA_TYPES = Collections.<String>unmodifiableList(CollectionLiterals.<String>newArrayList("int", "long", "float", "double", "string", "boolean"));
  
  /**
   * Input Model (CML)
   */
  private ContextMappingModel cmlModel;
  
  /**
   * Output Model (LEMMA DML)
   */
  private DataModel dataModel;
  
  /**
   * Helper for tracking the created ComplexTypes in a context
   */
  private Context currentCtx;
  
  public LemmaDomainDataModelFactory(final ContextMappingModel cmlModel) {
    this.cmlModel = cmlModel;
  }
  
  /**
   * Maps CML Model {@link ContextMappingModel} to LEMMA DML Model {@link DataModel}
   */
  public DataModel generateDataModel() {
    this.dataModel = LemmaDomainDataModelFactory.DATA_FACTORY.createDataModel();
    final Consumer<BoundedContext> _function = (BoundedContext bc) -> {
      final Context ctx = this.mapBoundedContext2Context(bc);
      ctx.setDataModel(this.dataModel);
      this.dataModel.getContexts().add(ctx);
    };
    this.cmlModel.getBoundedContexts().forEach(_function);
    return this.dataModel;
  }
  
  /**
   * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
   */
  private Context mapBoundedContext2Context(final BoundedContext bc) {
    final Context ctx = LemmaDomainDataModelFactory.DATA_FACTORY.createContext();
    ctx.setName(bc.getName());
    this.currentCtx = ctx;
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
    final ComplexType alreadyMappedType = this.alreadyMapped(obj);
    boolean _notEquals = (!Objects.equal(alreadyMappedType, null));
    if (_notEquals) {
      return alreadyMappedType;
    }
    final DataStructure lemmaStructure = this.createDataStructure(obj.getName());
    boolean _isAggregateRoot = obj.isAggregateRoot();
    if (_isAggregateRoot) {
      lemmaStructure.getFeatures().add(ComplexTypeFeature.AGGREGATE);
    }
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
    final Consumer<Attribute> _function = (Attribute attr) -> {
      final DataField field = LemmaDomainDataModelFactory.DATA_FACTORY.createDataField();
      field.setName(attr.getName());
      field.setImmutable(attr.isNotChangeable());
      field.setPrimitiveType(this.mapPrimitiveType(attr.getType()));
      field.setDataStructure(lemmaStructure);
      lemmaStructure.getDataFields().add(field);
    };
    obj.getAttributes().forEach(_function);
    final Consumer<Reference> _function_1 = (Reference ref) -> {
      final DataField field = LemmaDomainDataModelFactory.DATA_FACTORY.createDataField();
      field.setName(ref.getName());
      field.setImmutable(ref.isNotChangeable());
      field.setComplexType(this.mapReferenceType(ref.getDomainObjectType()));
      field.setDataStructure(lemmaStructure);
      lemmaStructure.getDataFields().add(field);
    };
    obj.getReferences().forEach(_function_1);
    final Consumer<DomainObjectOperation> _function_2 = (DomainObjectOperation op) -> {
      final DataOperation lemmaOp = LemmaDomainDataModelFactory.DATA_FACTORY.createDataOperation();
      lemmaOp.setName(op.getName());
      org.contextmapper.tactic.dsl.tacticdsl.ComplexType _returnType = op.getReturnType();
      boolean _tripleEquals = (_returnType == null);
      if (_tripleEquals) {
        lemmaOp.setHasNoReturnType(true);
      } else {
        SimpleDomainObject _domainObjectType = op.getReturnType().getDomainObjectType();
        boolean _notEquals_1 = (!Objects.equal(_domainObjectType, null));
        if (_notEquals_1) {
          lemmaOp.setComplexReturnType(this.mapReferenceType(op.getReturnType().getDomainObjectType()));
        } else {
          lemmaOp.setPrimitiveReturnType(this.mapPrimitiveType(op.getReturnType().getType()));
        }
      }
      final Consumer<Parameter> _function_3 = (Parameter param) -> {
        final DataOperationParameter lemmaParam = LemmaDomainDataModelFactory.DATA_FACTORY.createDataOperationParameter();
        lemmaParam.setName(param.getName());
        SimpleDomainObject _domainObjectType_1 = param.getParameterType().getDomainObjectType();
        boolean _tripleNotEquals = (_domainObjectType_1 != null);
        if (_tripleNotEquals) {
          lemmaParam.setComplexType(this.mapReferenceType(param.getParameterType().getDomainObjectType()));
        } else {
          lemmaParam.setPrimitiveType(this.mapPrimitiveType(param.getParameterType().getType()));
        }
        lemmaOp.getParameters().add(lemmaParam);
      };
      op.getParameters().forEach(_function_3);
      lemmaStructure.getOperations().add(lemmaOp);
    };
    obj.getOperations().forEach(_function_2);
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
  
  /**
   * Maps CML types (String values) to LEMMA DML types.
   * Checks if its a primitive type by checking the internal type map {@link KNOWN_TYPES}.
   * - If yes return the corresponding LEMMA DML type from the internal map {@link KNOWN_TYPES}.
   * - If no, return "unspecified"
   */
  private PrimitiveType mapPrimitiveType(final String type) {
    PrimitiveType _switchResult = null;
    String _lowerCase = type.toLowerCase();
    boolean _matched = false;
    if (Objects.equal(_lowerCase, "boolean")) {
      _matched=true;
      _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveBoolean();
    }
    if (!_matched) {
      if (Objects.equal(_lowerCase, "string")) {
        _matched=true;
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveString();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "int")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveInteger();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "integer")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveInteger();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "long")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveLong();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "double")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveDouble();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "float")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveFloat();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "date")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveDate();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "datetime")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveDate();
      }
    }
    if (!_matched) {
      _matched=true;
      if (!_matched) {
        if (Objects.equal(_lowerCase, "timestamp")) {
          _matched=true;
        }
      }
      if (_matched) {
        _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveDate();
      }
    }
    if (!_matched) {
      _switchResult = LemmaDomainDataModelFactory.DATA_FACTORY.createPrimitiveUnspecified();
    }
    return _switchResult;
  }
  
  /**
   * Maps CML reference types to LEMMA DML complex types by returning the needed Complex Type from the LEMMA data model.
   * If its not existing, it will be created on the fly.
   */
  private ComplexType mapReferenceType(final SimpleDomainObject sObj) {
    EList<ComplexType> _complexTypes = this.dataModel.getComplexTypes();
    for (final ComplexType cType : _complexTypes) {
      boolean _equals = sObj.equals(cType.getName());
      if (_equals) {
        return cType;
      }
    }
    return this.mapSimpleDomainObject2ComplexType(sObj);
  }
  
  /**
   * Checks whether a CML {@link DomainObject} was already mapped.
   * Needed since a ComplexType is being created on the fly when not existing in the
   * {@link LemmaDomainDataModelFactory#mapReferenceType} method.
   */
  private ComplexType alreadyMapped(final DomainObject obj) {
    EList<ComplexType> _complexTypes = this.currentCtx.getComplexTypes();
    for (final ComplexType cType : _complexTypes) {
      boolean _equals = cType.getName().equals(obj.getName());
      if (_equals) {
        return cType;
      }
    }
    return null;
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
