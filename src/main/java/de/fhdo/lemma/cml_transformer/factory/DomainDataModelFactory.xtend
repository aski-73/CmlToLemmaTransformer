package de.fhdo.lemma.cml_transformer.factory

import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.ComplexTypeFeature
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataFactory
import de.fhdo.lemma.data.DataField
import de.fhdo.lemma.data.DataFieldFeature
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataOperation
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.data.Enumeration
import de.fhdo.lemma.data.EnumerationField
import de.fhdo.lemma.data.ListType
import de.fhdo.lemma.data.PrimitiveType
import java.util.List
import org.contextmapper.dsl.contextMappingDSL.Aggregate
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.tactic.dsl.tacticdsl.Attribute
import org.contextmapper.tactic.dsl.tacticdsl.CollectionType
import org.contextmapper.tactic.dsl.tacticdsl.DomainObject
import org.contextmapper.tactic.dsl.tacticdsl.DomainObjectOperation
import org.contextmapper.tactic.dsl.tacticdsl.Entity
import org.contextmapper.tactic.dsl.tacticdsl.Enum
import org.contextmapper.tactic.dsl.tacticdsl.Reference
import org.contextmapper.tactic.dsl.tacticdsl.Service
import org.contextmapper.tactic.dsl.tacticdsl.ServiceOperation
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject
import org.contextmapper.tactic.dsl.tacticdsl.ValueObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.contextmapper.tactic.dsl.tacticdsl.Repository
import org.contextmapper.tactic.dsl.tacticdsl.RepositoryOperation
import de.fhdo.lemma.cml_transformer.factory.intermediate.CmlOperation
import java.util.Map
import de.fhdo.lemma.cml_transformer.Util
import org.slf4j.LoggerFactory
import java.util.Collections

/**
 * Model transformation from ContextMapper DSL (CML) to LEMMA Domain Data Modeling Language (DML)
 */
