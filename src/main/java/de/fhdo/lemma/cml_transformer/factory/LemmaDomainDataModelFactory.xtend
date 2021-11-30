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
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
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
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceDownstreamGenerator
import de.fhdo.lemma.cml_transformer.factory.context_map.AnticorruptionLayerGenerator
import org.eclipse.xtend.lib.annotations.Accessors
import de.fhdo.lemma.cml_transformer.factory.context_map.ConformistGenerator
import org.eclipse.emf.ecore.util.EcoreUtil

/**
 * Model transformation from ContextMapper DSL (CML) to LEMMA Domain Data Modeling Language (DML)
 */
class LemmaDomainDataModelFactory {
	static val DATA_FACTORY = DataFactory.eINSTANCE
	
	/**
	 * Maps CML {@link Aggregate} to LEMMA DML {@link ComplexType}s.
	 * 
	 * Since CML aggregates all Domain Services, Entities and Value Objects, we need to extract those and put
	 * them in a list in order to add them into the Lemma {@link Context}.
	 * 
	 * Static variant of the method {@link LemmaDomainDataModelFactory#mapAggregate2ComplexType} in order
	 * to map a single CML {@link Aggregate}.
	 */
	static def List<ComplexType> mapAggregate2ComplexType(ContextMappingModel cmlModel, Aggregate agg) {
		val dataModelFactory = new LemmaDomainDataModelFactory(cmlModel)
		dataModelFactory.dataModel = DATA_FACTORY.createDataModel
		// contains all extracted Entities and Value Objects of an CML Aggregate
		val dataStructures = <ComplexType>newLinkedList
		val ctx = DATA_FACTORY.createContext
		

		// A CML Aggregate contains Entities, Value Objects and Domain Services
		for (obj : agg.domainObjects) {
			val lemmaStructure = dataModelFactory.mapSimpleDomainObject2ComplexType(obj, ctx)

			dataStructures.add(lemmaStructure)
		}

		// Creating domain services
		for (service : agg.services) {
			val lemmaDomainService = dataModelFactory.mapServiceToComplexType(service, true, ctx)
			dataStructures.add(lemmaDomainService)
		}

		return dataStructures
	}

	/**
	 * Input Model (CML)
	 */
	ContextMappingModel cmlModel;

	/**
	 * Output Model (LEMMA DML)
	 */
	DataModel dataModel;

	/**
	 * Keeps track of lists that must be generated. LEMMA DML needs extra list types with an own declaration for each
	 * kind of list (primitive list, complex type list etc.)
	 * {@link ListType}s are not put directly into the List of {@link ComplexType}s of a {@link Context} in order to make
	 * a check for already created {@link ListType}s easier and faster.
	 */
	@Accessors(PUBLIC_GETTER) List<ListType> listsToGenerate = newLinkedList;

	new(ContextMappingModel cmlModel) {
		this.cmlModel = cmlModel
	}

	/**
	 * Maps CML Model {@link BoundedContext} to LEMMA DML Model {@link DataModel}. The latter containing one {@link Context}
	 */
	def DataModel generateDataModel(BoundedContext bc) {
		listsToGenerate = newLinkedList
		dataModel = DATA_FACTORY.createDataModel

		val ctx = mapBoundedContext2Context(bc);
		// Tell the Context in which DataModel it is and visa versa
		ctx.dataModel = dataModel
		dataModel.contexts.add(ctx)

		return dataModel
	}

