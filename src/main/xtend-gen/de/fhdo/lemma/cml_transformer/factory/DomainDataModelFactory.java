package de.fhdo.lemma.cml_transformer.factory;

import com.google.common.base.Objects;
import de.fhdo.lemma.cml_transformer.Util;
import de.fhdo.lemma.cml_transformer.factory.intermediate.CmlOperation;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.ComplexTypeFeature;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataFactory;
import de.fhdo.lemma.data.DataField;
import de.fhdo.lemma.data.DataFieldFeature;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.Enumeration;
import de.fhdo.lemma.data.EnumerationField;
import de.fhdo.lemma.data.ListType;
import de.fhdo.lemma.data.PrimitiveType;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Consumer;
import java.util.function.Predicate;
import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.Application;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.tactic.dsl.tacticdsl.Attribute;
import org.contextmapper.tactic.dsl.tacticdsl.CollectionType;
import org.contextmapper.tactic.dsl.tacticdsl.DomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.DomainObjectOperation;
import org.contextmapper.tactic.dsl.tacticdsl.Entity;
import org.contextmapper.tactic.dsl.tacticdsl.EnumValue;
import org.contextmapper.tactic.dsl.tacticdsl.Parameter;
import org.contextmapper.tactic.dsl.tacticdsl.Reference;
import org.contextmapper.tactic.dsl.tacticdsl.Repository;
import org.contextmapper.tactic.dsl.tacticdsl.RepositoryOperation;
import org.contextmapper.tactic.dsl.tacticdsl.Service;
import org.contextmapper.tactic.dsl.tacticdsl.ServiceOperation;
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.ValueObject;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.StringExtensions;

/**
 * Model transformation from ContextMapper DSL (CML) to LEMMA Domain Data Modeling Language (DML)
 */
@SuppressWarnings("all")
public class DomainDataModelFactory {
  private static final DataFactory DATA_FACTORY = DataFactory.eINSTANCE;
  
  /**
   * Maps CML {@link Aggregate} to LEMMA DML {@link ComplexType}s.
   * 
   * Since CML aggregates all Domain Services, Entities and Value Objects, we need to extract those and put
   * them in a list in order to add them into the Lemma {@link Context}.
   * 
   * Static variant of the method {@link LemmaDomainDataModelFactory#mapAggregateToComplexType} in order
   * to map a single CML {@link Aggregate}.
   * 
   * @returns Mapped aggregate and other complex types that were referenced by the aggregate
   */
  public static List<ComplexType> mapAggregateToComplexType(final Aggregate agg) {
    final DomainDataModelFactory dataModelFactory = new DomainDataModelFactory();
    dataModelFactory.dataModel = DomainDataModelFactory.DATA_FACTORY.createDataModel();
    final LinkedList<ComplexType> dataStructures = CollectionLiterals.<ComplexType>newLinkedList();
    final Context ctx = DomainDataModelFactory.DATA_FACTORY.createContext();
    dataStructures.addAll(dataModelFactory.mapAggregateToComplexType(agg, ctx));
    dataStructures.addAll(dataModelFactory.listsToGenerate);
    return dataStructures;
  }
  
  /**
   * Maps CML {@link Service} to LEMMA DML {@link ComplexType}
   * 
   * Static variant of the method {@link LemmaDomainDataModelFactory#mapServiceToComplexType} in order
   * to map a single CML {@link Service}.
   * 
   * @param domainService true: map to LEMMA DML Domain Service. False: Map to LEMMA DML Application Service
   * @returns Mapped service and other complex types that were referenced by the aggregate
   */
  public static List<ComplexType> mapServiceToComplexType(final Service cmlDomainService, final boolean domainService) {
    final DomainDataModelFactory dataModelFactory = new DomainDataModelFactory();
    dataModelFactory.dataModel = DomainDataModelFactory.DATA_FACTORY.createDataModel();
    final LinkedList<ComplexType> dataStructures = CollectionLiterals.<ComplexType>newLinkedList();
    final Context ctx = DomainDataModelFactory.DATA_FACTORY.createContext();
    dataStructures.addAll(dataModelFactory.mapServiceToComplexType(cmlDomainService, domainService, ctx));
    dataStructures.addAll(dataModelFactory.listsToGenerate);
    return dataStructures;
  }
  
  /**
   * Output Model (LEMMA DML)
   */
  private DataModel dataModel;
  