class DomainDataModelFactory {
	static val LOGGER = LoggerFactory.getLogger(DomainDataModelFactory)
	static val DATA_FACTORY = DataFactory.eINSTANCE

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
	static def List<ComplexType> mapAggregateToComplexType(Aggregate agg) {
		val dataModelFactory = new DomainDataModelFactory()
		dataModelFactory.dataModel = DATA_FACTORY.createDataModel
		// contains all extracted Entities and Value Objects of an CML Aggregate
		val dataStructures = <ComplexType>newLinkedList
		val ctx = DATA_FACTORY.createContext

		// add DataStructures
		val mappedAggregateAndReferencedTypes = dataModelFactory.mapAggregateToComplexType(agg, ctx)
		Util.mergeComplexTypeLists(dataStructures, mappedAggregateAndReferencedTypes)

		// add LEMMA ListTypes that might have be created during previous mapping
		Util.mergeComplexTypeLists(dataStructures, dataModelFactory.listsToGenerate)

		return dataStructures
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
	static def List<ComplexType> mapServiceToComplexType(Service cmlDomainService, boolean domainService) {
		val dataModelFactory = new DomainDataModelFactory()
		dataModelFactory.dataModel = DATA_FACTORY.createDataModel
		// contains all extracted Entities and Value Objects of an CML Aggregate
		val dataStructures = <ComplexType>newLinkedList
		val ctx = DATA_FACTORY.createContext
		ctx.dataModel = dataModelFactory.dataModel

		// add DataStructures
		val mappedDataStructures = dataModelFactory.mapServiceToComplexType(cmlDomainService, domainService, ctx)
		Util.mergeComplexTypeLists(dataStructures, mappedDataStructures)

		// add LEMMA ListTypes that might have be created during previous mapping
		Util.mergeComplexTypeLists(dataStructures, dataModelFactory.listsToGenerate)

		return dataStructures
	}

	/**
	 * Output Model (LEMMA DML)
	 */
	DataModel dataModel;

	/**
	 * Contains type names ({@link ComplexType}) that have been visited in order to 
	 * check whether a specific type is already "in mapping". Needed to
	 * prevent recursive calls since CML domain concepts are nested
	 */
	Map<String, ComplexType> markedTypes = newHashMap

	/**
	 * Saves references of repositories and operation types (parameter and return types) in order to add them 
	 * at the end of the mapping process since they are needed for the whole model. The latter needs to be done, since
	 * in CML it's possible to reference domain objects from other bounded contexts. Those are copied in the LEMMA
	 * context, so that each team works on their own domain model.
	 * 
	 * Repositories needs to be saved separately since repositories are located inside of domain objects in CML. LEMMA
	 * separates them.
	 * Operation types needs to be saved since they are not directly added into the domain model by the methods.
	 * 
	 */
	List<ComplexType> repositoriesAndOperationTypes = newLinkedList

	/**
	 * Keeps track of lists that must be generated. LEMMA DML needs extra list types with an own declaration for each
	 * kind of list (primitive list, complex type list etc.)
	 * {@link ListType}s are not put directly into the List of {@link ComplexType}s of a {@link Context} in order to make
	 * a check for already created {@link ListType}s easier and faster.
	 */
	public final List<ListType> listsToGenerate = newLinkedList;

	/**
	 * Maps CML Model {@link BoundedContext} to LEMMA DML Model {@link DataModel}. The latter containing one {@link Context}
	 */
	def DataModel generateDataModel(BoundedContext bc) {
		listsToGenerate.clear()
		dataModel = DATA_FACTORY.createDataModel

		val ctx = mapBoundedContextToContext(bc);
		// Tell the Context in which DataModel it is and visa versa
		ctx.dataModel = dataModel
		dataModel.contexts.add(ctx)

		return dataModel
	}

	/**
	 * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
	 */
	private def Context mapBoundedContextToContext(BoundedContext bc) {
		val ctx = DATA_FACTORY.createContext
		ctx.name = bc.name

		// Entities, Value Objects, Repositories, Domain Services, Aggregates
		if (bc.aggregates !== null) {
			bc.aggregates.forEach [ agg |
				val dataStructures = mapAggregateToComplexType(agg, ctx)
				Util.addComplexTypesIntoContext(ctx, dataStructures)
			]
		}

		// Application Service
		if (bc.application !== null) {
			bc.application.services.forEach [ appService |
				val lemmaAppServiceWithComplexTypes = mapServiceToComplexType(appService, false, ctx)
				Util.addComplexTypesIntoContext(ctx, lemmaAppServiceWithComplexTypes)
			]
		}

		// Lists
		Util.addComplexTypesIntoContext(ctx, listsToGenerate)

		return ctx
	}

	/**
	 * Maps CML {@link Aggregate} to LEMMA DML {@link ComplexType}s.
	 * 
	 * Since CML aggregates all Domain Services, Entities and Value Objects, we need to extract those and put
	 * them in a list in order to add them into the Lemma {@link Context}
	 * 
	 * @param agg CML {@link Aggregate} to map
	 * @param ctx LEMMA {@link Context} which is needed for already checked domain objects
	 * 
	 * @return List of {@link ComplexType}. Each complex type is a part of the Aggregate parameter. The 
	 * aggregate itself is is represented as its aggregate root.
	 */
	private def List<ComplexType> mapAggregateToComplexType(Aggregate agg, Context ctx) {
		repositoriesAndOperationTypes.clear()
		// contains all extracted Entities and Value Objects of an CML Aggregate
		val dataStructures = <ComplexType>newLinkedList

		// A CML Aggregate contains Entities, Value Objects and Repositories
		for (obj : agg.domainObjects) {
			val lemmaStructureAndReferencedTypes = mapSimpleDomainObjectToComplexType(obj, ctx)
			Util.mergeComplexTypeLists(dataStructures, lemmaStructureAndReferencedTypes)
		}

		// Creating domain services
		for (service : agg.services) {
			val lemmaDomainServiceAndReferencedTypes = mapServiceToComplexType(service, true, ctx)
			Util.mergeComplexTypeLists(dataStructures, lemmaDomainServiceAndReferencedTypes)
		}

		// Add repositories and referenced types of other bounded contexts (in cml)
		Util.mergeComplexTypeLists(dataStructures, repositoriesAndOperationTypes)

		return dataStructures
	}

	/**
	 * Maps CML {@link SimpleDomainObject} (super class of {@link DomainObject} and {@link java.lang.Enum})
	 * to a LEMMA {@link ComplexType}.
	 * In other words it creates DataStructures and Enums depending on the given {@link SimpleDomainObject}
	 * 
	 * @returns List of {@link ComplexType}. First element is the mapped {@link SimpleDomainObject}. All other
	 * elements are {@link ComplexTypes}s referenced by the first element.
	 */
	private def List<ComplexType> mapSimpleDomainObjectToComplexType(SimpleDomainObject sObj, Context ctx) {
		// Depending on concrete Type of SimpleDomainObject call different Method.
		return mapDomainObjectToConcreteComplexType(sObj, ctx)
	}

	/** 
	 * Maps CML {@link ValueObject} and {@link Entity} to LEMMA DML {@link DataStructure}. 
	 * 
	 * @param obj CML {@link DomainObject} to map
	 * @param ctx LEMMA {@link Context} which is needed for already checked domain objects
	 */
	private def dispatch List<ComplexType> mapDomainObjectToConcreteComplexType(DomainObject obj, Context ctx) {
		val alreadyMappedType = obj.alreadyMapped(ctx)
		if (alreadyMappedType !== null) {
			return Collections.singletonList(EcoreUtil.copy(alreadyMappedType))
		}
		val referencedComplexTypes = <ComplexType>newLinkedList

		val lemmaStructure = createDataStructure(obj.name)
		lemmaStructure.context = ctx
		referencedComplexTypes.add(lemmaStructure)

		markedTypes.put(obj.name, EcoreUtil.copy(lemmaStructure))

		// Determine LEMMA Features
		if (obj.aggregateRoot) {
			lemmaStructure.features.add(ComplexTypeFeature.AGGREGATE)
		}

		if (obj instanceof Entity) {
			lemmaStructure.features.add(ComplexTypeFeature.ENTITY)
		} else if (obj instanceof ValueObject) {
			lemmaStructure.features.add(ComplexTypeFeature.VALUE_OBJECT)
		} else { // Event
			lemmaStructure.features.add(ComplexTypeFeature.VALUE_OBJECT)
			lemmaStructure.features.add(ComplexTypeFeature.DOMAIN_EVENT)
		}

		// Add fields. CML separates fields in Attributes and References. 
		// Attributes are primitive types ...
		obj.attributes.forEach [ attr |
			val field = DATA_FACTORY.createDataField
			field.name = attr.name
			field.immutable = attr.isNotChangeable

			mapAttributeTypeToPrimitiveTypeAndAssignItToDataField(attr, field)

			// Knows in which DataStructure it is contained
			field.dataStructure = lemmaStructure

			lemmaStructure.dataFields.add(field)
		]
		// ... while References are complex types
		obj.references.forEach [ ref |
			val field = DATA_FACTORY.createDataField
			field.name = ref.name
			field.immutable = ref.isNotChangeable

			// Map the CML Type to a DML type
			val mappedTypeAndReferencedTypes = mapReferenceTypeToComplexType(ref, ctx)
			Util.mergeComplexTypeLists(referencedComplexTypes, mappedTypeAndReferencedTypes)

			// Assign mapped type to field
			field.complexType = mappedTypeAndReferencedTypes.get(0)

			if (ref.key) {
				field.features.add(DataFieldFeature.IDENTIFIER)
			}

			// Complex Types are always a part of the aggregate
			field.features.add(DataFieldFeature.PART)

			// Knows in which DataStructure it is contained
			field.dataStructure = lemmaStructure

			lemmaStructure.dataFields.add(field)
		]

		// Add DataOperations
		obj.operations.forEach([ op |
			val lemmaOpAndReferencedTypes = mapDomainObjectOperationToDataOperation(op, ctx)
			lemmaStructure.operations.add(lemmaOpAndReferencedTypes.key)
			lemmaOpAndReferencedTypes.key.dataStructure = lemmaStructure
			Util.mergeComplexTypeLists(referencedComplexTypes, lemmaOpAndReferencedTypes.value)
		])

		// Add repository of the domain object if one exists
		if (obj.repository !== null && obj.repository.operations.length > 0) {
			val lemmaRepo = mapRepositoryToDataStructure(obj.repository, ctx)
			repositoriesAndOperationTypes.add(lemmaRepo)
		}

		return referencedComplexTypes
	}

	/**
	 * Maps CML {@link Enum} to LEMMA DML {@link Enumeration}
	 */
	private def dispatch List<ComplexType> mapDomainObjectToConcreteComplexType(Enum obj, Context ctx) {
		val lemmaEnum = createEnumeration(obj.name)
		lemmaEnum.context = ctx

		markedTypes.put(obj.name, EcoreUtil.copy(lemmaEnum))

		obj.values.forEach [ enumValue |
			lemmaEnum.fields.add(createEnumerationField(enumValue.name))
		]

		return Collections.singletonList(lemmaEnum)
	}

	/**
	 * Maps a CML Operation ({@link ServiceOperation}, {@link RepositoryOperation}, {@link DomainOperation}) to a 
	 * LEMMA {@link DataOperation}
	 * 
	 * @returns Pair. First Element is the mapped DML {@link DataOperation}. Second element is a list
	 * of {@link ComplexType} that the data operations references.
	 */
	private def Pair<DataOperation, List<ComplexType>> mapCmlOperationToDataOperation(CmlOperation cmlOp, Context ctx) {
		val referencedComplexTypes = <ComplexType>newLinkedList

		val lemmaOp = DATA_FACTORY.createDataOperation
		lemmaOp.name = cmlOp.name

		if (cmlOp.returnType === null) {
			lemmaOp.hasNoReturnType = true
		} else { // Set ReturnType
			if (cmlOp.returnType.domainObjectType !== null) {
				referencedComplexTypes.addAll(mapComplexTypes(cmlOp.returnType, ctx))
				lemmaOp.complexReturnType = referencedComplexTypes.get(0)
				repositoriesAndOperationTypes.addIfNotExists(EcoreUtil.copy(lemmaOp.complexReturnType))
			} else {
				lemmaOp.primitiveReturnType = mapPrimitiveType(cmlOp.returnType.type)
			}
		}

		// Add DataOperationParameters
		cmlOp.parameters.forEach([ param |
			val lemmaParam = DATA_FACTORY.createDataOperationParameter
			lemmaParam.name = param.name
			if (param.parameterType.domainObjectType !== null) { // Complex Type
				val cTypes = mapComplexTypes(param.parameterType, ctx)
				lemmaParam.complexType = cTypes.get(0)
				repositoriesAndOperationTypes.addIfNotExists(EcoreUtil.copy(lemmaParam.complexType))
				// Need to merge because types can already exist due to return type
				Util.mergeComplexTypeLists(referencedComplexTypes, cTypes)
			} else { // Primitive Type
				lemmaParam.primitiveType = mapPrimitiveType(param.parameterType.type)
			}
			lemmaOp.parameters.add(lemmaParam)
		])

		return lemmaOp -> referencedComplexTypes
	}

	/**
	 * Maps CML {@link RepositoryOperation} to LEMMA DML {@link DataOperation}
	 */
	private def Pair<DataOperation, List<ComplexType>> mapRepositoryOperationToDataOperation(RepositoryOperation cmlOp,
		Context ctx) {
		return mapCmlOperationToDataOperation(new CmlOperation(cmlOp.name, cmlOp.returnType, cmlOp.parameters), ctx)
	}

	/**
	 * Maps CML {@link DomainObjectOperation} to LEMMA DML {@link DataOperation}
	 */
	private def Pair<DataOperation, List<ComplexType>> mapDomainObjectOperationToDataOperation(
		DomainObjectOperation cmlOp, Context ctx) {
		return mapCmlOperationToDataOperation(new CmlOperation(cmlOp.name, cmlOp.returnType, cmlOp.parameters), ctx)
	}

	/**
	 * Maps CML {@link ServiceOperation} to LEMMA DML {@link DataOperation}
	 */
	private def Pair<DataOperation, List<ComplexType>> mapServiceOperationToDataOperation(ServiceOperation cmlOp,
		Context ctx) {
		return mapCmlOperationToDataOperation(new CmlOperation(cmlOp.name, cmlOp.returnType, cmlOp.parameters), ctx)
	}

	/**
	 * Maps CML {@link Service} to LEMMA DML {@link ComplexType}
	 * 
	 * @param domainService true: map to LEMMA DML Domain Service. False: Map to LEMMA DML Application Service
	 * @returns Mapped service and complex types of operations and return type
	 */
	private def List<ComplexType> mapServiceToComplexType(Service cmlDomainService, boolean domainService,
		Context ctx) {
		val referencedComplexTypes = <ComplexType>newLinkedList

		val lemmaDomainService = DATA_FACTORY.createDataStructure
		lemmaDomainService.name = cmlDomainService.name
		referencedComplexTypes.add(lemmaDomainService)

		if (domainService) {
			lemmaDomainService.features.add(ComplexTypeFeature.DOMAIN_SERVICE)
		} else {
			lemmaDomainService.features.add(ComplexTypeFeature.APPLICATION_SERVICE)
		}

		cmlDomainService.operations.forEach [ cmlOp |
			val lemmaOpAndComplexTypes = mapServiceOperationToDataOperation(cmlOp, ctx)
			lemmaDomainService.operations.add(lemmaOpAndComplexTypes.key)
			Util.mergeComplexTypeLists(referencedComplexTypes, lemmaOpAndComplexTypes.value)
		]

		// Add repositories and referenced types of other bounded contexts (in cml)
		Util.mergeComplexTypeLists(referencedComplexTypes, repositoriesAndOperationTypes)

		return referencedComplexTypes
	}

	/** 
	 * Maps a CML {@link Repository} to a DML {@link DataStructure}.
	 */
	private def mapRepositoryToDataStructure(Repository repo, Context ctx) {
		val referencedTypes = <ComplexType>newLinkedList
		val lemmaStructure = DATA_FACTORY.createDataStructure
		lemmaStructure.name = repo.name
		lemmaStructure.features.add(ComplexTypeFeature.REPOSITORY)
		lemmaStructure.context = ctx
		referencedTypes.add(lemmaStructure)

		// Add DataOperations
		repo.operations.forEach([ op |
			val lemmaOpAndComplexTypes = mapRepositoryOperationToDataOperation(op, ctx)
			lemmaStructure.operations.add(lemmaOpAndComplexTypes.key)
			lemmaOpAndComplexTypes.key.dataStructure = lemmaStructure

			Util.mergeComplexTypeLists(referencedTypes, lemmaOpAndComplexTypes.value)
		])

		return lemmaStructure
	}

	/**
	 * Create a LEMMA Enumeration instance
	 */
	private def Enumeration createEnumeration(String name) {
		val enumeration = DATA_FACTORY.createEnumeration
		enumeration.name = name
		return enumeration
	}

	/**
	 * Create a LEMMA EnumerationField instance
	 */
	private def EnumerationField createEnumerationField(String name) {
		val enumerationField = DATA_FACTORY.createEnumerationField
		enumerationField.name = name
		return enumerationField
	}

	/**
	 * Create a LEMMA DataStructure with the given name, and a version and context
	 */
	private def DataStructure createDataStructure(String name) {
		val structure = DATA_FACTORY.createDataStructure
		structure.name = name
		return structure
	}

	/**
	 * Create a LEMMA DML {@link ListType} for a given {@link ComplexType}
	 */
	private def ListType createListTypeIfNotExisting(ComplexType type) {
		var list = type.alreadyExistingListType

		if (list === null) {
			list = DATA_FACTORY.createListType
			list.name = type.name + "List"

			val dataField = DATA_FACTORY.createDataField
			dataField.name = String.valueOf(type.name.toFirstLower.charAt(0))
			dataField.complexType = type

			list.dataFields.add(dataField)
		}

		return list
	}

	/**
	 * Create a LEMMA DML {@link ListType} for a given {@link PrimitiveType}
	 */
	private def ListType createListTypeIfNotExisting(PrimitiveType type) {
		var list = type.alreadyExistingListType

		if (list === null) {
			list = DATA_FACTORY.createListType
			list.name = type.typeName.toFirstUpper + "List"

			val dataField = DATA_FACTORY.createDataField
			dataField.name = String.valueOf(type.typeName.toFirstLower.charAt(0))
			dataField.primitiveType = type

			list.dataFields.add(dataField)
		}

		return list
	}

	/**
	 * Maps CML {@link Attribute#type} to LEMMA DML {@link PrimitiveType} and assigns it to the given
	 * {@link DataField}. If the {@link Attribute} has a List {@link CollectionType} a {@link ListType} will be assigned instead (and 
	 * created if not existed yet)
	 */
	private def mapAttributeTypeToPrimitiveTypeAndAssignItToDataField(Attribute attr, DataField field) {
		// Temp var in order to check if a ListType is needed
		val primitiveType = mapPrimitiveType(attr.type)

		// If a list is used in CML then an extra ListType must be generated for LEMMA DML
		// and the original expected PrimtiveType is substituted with a ComplexType (ListType)
		if (attr.collectionType.equals(CollectionType.LIST)) {
			val list = primitiveType.createListTypeIfNotExisting
			field.complexType = list
			this.listsToGenerate.add(list)
		} else {
			// field type (primitive)
			field.primitiveType = primitiveType
		}

		if (attr.key) {
			field.features.add(DataFieldFeature.IDENTIFIER)
		}
	}

	/**
	 * Maps CML {@link Reference#domainObjectType} to LEMMA DML {@link ComplexType} and returns it.
	 * If the {@link Reference} has a list type of {@link CollectionType} a LEMMA DML {@link ListType} will be mapped (and 
	 * created if not existed yet)
	 * 
	 * @returns List of {@link ComplexType}s. First element is the mapped DML {@link ComplexType}. All other elements
	 * are referenced by the first element.
	 */
	private def List<ComplexType> mapReferenceTypeToComplexType(Reference ref, Context ctx) {
		val cTypeAndReferencedTypes = findOrCreateComplexTypeBySimpleDomainObject(ref.domainObjectType, ctx)

		// If a list is used in CML then an extra list type must be generated for LEMMA DML
		if (ref.collectionType.equals(CollectionType.LIST)) {
			val list = cTypeAndReferencedTypes.get(0).createListTypeIfNotExisting
			this.listsToGenerate.add(list)
			cTypeAndReferencedTypes.set(0, list)
		}

		return cTypeAndReferencedTypes
	}

	/**
	 * Maps CML types (String values) to LEMMA DML types. 
	 * Checks if its a primitive type by checking the internal type map {@link KNOWN_TYPES}. 
	 * - If yes return the corresponding LEMMA DML type from the internal map {@link KNOWN_TYPES}.
	 * - If no, return "unspecified"
	 */
	private def PrimitiveType mapPrimitiveType(String type) {
		return switch (type.toLowerCase) {
			case "boolean":
				DATA_FACTORY.createPrimitiveBoolean
			case "string":
				DATA_FACTORY.createPrimitiveString
			,
			case "int":
				DATA_FACTORY.createPrimitiveInteger
			,
			case "integer":
				DATA_FACTORY.createPrimitiveInteger
			,
			case "long":
				DATA_FACTORY.createPrimitiveLong
			,
			case "double":
				DATA_FACTORY.createPrimitiveDouble
			,
			case "float":
				DATA_FACTORY.createPrimitiveFloat
			,
			case "date":
				DATA_FACTORY.createPrimitiveDate
			,
			case "datetime":
				DATA_FACTORY.createPrimitiveDate
			,
			case "timestamp":
				DATA_FACTORY.createPrimitiveDate
			default:
				DATA_FACTORY.createPrimitiveUnspecified
		}
	}

	/**
	 * Maps CML {@link org.contextmapper.tactic.dsl.tacticdsl.ComplexType} to LEMMA DML {@link ComplexType}s 
	 * by returning the needed {@link ComplexType} from the LEMMA {@link DataModel}.
	 * If its not existing, it will be created on the fly.
	 * 
	 * If the CML {@link org.contextmapper.tactic.dsl.tacticdsl.ComplexType} is a list then a 
	 * LEMMA {@link ListType} will be returned (and created if not existing)
	 * 
	 * @returns List. First element is the mapped Complex Type. All other elements are complex types 
	 * that are referenced by the first element.
	 */
	private def List<ComplexType> mapComplexTypes(org.contextmapper.tactic.dsl.tacticdsl.ComplexType cmlComplexType,
		Context ctx) {
		// If a list is used in CML then an extra list type must be generated for LEMMA DML
		if (cmlComplexType.collectionType.equals(CollectionType.LIST)) {
			// If cmlComplexType is a List, then the generic type (primitive or complex) of the list must be checked in order to
			// call the correct list creating method.
			var ListType listType = null
			if (cmlComplexType.domainObjectType !== null) { // Complex Type
				val lemmaComplexType = findOrCreateComplexTypeBySimpleDomainObject(cmlComplexType.domainObjectType, ctx)
				listType = lemmaComplexType.get(0).createListTypeIfNotExisting
			} else {
				val lemmaPrimitiveType = mapPrimitiveType(cmlComplexType.type)
				listType = lemmaPrimitiveType.createListTypeIfNotExisting
			}

			this.listsToGenerate.add(listType)
			return Collections.singletonList(listType)
		} else { // Not a list
			return findOrCreateComplexTypeBySimpleDomainObject(cmlComplexType.domainObjectType, ctx)
		}
	}

	/**
	 * Maps CML {@link SimpleDomainObject} to LEMMA DML {@link ComplexType}s 
	 * by returning the needed {@link ComplexType} from the LEMMA {@link DataModel}.
	 * If its not existing, it will be created on the fly.
	 */
	private def List<ComplexType> findOrCreateComplexTypeBySimpleDomainObject(SimpleDomainObject sObj, Context ctx) {
		for (lemmaComplexType : ctx.complexTypes) {
			if (sObj.name.equals(lemmaComplexType.name)) {
				// Already in the data model. Return as singleton list because all other
				// referenced types by lemmaComplexType are already in the context				
				return Collections.singletonList(lemmaComplexType)
			}
		}

		// Not in the data model, but might be "in mapping" (look ahead)
		for (type : markedTypes.keySet()) {
			if (sObj.name.equals(type))
				return Collections.singletonList(markedTypes.get(type))
		}

		// Not in the data model yet. Create it
		return mapSimpleDomainObjectToComplexType(sObj, ctx)
	}

	/**
	 * Checks whether a CML {@link DomainObject} is already mapped in a {@link Context}.
	 * Needed since a ComplexType is being created on the fly when not existing in the
	 * {@link LemmaDomainDataModelFactory#mapReferenceType} method.
	 */
	private def ComplexType alreadyMapped(DomainObject obj, Context ctx) {
		for (ComplexType cType : ctx.complexTypes) {
			if (cType.name.equals(obj.name))
				return cType;
		}

		return null;
	}

	/**
	 * Checks whether a {@link ListType} for a given {@link PrimitiveType} exists
	 */
	private def ListType alreadyExistingListType(PrimitiveType type) {
		val expectedName = String.valueOf(type.typeName.toFirstUpper + "List");

		for (listToGenerate : this.listsToGenerate) {
			if (listToGenerate.name.equals(expectedName)) {
				return listToGenerate
			}
		}

		return null
	}

	/**
	 * Checks whether a {@link ListType} for a given {@link ComplexType} exists
	 */
	private def ListType alreadyExistingListType(ComplexType type) {
		val expectedName = String.valueOf(type.name.toFirstUpper + "List");

		for (listToGenerate : this.listsToGenerate) {
			if (listToGenerate.name.equals(expectedName)) {
				return listToGenerate
			}
		}

		return null
	}

	private def addIfNotExists(List<ComplexType> list, ComplexType element) {
		val check = list.stream.filter [ checkMe |
			checkMe.name.equals(element.name)
		].findAny

		if (check.empty) {
			list.add(EcoreUtil.copy(element))
		}
	}

}