	/**
	 * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
	 */
	private def Context mapBoundedContext2Context(BoundedContext bc) {
		val ctx = DATA_FACTORY.createContext
		ctx.name = bc.name

		// Entities, Value Objects, Repositories, Domain Services, Aggregates
		if (bc.aggregates !== null) {
			bc.aggregates.forEach [ agg |
				val dataStructures = mapAggregate2ComplexType(agg, ctx)
				dataStructures.forEach [ struct |
					// Tell the DataStructure in which context it is and visa versa
					struct.context = ctx;
					ctx.complexTypes.add(struct)
				]
			]
		}

		// Application Service
		if (bc.application !== null) { // Null-Safe Operator does not work ?
			bc.application.services.forEach [ appService |
				val lemmaAppService = mapServiceToComplexType(appService, false, ctx)
				ctx.complexTypes.add(lemmaAppService)
			]
		}

		// Lists
		ctx.complexTypes.addAll(listsToGenerate)

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
	 */
	private def List<ComplexType> mapAggregate2ComplexType(Aggregate agg, Context ctx) {
		// contains all extracted Entities and Value Objects of an CML Aggregate
		val dataStructures = <ComplexType>newLinkedList

		// A CML Aggregate contains Entities, Value Objects and Repositories
		for (obj : agg.domainObjects) {
			val lemmaStructure = mapSimpleDomainObject2ComplexType(obj, ctx)

			dataStructures.add(lemmaStructure)
		}

		// Creating domain services
		for (service : agg.services) {
			val lemmaDomainService = mapServiceToComplexType(service, true, ctx)
			dataStructures.add(lemmaDomainService)
		}

		return dataStructures
	}

	/**
	 * Maps CML {@link SimpleDomainObject} (super class of {@link DomainObject} and {@link java.lang.Enum})
	 * to a LEMMA {@link ComplexType}.
	 * In other words it creates DataStructures and Enums depending on the given {@link SimpleDomainObject}
	 */
	private def ComplexType mapSimpleDomainObject2ComplexType(SimpleDomainObject sObj, Context ctx) {
		// Depending on concrete Type of SimpleDomainObject call different Method.
		return mapDomainObject2ConcreteComplexType(sObj, ctx)

	}

	/** 
	 * Maps CML {@link ValueObject} and {@link Entity} to LEMMA DML {@link DataStructure}. 
	 * 
	 * @param obj CML {@link DomainObject} to map
	 * @param ctx LEMMA {@link Context} which is needed for already checked domain objects
	 */
	private def dispatch ComplexType mapDomainObject2ConcreteComplexType(DomainObject obj, Context ctx) {
		val alreadyMappedType = obj.alreadyMapped(ctx)
		if (alreadyMappedType !== null) {
			return EcoreUtil.copy(alreadyMappedType)
		}

		val lemmaStructure = createDataStructure(obj.name)

		// Determine LEMMA Features
		if (obj.aggregateRoot) {
			lemmaStructure.features.add(ComplexTypeFeature.AGGREGATE)
		}
		val feature = if (obj instanceof Entity) {
				ComplexTypeFeature.ENTITY
			} else if (obj instanceof ValueObject) {
				ComplexTypeFeature.VALUE_OBJECT
			} else { // Event
				ComplexTypeFeature.DOMAIN_EVENT
			}
		lemmaStructure.features.add(feature)

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

			field.complexType = mapReferenceTypeToComplexType(ref, field, ctx)

			// Knows in which DataStructure it is contained
			field.dataStructure = lemmaStructure

			lemmaStructure.dataFields.add(field)
		]

		// Add DataOperations
		obj.operations.forEach([ op |
			val lemmaOp = mapDomainObjectOperationToDataOperation(op, ctx)
			lemmaStructure.operations.add(lemmaOp)
			lemmaOp.dataStructure = lemmaStructure
		])

		return lemmaStructure
	}

	/**
	 * Maps CML {@link Enum} to LEMMA DML {@link Enumeration}
	 */
	private def dispatch ComplexType mapDomainObject2ConcreteComplexType(Enum obj, Context ctx) {
		val lemmaEnum = createEnumeration(obj.name)

		obj.values.forEach [ enumValue |
			lemmaEnum.fields.add(createEnumerationField(enumValue.name))
		]

		return lemmaEnum
	}

	/**
	 * Maps CML {@link ServiceOperation} to LEMMA DML {@link DataOperation}
	 */
	private def DataOperation mapDomainObjectOperationToDataOperation(ServiceOperation cmlOp, Context ctx) {
		val lemmaOp = DATA_FACTORY.createDataOperation
		lemmaOp.name = cmlOp.name

		if (cmlOp.returnType === null) {
			lemmaOp.hasNoReturnType = true
		} else { // Set ReturnType
			if (cmlOp.returnType.collectionType === CollectionType.LIST || cmlOp.returnType.domainObjectType !== null) { // Complex Type
				lemmaOp.complexReturnType = mapComplexTypes(cmlOp.returnType, ctx)
			} else {
				lemmaOp.primitiveReturnType = mapPrimitiveType(cmlOp.returnType.type)
			}
		}

		// Add DataOperationParameters
		cmlOp.parameters.forEach([ param |
			val lemmaParam = DATA_FACTORY.createDataOperationParameter
			lemmaParam.name = param.name
			if (param.parameterType.collectionType === CollectionType.LIST ||
				param.parameterType.domainObjectType !== null) { // Complex Type
				lemmaParam.complexType = mapComplexTypes(param.parameterType, ctx)
			} else { // Primitive Type
				lemmaParam.primitiveType = mapPrimitiveType(param.parameterType.type)
			}
			lemmaOp.parameters.add(lemmaParam)
		])

		return lemmaOp
	}