  /**
   * Contains type names ({@link ComplexType}) that have been visited in order to
   * check whether a specific type is already "in mapping". Needed to
   * prevent recursive calls since CML domain concepts are nested
   */
  private Map<String, ComplexType> markedTypes = CollectionLiterals.<String, ComplexType>newHashMap();
  
  /**
   * Saves references of repositories and operation types (parameter and return types) in order to add them
   * at the end of the mapping process since they are needed for the whole model. The latter needs to be done, since
   * in CML it's possible to reference domain objects from other bounded contexts. Those are copied in the LEMMA
   * context, so that each team works on their own domain model.
   * 
   * Repositories needs to be saved separately since repositories are located inside of domain objects in CML. LEMMA
   * separates them.
   * Operation types needs to be saved since they are not directly added into the domain model by the methods.
   */
  private List<ComplexType> repositoriesAndOperationTypes = CollectionLiterals.<ComplexType>newLinkedList();
  
  /**
   * Keeps track of lists that must be generated. LEMMA DML needs extra list types with an own declaration for each
   * kind of list (primitive list, complex type list etc.)
   * {@link ListType}s are not put directly into the List of {@link ComplexType}s of a {@link Context} in order to make
   * a check for already created {@link ListType}s easier and faster.
   */
  public final List<ListType> listsToGenerate = CollectionLiterals.<ListType>newLinkedList();
  
  /**
   * Maps CML Model {@link BoundedContext} to LEMMA DML Model {@link DataModel}. The latter containing one {@link Context}
   */
  public DataModel generateDataModel(final BoundedContext bc) {
    this.listsToGenerate.clear();
    this.dataModel = DomainDataModelFactory.DATA_FACTORY.createDataModel();
    final Context ctx = this.mapBoundedContextToContext(bc);
    ctx.setDataModel(this.dataModel);
    this.dataModel.getContexts().add(ctx);
    return this.dataModel;
  }
  
  /**
   * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
   */
  private Context mapBoundedContextToContext(final BoundedContext bc) {
    final Context ctx = DomainDataModelFactory.DATA_FACTORY.createContext();
    ctx.setName(bc.getName());
    EList<Aggregate> _aggregates = bc.getAggregates();
    boolean _tripleNotEquals = (_aggregates != null);
    if (_tripleNotEquals) {
      final Consumer<Aggregate> _function = (Aggregate agg) -> {
        final List<ComplexType> dataStructures = this.mapAggregateToComplexType(agg, ctx);
        final Consumer<ComplexType> _function_1 = (ComplexType struct) -> {
          struct.setContext(ctx);
          ctx.getComplexTypes().add(struct);
        };
        dataStructures.forEach(_function_1);
      };
      bc.getAggregates().forEach(_function);
    }
    Application _application = bc.getApplication();
    boolean _tripleNotEquals_1 = (_application != null);
    if (_tripleNotEquals_1) {
      final Consumer<Service> _function_1 = (Service appService) -> {
        final List<ComplexType> lemmaAppService = this.mapServiceToComplexType(appService, false, ctx);
        Util.addComplexTypesIntoContext(ctx, lemmaAppService);
      };
      bc.getApplication().getServices().forEach(_function_1);
    }
    ctx.getComplexTypes().addAll(this.listsToGenerate);
    return ctx;
  }
  
  /**
   * Maps CML {@link Aggregate} to LEMMA DML {@link ComplexType}s.
   * 
   * Since CML aggregates all Domain Services, Entities and Value Objects, we need to extract those and put
   * them in a list in order to add them into the Lemma {@link Context}
   * 
   * @param agg CML {@link Aggregate} to map
   * @param ctx LEMMA {@link Context} which is needed for already checked domain objects
   */
  private List<ComplexType> mapAggregateToComplexType(final Aggregate agg, final Context ctx) {
    this.repositoriesAndOperationTypes.clear();
    final LinkedList<ComplexType> dataStructures = CollectionLiterals.<ComplexType>newLinkedList();
    EList<SimpleDomainObject> _domainObjects = agg.getDomainObjects();
    for (final SimpleDomainObject obj : _domainObjects) {
      {
        final ComplexType lemmaStructure = this.mapSimpleDomainObjectToComplexType(obj, ctx);
        dataStructures.add(lemmaStructure);
      }
    }
    EList<Service> _services = agg.getServices();
    for (final Service service : _services) {
      {
        final List<ComplexType> lemmaDomainServiceWithNeededTypes = this.mapServiceToComplexType(service, true, ctx);
        Util.mergeComplexTypeLists(dataStructures, lemmaDomainServiceWithNeededTypes);
      }
    }
    Util.mergeComplexTypeLists(dataStructures, this.repositoriesAndOperationTypes);
    return dataStructures;
  }
  
