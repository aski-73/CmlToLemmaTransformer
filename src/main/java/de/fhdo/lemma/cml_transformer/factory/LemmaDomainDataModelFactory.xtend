package de.fhdo.lemma.cml_transformer.factory

import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
import de.fhdo.lemma.data.DataModel
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.DataFactory
import org.eclipse.emf.ecore.EObject
import java.util.List
import de.fhdo.lemma.data.Version
import de.fhdo.lemma.data.EnumerationField
import de.fhdo.lemma.data.DataStructure
import org.contextmapper.tactic.dsl.tacticdsl.DomainObject
import org.contextmapper.dsl.contextMappingDSL.Aggregate
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject
import org.contextmapper.tactic.dsl.tacticdsl.Entity
import org.contextmapper.tactic.dsl.tacticdsl.ValueObject
import de.fhdo.lemma.data.ComplexTypeFeature
import de.fhdo.lemma.data.ListType
import de.fhdo.lemma.data.Enumeration
import org.contextmapper.dsl.contextMappingDSL.BoundedContextType
import de.fhdo.lemma.data.Type
import de.fhdo.lemma.data.PrimitiveBoolean
import de.fhdo.lemma.data.PrimitiveString
import de.fhdo.lemma.data.PrimitiveInteger
import de.fhdo.lemma.data.PrimitiveLong
import de.fhdo.lemma.data.PrimitiveDouble
import de.fhdo.lemma.data.PrimitiveFloat
import de.fhdo.lemma.data.PrimitiveType
import org.contextmapper.tactic.dsl.tacticdsl.Reference
import de.fhdo.lemma.data.PrimitiveUnspecified
import org.contextmapper.tactic.dsl.tacticdsl.Service
import org.contextmapper.tactic.dsl.tacticdsl.ServiceOperation
import de.fhdo.lemma.data.DataOperation
import org.contextmapper.tactic.dsl.tacticdsl.DomainObjectOperation

class LemmaDomainDataModelFactory {
	static val DATA_FACTORY = DataFactory.eINSTANCE