	/**
	 * Maps CML {@link DomainObjectOperation} to LEMMA DML {@link DataOperation}
	 */
	private def DataOperation mapDomainObjectOperationToDataOperation(DomainObjectOperation cmlOp, Context ctx) {
		val lemmaOp = DATA_FACTORY.createDataOperation
		lemmaOp.name = cmlOp.name

		if (cmlOp.returnType === null) {
			lemmaOp.hasNoReturnType = true
		} else { // Set ReturnType
			if (cmlOp.returnType.domainObjectType !== null) {
				lemmaOp.complexReturnType = mapComplexTypes(cmlOp.returnType, ctx)
			} else {
				lemmaOp.primitiveReturnType = mapPrimitiveType(cmlOp.returnType.type)
			}
		}

		// Add DataOperationParameters
		cmlOp.parameters.forEach([ param |
			val lemmaParam = DATA_FACTORY.createDataOperationParameter
			lemmaParam.name = param.name
			if (param.parameterType.domainObjectType !== null) { // Complex Type
				lemmaParam.complexType = mapComplexTypes(param.parameterType, ctx)
			} else { // Primitive Type
				lemmaParam.primitiveType = mapPrimitiveType(param.parameterType.type)
			}
			lemmaOp.parameters.add(lemmaParam)
		])

		return lemmaOp
	}

	/**
	 * Maps CML {@link Service} to LEMMA DML {@link ComplexType}
	 * 
	 * @param domainService true: map to LEMMA DML Domain Service. False: Map to LEMMA DML Application Service
	 */
	private def ComplexType mapServiceToComplexType(Service cmlDomainService, boolean domainService, Context ctx) {
		val lemmaDomainService = DATA_FACTORY.createDataStructure
		lemmaDomainService.name = cmlDomainService.name
		if (domainService) {
			lemmaDomainService.features.add(ComplexTypeFeature.DOMAIN_SERVICE)
		} else {
			lemmaDomainService.features.add(ComplexTypeFeature.APPLICATION_SERVICE)
		}

		cmlDomainService.operations.forEach [ cmlOp |
			val lemmaOp = mapDomainObjectOperationToDataOperation(cmlOp, ctx)
			lemmaDomainService.operations.add(lemmaOp)
		]

		return lemmaDomainService
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
	 */
	private def mapReferenceTypeToComplexType(Reference ref, DataField field, Context ctx) {
		var complexType = findComplexTypeBySimpleDomainObject(ref.domainObjectType, ctx)

		// If a list is used in CML then an extra list type must be generated for LEMMA DML
		if (ref.collectionType.equals(CollectionType.LIST)) {
			val list = complexType.createListTypeIfNotExisting
			this.listsToGenerate.add(list)
			complexType = list
		}

		if (ref.key) {
			field.features.add(DataFieldFeature.IDENTIFIER)
		}

		// Complex Types are always a part of the aggregate
		field.features.add(DataFieldFeature.PART)

		return complexType
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
	 */
	private def ComplexType mapComplexTypes(org.contextmapper.tactic.dsl.tacticdsl.ComplexType cmlComplexType, Context ctx) {
		// If a list is used in CML then an extra list type must be generated for LEMMA DML
		if (cmlComplexType.collectionType.equals(CollectionType.LIST)) {
			// If cmlComplexType is a List, then the generic type (primitive or complex) of the list must be checked in order to
			// call the correct list creating method.
			var ListType list = null
			if (cmlComplexType.domainObjectType !== null) { // Complex Type
				val lemmaComplexType = findComplexTypeBySimpleDomainObject(cmlComplexType.domainObjectType, ctx)
				list = lemmaComplexType.createListTypeIfNotExisting
			} else {
				val lemmaPrimitiveType = mapPrimitiveType(cmlComplexType.type)
				list = lemmaPrimitiveType.createListTypeIfNotExisting
			}

			this.listsToGenerate.add(list)
			return list
		} else { // Not a list
		// Check if already mapped
			val lemmaComplexType = findComplexTypeBySimpleDomainObject(cmlComplexType.domainObjectType, ctx)
			for (cType : this.dataModel.complexTypes) {
				if (cType.name.equals(lemmaComplexType.name))
					return lemmaComplexType;
			}

			// Not mapped yet cause not in the data model yet. Create it
			return mapSimpleDomainObject2ComplexType(cmlComplexType.domainObjectType, ctx)

		}
	}

	/**
	 * Maps CML {@link SimpleDomainObject} to LEMMA DML {@link ComplexType}s 
	 * by returning the needed {@link ComplexType} from the LEMMA {@link DataModel}.
	 * If its not existing, it will be created on the fly.
	 */
	private def ComplexType findComplexTypeBySimpleDomainObject(SimpleDomainObject sObj, Context ctx) {
		for (lemmaComplexType : ctx.complexTypes) {
			if (sObj.name.equals(lemmaComplexType.name))
				return lemmaComplexType;
		}

		// Not in the data model yet. Create it
		return mapSimpleDomainObject2ComplexType(sObj, ctx)
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

}