  /**
   * Maps CML {@link SimpleDomainObject} (super class of {@link DomainObject} and {@link java.lang.Enum})
   * to a LEMMA {@link ComplexType}.
   * In other words it creates DataStructures and Enums depending on the given {@link SimpleDomainObject}
   */
  private ComplexType mapSimpleDomainObjectToComplexType(final SimpleDomainObject sObj, final Context ctx) {
    return this.mapDomainObjectToConcreteComplexType(sObj, ctx);
  }
  
  /**
   * Maps CML {@link ValueObject} and {@link Entity} to LEMMA DML {@link DataStructure}.
   * 
   * @param obj CML {@link DomainObject} to map
   * @param ctx LEMMA {@link Context} which is needed for already checked domain objects
   */
  private ComplexType _mapDomainObjectToConcreteComplexType(final DomainObject obj, final Context ctx) {
    final ComplexType alreadyMappedType = this.alreadyMapped(obj, ctx);
    if ((alreadyMappedType != null)) {
      return EcoreUtil.<ComplexType>copy(alreadyMappedType);
    }
    final DataStructure lemmaStructure = this.createDataStructure(obj.getName());
    this.markedTypes.put(obj.getName(), EcoreUtil.<DataStructure>copy(lemmaStructure));
    boolean _isAggregateRoot = obj.isAggregateRoot();
    if (_isAggregateRoot) {
      lemmaStructure.getFeatures().add(ComplexTypeFeature.AGGREGATE);
    }
    if ((obj instanceof Entity)) {
      lemmaStructure.getFeatures().add(ComplexTypeFeature.ENTITY);
    } else {
      if ((obj instanceof ValueObject)) {
        lemmaStructure.getFeatures().add(ComplexTypeFeature.VALUE_OBJECT);
      } else {
        lemmaStructure.getFeatures().add(ComplexTypeFeature.VALUE_OBJECT);
        lemmaStructure.getFeatures().add(ComplexTypeFeature.DOMAIN_EVENT);
      }
    }
    final Consumer<Attribute> _function = (Attribute attr) -> {
      final DataField field = DomainDataModelFactory.DATA_FACTORY.createDataField();
      field.setName(attr.getName());
      field.setImmutable(attr.isNotChangeable());
      this.mapAttributeTypeToPrimitiveTypeAndAssignItToDataField(attr, field);
      field.setDataStructure(lemmaStructure);
      lemmaStructure.getDataFields().add(field);
    };
    obj.getAttributes().forEach(_function);
    final Consumer<Reference> _function_1 = (Reference ref) -> {
      final DataField field = DomainDataModelFactory.DATA_FACTORY.createDataField();
      field.setName(ref.getName());
      field.setImmutable(ref.isNotChangeable());
      field.setComplexType(this.mapReferenceTypeToComplexType(ref, field, ctx));
      field.setDataStructure(lemmaStructure);
      lemmaStructure.getDataFields().add(field);
    };
    obj.getReferences().forEach(_function_1);
    final Consumer<DomainObjectOperation> _function_2 = (DomainObjectOperation op) -> {
      final DataOperation lemmaOp = this.mapDomainObjectOperationToDataOperation(op, ctx);
      lemmaStructure.getOperations().add(lemmaOp);
      lemmaOp.setDataStructure(lemmaStructure);
    };
    obj.getOperations().forEach(_function_2);
    if (((obj.getRepository() != null) && (((Object[])Conversions.unwrapArray(obj.getRepository().getOperations(), Object.class)).length > 0))) {
      final DataStructure lemmaRepo = this.mapRepositoryToDataStructure(obj.getRepository(), ctx);
      this.repositoriesAndOperationTypes.add(lemmaRepo);
    }
    return lemmaStructure;
  }
  