	static val PRIMITIVE_LEMMA_TYPES = #[
		"int",
		"long",
		"float",
		"double",
		"string",
		"boolean"
	]

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

	new(ContextMappingModel cmlModel) {
		this.cmlModel = cmlModel
	}

	/**
	 * Maps CML Model {@link ContextMappingModel} to LEMMA DML Model {@link DataModel}
	 */
	def DataModel generateDataModel() {
		this.dataModel = DATA_FACTORY.createDataModel

		cmlModel.boundedContexts.forEach [ bc |
			val ctx = mapBoundedContext2Context(bc);

			// Tell the Context in which DataModel it is and visa versa
			ctx.dataModel = dataModel
			dataModel.contexts.add(ctx)
		]

		return dataModel
	}

	/**
	 * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
	 */
	private def Context mapBoundedContext2Context(BoundedContext bc) {
		val ctx = DATA_FACTORY.createContext
		ctx.name = bc.name

		this.currentCtx = ctx;

		// Entities, Value Objects, Repositories, Domain Services, Aggregates
		if (bc.aggregates != null) {
			bc.aggregates.forEach [ agg |
				val dataStructures = mapAggregate2ComplexType(agg)
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
				val lemmaAppService = mapServiceToComplexType(appService, false)
				ctx.complexTypes.add(lemmaAppService)
			]
		}

		return ctx
	}

	/**
	 * Maps CML {@link Aggregate} to LEMMA DML {@link ComplexType}s.
	 * 
	 * Since CML aggregates all Domain Services, Entities and Value Objects, we need to extract those and put
	 * them in a list in order to add them into the Lemma {@link Context}
	 */
	private def List<ComplexType> mapAggregate2ComplexType(Aggregate agg) {
		// contains all extracted Entities and Value Objectsof an CML Aggregate
		val dataStructures = <ComplexType>newLinkedList

		// A CML Aggregate contains Entities, Value Objects and Domain Services
		for (obj : agg.domainObjects) {
			val lemmaStructure = mapSimpleDomainObject2ComplexType(obj)

			dataStructures.add(lemmaStructure)
		}

		// Creating domain services
		for (service : agg.services) {
			val lemmaDomainService = mapServiceToComplexType(service, true)
			dataStructures.add(lemmaDomainService)
		}

		return dataStructures
	}

	/**
	 * Maps CML {@link SimpleDomainObject} (super class of {@link DomainObject} and {@link Enum})
	 * to a LEMMA {@link ComplexType}.
	 * In other words it creates DataStructures and Enums depending on the given {@link SimpleDomainObject}
	 */
	private def ComplexType mapSimpleDomainObject2ComplexType(SimpleDomainObject sObj) {
		// Depending on concrete Type of SimpleDomainObject call different Method.
		return mapDomainObject2ConcreteComplexType(sObj)

	}

	/** 
	 * Maps CML {@link ValueObject} and {@link Entity} to LEMMA DML {@link DataStructure}
	 * */
	private def dispatch ComplexType mapDomainObject2ConcreteComplexType(DomainObject obj) {
		val alreadyMappedType = obj.alreadyMapped
		if (alreadyMappedType != null) {
			return alreadyMappedType
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

			// field type (primitive)
			field.primitiveType = mapPrimitiveType(attr.type)

			// Knows in which DataStructure it is contained
			field.dataStructure = lemmaStructure

			lemmaStructure.dataFields.add(field)
		]
		// ... while References are complex types
		obj.references.forEach [ ref |
			val field = DATA_FACTORY.createDataField
			field.name = ref.name
			field.immutable = ref.isNotChangeable

			// field type (primitive)
			field.complexType = mapReferenceType(ref.domainObjectType)

			// Knows in which DataStructure it is contained
			field.dataStructure = lemmaStructure

			lemmaStructure.dataFields.add(field)
		]

		// Add DataOperations
		obj.operations.forEach([ op |
			val lemmaOp = mapServiceOperationToDataOperation(op)
			lemmaStructure.operations.add(lemmaOp)
		])

		return lemmaStructure
	}

	/**
	 * Maps CML {@link org.contextmapper.tactic.dsl.tacticdsl.Enum} to LEMMA DML {@link Enumeration}
	 */
	private def dispatch ComplexType mapDomainObject2ConcreteComplexType(
		org.contextmapper.tactic.dsl.tacticdsl.Enum obj) {
		val lemmaEnum = createEnumeration(obj.name)

		obj.values.forEach [ enumValue |
			lemmaEnum.fields.add(createEnumerationField(enumValue.name))
		]

		return lemmaEnum
	}

	/**
	 * Maps CML {@link ServiceOperation} to LEMMA DML {@link DataOperation}
	 */
	private def DataOperation mapServiceOperationToDataOperation(ServiceOperation cmlOp) {
		val lemmaOp = DATA_FACTORY.createDataOperation
		lemmaOp.name = cmlOp.name

		if (cmlOp.returnType === null) {
			lemmaOp.hasNoReturnType = true
		} else { // Set ReturnType
			if (cmlOp.returnType.domainObjectType != null) {
				lemmaOp.complexReturnType = mapReferenceType(cmlOp.returnType.domainObjectType)
			} else {
				lemmaOp.primitiveReturnType = mapPrimitiveType(cmlOp.returnType.type)
			}
		}

		// Add DataOperationParameters
		cmlOp.parameters.forEach([ param |
			val lemmaParam = DATA_FACTORY.createDataOperationParameter
			lemmaParam.name = param.name
			if (param.parameterType.domainObjectType !== null) { // Complex Type
				lemmaParam.complexType = mapReferenceType(param.parameterType.domainObjectType)
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
	private def DataOperation mapServiceOperationToDataOperation(DomainObjectOperation cmlOp) {
		val lemmaOp = DATA_FACTORY.createDataOperation
		lemmaOp.name = cmlOp.name

		if (cmlOp.returnType === null) {
			lemmaOp.hasNoReturnType = true
		} else { // Set ReturnType
			if (cmlOp.returnType.domainObjectType != null) {
				lemmaOp.complexReturnType = mapReferenceType(cmlOp.returnType.domainObjectType)
			} else {
				lemmaOp.primitiveReturnType = mapPrimitiveType(cmlOp.returnType.type)
			}
		}

		// Add DataOperationParameters
		cmlOp.parameters.forEach([ param |
			val lemmaParam = DATA_FACTORY.createDataOperationParameter
			lemmaParam.name = param.name
			if (param.parameterType.domainObjectType !== null) { // Complex Type
				lemmaParam.complexType = mapReferenceType(param.parameterType.domainObjectType)
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
	private def ComplexType mapServiceToComplexType(Service cmlDomainService, boolean domainService) {
		val lemmaDomainService = DATA_FACTORY.createDataStructure
		lemmaDomainService.name = cmlDomainService.name
		if (domainService) {
			lemmaDomainService.features.add(ComplexTypeFeature.DOMAIN_SERVICE)
		} else {
			lemmaDomainService.features.add(ComplexTypeFeature.APPLICATION_SERVICE)
		}

		cmlDomainService.operations.forEach [ cmlOp |
			val lemmaOp = mapServiceOperationToDataOperation(cmlOp)
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
//        enumeration.version = getOrCreateVersion(avroNamespace)
//        enumeration.context = getOrCreateContext(avroNamespace)
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
//        structure.version = 
//        structure.context = 
		return structure
	}

	/**
	 * Create a LEMMA List with the given name
	 */
	private def ListType createListType(String name) {
		val listType = DATA_FACTORY.createListType
		listType.name = name
//        listType.version = getOrCreateVersion(avroNamespace)
//        listType.context = getOrCreateContext(avroNamespace)
//        if (generateUniqueName)
//            listType.name = qualifiedName(listType).toUniqueName(DataModel)
		return listType
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
	 * Maps CML reference types to LEMMA DML complex types by returning the needed Complex Type from the LEMMA data model.
	 * If its not existing, it will be created on the fly.
	 */
	private def ComplexType mapReferenceType(SimpleDomainObject sObj) {
		for (cType : this.dataModel.complexTypes) {
			if (sObj.equals(cType.name))
				return cType;
		}

		// Not in the data model yet. Create it
		return mapSimpleDomainObject2ComplexType(sObj)
	// Return null to mark it. Needs to be reevaluated as soon as the corresponding data structure is created
	}

	/**
	 * Checks whether a CML {@link DomainObject} was already mapped.
	 * Needed since a ComplexType is being created on the fly when not existing in the
	 * {@link LemmaDomainDataModelFactory#mapReferenceType} method.
	 */
	private def ComplexType alreadyMapped(DomainObject obj) {
		for (ComplexType cType : this.currentCtx.complexTypes) {
			if (cType.name.equals(obj.name))
				return cType;
		}

		return null;
	}
}