  /**
   * Maps CML {@link Enum} to LEMMA DML {@link Enumeration}
   */
  private ComplexType _mapDomainObjectToConcreteComplexType(final org.contextmapper.tactic.dsl.tacticdsl.Enum obj, final Context ctx) {
    final Enumeration lemmaEnum = this.createEnumeration(obj.getName());
    this.markedTypes.put(obj.getName(), EcoreUtil.<Enumeration>copy(lemmaEnum));
    final Consumer<EnumValue> _function = (EnumValue enumValue) -> {
      lemmaEnum.getFields().add(this.createEnumerationField(enumValue.getName()));
    };
    obj.getValues().forEach(_function);
    return lemmaEnum;
  }
  
  /**
   * Maps a CML Operation ({@link ServiceOperation}, {@link RepositoryOperation}, {@link DomainOperation}) to a
   * LEMMA {@link DataOperation}
   */
  private DataOperation mapCmlOperationToDataOperation(final CmlOperation cmlOp, final Context ctx) {
    final DataOperation lemmaOp = DomainDataModelFactory.DATA_FACTORY.createDataOperation();
    lemmaOp.setName(cmlOp.getName());
    org.contextmapper.tactic.dsl.tacticdsl.ComplexType _returnType = cmlOp.getReturnType();
    boolean _tripleEquals = (_returnType == null);
    if (_tripleEquals) {
      lemmaOp.setHasNoReturnType(true);
    } else {
      SimpleDomainObject _domainObjectType = cmlOp.getReturnType().getDomainObjectType();
      boolean _tripleNotEquals = (_domainObjectType != null);
      if (_tripleNotEquals) {
        lemmaOp.setComplexReturnType(this.mapComplexTypes(cmlOp.getReturnType(), ctx));
        this.addIfNotExists(this.repositoriesAndOperationTypes, EcoreUtil.<ComplexType>copy(lemmaOp.getComplexReturnType()));
      } else {
        lemmaOp.setPrimitiveReturnType(this.mapPrimitiveType(cmlOp.getReturnType().getType()));
      }
    }
    final Consumer<Parameter> _function = (Parameter param) -> {
      final DataOperationParameter lemmaParam = DomainDataModelFactory.DATA_FACTORY.createDataOperationParameter();
      lemmaParam.setName(param.getName());
      SimpleDomainObject _domainObjectType_1 = param.getParameterType().getDomainObjectType();
      boolean _tripleNotEquals_1 = (_domainObjectType_1 != null);
      if (_tripleNotEquals_1) {
        lemmaParam.setComplexType(this.mapComplexTypes(param.getParameterType(), ctx));
        this.addIfNotExists(this.repositoriesAndOperationTypes, EcoreUtil.<ComplexType>copy(lemmaParam.getComplexType()));
      } else {
        lemmaParam.setPrimitiveType(this.mapPrimitiveType(param.getParameterType().getType()));
      }
      lemmaOp.getParameters().add(lemmaParam);
    };
    cmlOp.getParameters().forEach(_function);
    return lemmaOp;
  }
  
  /**
   * Maps CML {@link RepositoryOperation} to LEMMA DML {@link DataOperation}
   */
  private DataOperation mapRepositoryOperationToDataOperation(final RepositoryOperation cmlOp, final Context ctx) {
    String _name = cmlOp.getName();
    org.contextmapper.tactic.dsl.tacticdsl.ComplexType _returnType = cmlOp.getReturnType();
    EList<Parameter> _parameters = cmlOp.getParameters();
    CmlOperation _cmlOperation = new CmlOperation(_name, _returnType, _parameters);
    return this.mapCmlOperationToDataOperation(_cmlOperation, ctx);
  }
  
  /**
   * Maps CML {@link DomainObjectOperation} to LEMMA DML {@link DataOperation}
   */
  private DataOperation mapDomainObjectOperationToDataOperation(final DomainObjectOperation cmlOp, final Context ctx) {
    String _name = cmlOp.getName();
    org.contextmapper.tactic.dsl.tacticdsl.ComplexType _returnType = cmlOp.getReturnType();
    EList<Parameter> _parameters = cmlOp.getParameters();
    CmlOperation _cmlOperation = new CmlOperation(_name, _returnType, _parameters);
    return this.mapCmlOperationToDataOperation(_cmlOperation, ctx);
  }
  
  /**
   * Maps CML {@link ServiceOperation} to LEMMA DML {@link DataOperation}
   */
  private DataOperation mapServiceOperationToDataOperation(final ServiceOperation cmlOp, final Context ctx) {
    String _name = cmlOp.getName();
    org.contextmapper.tactic.dsl.tacticdsl.ComplexType _returnType = cmlOp.getReturnType();
    EList<Parameter> _parameters = cmlOp.getParameters();
    CmlOperation _cmlOperation = new CmlOperation(_name, _returnType, _parameters);
    return this.mapCmlOperationToDataOperation(_cmlOperation, ctx);
  }
  
  /**
   * Maps CML {@link Service} to LEMMA DML {@link ComplexType}
   * 
   * @param domainService true: map to LEMMA DML Domain Service. False: Map to LEMMA DML Application Service
   * @returns Mapped service and complex types of operations and return type
   */
  private List<ComplexType> mapServiceToComplexType(final Service cmlDomainService, final boolean domainService, final Context ctx) {
    final LinkedList<ComplexType> dataStructures = CollectionLiterals.<ComplexType>newLinkedList();
    final DataStructure lemmaDomainService = DomainDataModelFactory.DATA_FACTORY.createDataStructure();
    lemmaDomainService.setName(cmlDomainService.getName());
    if (domainService) {
      lemmaDomainService.getFeatures().add(ComplexTypeFeature.DOMAIN_SERVICE);
    } else {
      lemmaDomainService.getFeatures().add(ComplexTypeFeature.APPLICATION_SERVICE);
    }
    final Consumer<ServiceOperation> _function = (ServiceOperation cmlOp) -> {
      final DataOperation lemmaOp = this.mapServiceOperationToDataOperation(cmlOp, ctx);
      lemmaDomainService.getOperations().add(lemmaOp);
    };
    cmlDomainService.getOperations().forEach(_function);
    dataStructures.add(lemmaDomainService);
    Util.mergeComplexTypeLists(dataStructures, this.repositoriesAndOperationTypes);
    return dataStructures;
  }
  
  /**
   * Maps a CML {@link Repository} to a DML {@link DataStructure}.
   */
  private DataStructure mapRepositoryToDataStructure(final Repository repo, final Context ctx) {
    final DataStructure lemmaStructure = DomainDataModelFactory.DATA_FACTORY.createDataStructure();
    lemmaStructure.setName(repo.getName());
    lemmaStructure.getFeatures().add(ComplexTypeFeature.REPOSITORY);
    final Consumer<RepositoryOperation> _function = (RepositoryOperation op) -> {
      final DataOperation lemmaOp = this.mapRepositoryOperationToDataOperation(op, ctx);
      lemmaStructure.getOperations().add(lemmaOp);
      lemmaOp.setDataStructure(lemmaStructure);
    };
    repo.getOperations().forEach(_function);
    return lemmaStructure;
  }
  
  /**
   * Create a LEMMA Enumeration instance
   */
  private Enumeration createEnumeration(final String name) {
    final Enumeration enumeration = DomainDataModelFactory.DATA_FACTORY.createEnumeration();
    enumeration.setName(name);
    return enumeration;
  }
  
  /**
   * Create a LEMMA EnumerationField instance
   */
  private EnumerationField createEnumerationField(final String name) {
    final EnumerationField enumerationField = DomainDataModelFactory.DATA_FACTORY.createEnumerationField();
    enumerationField.setName(name);
    return enumerationField;
  }
  
  /**
   * Create a LEMMA DataStructure with the given name, and a version and context
   */
  private DataStructure createDataStructure(final String name) {
    final DataStructure structure = DomainDataModelFactory.DATA_FACTORY.createDataStructure();
    structure.setName(name);
    return structure;
  }
  
  /**
   * Create a LEMMA DML {@link ListType} for a given {@link ComplexType}
   */
  private ListType createListTypeIfNotExisting(final ComplexType type) {
    ListType list = this.alreadyExistingListType(type);
    if ((list == null)) {
      list = DomainDataModelFactory.DATA_FACTORY.createListType();
      String _name = type.getName();
      String _plus = (_name + "List");
      list.setName(_plus);
      final DataField dataField = DomainDataModelFactory.DATA_FACTORY.createDataField();
      dataField.setName(String.valueOf(StringExtensions.toFirstLower(type.getName()).charAt(0)));
      dataField.setComplexType(type);
      list.getDataFields().add(dataField);
    }
    return list;
  }
  
  /**
   * Create a LEMMA DML {@link ListType} for a given {@link PrimitiveType}
   */
  private ListType createListTypeIfNotExisting(final PrimitiveType type) {
    ListType list = this.alreadyExistingListType(type);
    if ((list == null)) {
      list = DomainDataModelFactory.DATA_FACTORY.createListType();
      String _firstUpper = StringExtensions.toFirstUpper(type.getTypeName());
      String _plus = (_firstUpper + "List");
      list.setName(_plus);
      final DataField dataField = DomainDataModelFactory.DATA_FACTORY.createDataField();
      dataField.setName(String.valueOf(StringExtensions.toFirstLower(type.getTypeName()).charAt(0)));
      dataField.setPrimitiveType(type);
      list.getDataFields().add(dataField);
    }
    return list;
  }
  
  /**
   * Maps CML {@link Attribute#type} to LEMMA DML {@link PrimitiveType} and assigns it to the given
   * {@link DataField}. If the {@link Attribute} has a List {@link CollectionType} a {@link ListType} will be assigned instead (and
   * created if not existed yet)
   */
  private boolean mapAttributeTypeToPrimitiveTypeAndAssignItToDataField(final Attribute attr, final DataField field) {
    boolean _xblockexpression = false;
    {
      final PrimitiveType primitiveType = this.mapPrimitiveType(attr.getType());
      boolean _equals = attr.getCollectionType().equals(CollectionType.LIST);
      if (_equals) {
        final ListType list = this.createListTypeIfNotExisting(primitiveType);
        field.setComplexType(list);
        this.listsToGenerate.add(list);
      } else {
        field.setPrimitiveType(primitiveType);
      }
      boolean _xifexpression = false;
      boolean _isKey = attr.isKey();
      if (_isKey) {
        _xifexpression = field.getFeatures().add(DataFieldFeature.IDENTIFIER);
      }
      _xblockexpression = _xifexpression;
    }
    return _xblockexpression;
  }
  
  /**
   * Maps CML {@link Reference#domainObjectType} to LEMMA DML {@link ComplexType} and returns it.
   * If the {@link Reference} has a list type of {@link CollectionType} a LEMMA DML {@link ListType} will be mapped (and
   * created if not existed yet)
   */
  private ComplexType mapReferenceTypeToComplexType(final Reference ref, final DataField field, final Context ctx) {
    ComplexType complexType = this.findOrCreateComplexTypeBySimpleDomainObject(ref.getDomainObjectType(), ctx);
    boolean _equals = ref.getCollectionType().equals(CollectionType.LIST);
    if (_equals) {
      final ListType list = this.createListTypeIfNotExisting(complexType);
      this.listsToGenerate.add(list);
      complexType = list;
    }
    boolean _isKey = ref.isKey();
    if (_isKey) {
      field.getFeatures().add(DataFieldFeature.IDENTIFIER);
    }
    field.getFeatures().add(DataFieldFeature.PART);
    return complexType;
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
      _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveBoolean();
    }
    if (!_matched) {
      if (Objects.equal(_lowerCase, "string")) {
        _matched=true;
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveString();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveInteger();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveInteger();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveLong();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveDouble();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveFloat();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveDate();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveDate();
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
        _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveDate();
      }
    }
    if (!_matched) {
      _switchResult = DomainDataModelFactory.DATA_FACTORY.createPrimitiveUnspecified();
    }
    return _switchResult;
  }
  
  /**
   * Maps CML {@link org.contextmapper.tactic.dsl.tacticdsl.ComplexType} to LEMMA DML {@link ComplexType}s
   * by returning the needed {@link ComplexType} from the LEMMA {@link DataModel}.
   * If its not existing, it will be created on the fly.
   * 
   * If the CML {@link org.contextmapper.tactic.dsl.tacticdsl.ComplexType} is a list then a
   * LEMMA {@link ListType} will be returned (and created if not existing)
   */
  private ComplexType mapComplexTypes(final org.contextmapper.tactic.dsl.tacticdsl.ComplexType cmlComplexType, final Context ctx) {
    boolean _equals = cmlComplexType.getCollectionType().equals(CollectionType.LIST);
    if (_equals) {
      ListType list = null;
      SimpleDomainObject _domainObjectType = cmlComplexType.getDomainObjectType();
      boolean _tripleNotEquals = (_domainObjectType != null);
      if (_tripleNotEquals) {
        final ComplexType lemmaComplexType = this.findOrCreateComplexTypeBySimpleDomainObject(cmlComplexType.getDomainObjectType(), ctx);
        list = this.createListTypeIfNotExisting(lemmaComplexType);
      } else {
        final PrimitiveType lemmaPrimitiveType = this.mapPrimitiveType(cmlComplexType.getType());
        list = this.createListTypeIfNotExisting(lemmaPrimitiveType);
      }
      this.listsToGenerate.add(list);
      return list;
    } else {
      return this.findOrCreateComplexTypeBySimpleDomainObject(cmlComplexType.getDomainObjectType(), ctx);
    }
  }
  
  /**
   * Maps CML {@link SimpleDomainObject} to LEMMA DML {@link ComplexType}s
   * by returning the needed {@link ComplexType} from the LEMMA {@link DataModel}.
   * If its not existing, it will be created on the fly.
   */
  private ComplexType findOrCreateComplexTypeBySimpleDomainObject(final SimpleDomainObject sObj, final Context ctx) {
    EList<ComplexType> _complexTypes = ctx.getComplexTypes();
    for (final ComplexType lemmaComplexType : _complexTypes) {
      boolean _equals = sObj.getName().equals(lemmaComplexType.getName());
      if (_equals) {
        return lemmaComplexType;
      }
    }
    Set<String> _keySet = this.markedTypes.keySet();
    for (final String type : _keySet) {
      boolean _equals_1 = sObj.getName().equals(type);
      if (_equals_1) {
        return this.markedTypes.get(type);
      }
    }
    return this.mapSimpleDomainObjectToComplexType(sObj, ctx);
  }
  
  /**
   * Checks whether a CML {@link DomainObject} is already mapped in a {@link Context}.
   * Needed since a ComplexType is being created on the fly when not existing in the
   * {@link LemmaDomainDataModelFactory#mapReferenceType} method.
   */
  private ComplexType alreadyMapped(final DomainObject obj, final Context ctx) {
    EList<ComplexType> _complexTypes = ctx.getComplexTypes();
    for (final ComplexType cType : _complexTypes) {
      boolean _equals = cType.getName().equals(obj.getName());
      if (_equals) {
        return cType;
      }
    }
    return null;
  }
  
  /**
   * Checks whether a {@link ListType} for a given {@link PrimitiveType} exists
   */
  private ListType alreadyExistingListType(final PrimitiveType type) {
    String _firstUpper = StringExtensions.toFirstUpper(type.getTypeName());
    String _plus = (_firstUpper + "List");
    final String expectedName = String.valueOf(_plus);
    for (final ListType listToGenerate : this.listsToGenerate) {
      boolean _equals = listToGenerate.getName().equals(expectedName);
      if (_equals) {
        return listToGenerate;
      }
    }
    return null;
  }
  
  /**
   * Checks whether a {@link ListType} for a given {@link ComplexType} exists
   */
  private ListType alreadyExistingListType(final ComplexType type) {
    String _firstUpper = StringExtensions.toFirstUpper(type.getName());
    String _plus = (_firstUpper + "List");
    final String expectedName = String.valueOf(_plus);
    for (final ListType listToGenerate : this.listsToGenerate) {
      boolean _equals = listToGenerate.getName().equals(expectedName);
      if (_equals) {
        return listToGenerate;
      }
    }
    return null;
  }
  
  private boolean addIfNotExists(final List<ComplexType> list, final ComplexType element) {
    boolean _xblockexpression = false;
    {
      final Predicate<ComplexType> _function = (ComplexType checkMe) -> {
        return checkMe.getName().equals(element.getName());
      };
      final Optional<ComplexType> check = list.stream().filter(_function).findAny();
      boolean _xifexpression = false;
      boolean _isEmpty = check.isEmpty();
      if (_isEmpty) {
        _xifexpression = list.add(EcoreUtil.<ComplexType>copy(element));
      }
      _xblockexpression = _xifexpression;
    }
    return _xblockexpression;
  }
  
  private ComplexType mapDomainObjectToConcreteComplexType(final SimpleDomainObject obj, final Context ctx) {
    if (obj instanceof DomainObject) {
      return _mapDomainObjectToConcreteComplexType((DomainObject)obj, ctx);
    } else if (obj instanceof org.contextmapper.tactic.dsl.tacticdsl.Enum) {
      return _mapDomainObjectToConcreteComplexType((org.contextmapper.tactic.dsl.tacticdsl.Enum)obj, ctx);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(obj, ctx).toString());
    }
  }
}
