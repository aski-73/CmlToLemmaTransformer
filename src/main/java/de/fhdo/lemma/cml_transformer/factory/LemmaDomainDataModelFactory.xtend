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

class LemmaDomainDataModelFactory {
	static val DATA_FACTORY = DataFactory.eINSTANCE

	/**
	 * Maps CML Model {@link ContextMappingModel} to LEMMA DML Model {@link DataModel}
	 */
	def DataModel generateDataModel(ContextMappingModel cmlModel) {
		val dataModel = DATA_FACTORY.createDataModel
		cmlModel.boundedContexts.forEach[bc |
			val ctx = mapBoundedContext2Context(bc);
			
			// Tell the Context in which DataModel it is and visa versa
			ctx.dataModel =  dataModel
			dataModel.contexts.add(ctx)
			
			//  The DataModel also contains references to all ComplexTypes of all Context instances
			dataModel.complexTypes.addAll(ctx.complexTypes)
		]
		
		return dataModel
	}

	/**
	 * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
	 */
	private def Context mapBoundedContext2Context(BoundedContext bc) {
		val ctx = DATA_FACTORY.createContext

		bc.aggregates.forEach [ agg |
			val dataStructures = mapAggregate2ComplexType(agg)
			dataStructures.forEach [ struct |
				// Tell the DataStructure in which context it is and visa versa
				struct.context = ctx;
				ctx.complexTypes.add(struct)
			]
		]

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

		val lemmaAggregate = createDataStructure(agg.name)
		dataStructures.add(lemmaAggregate)

		// A CML Aggregate contains Entities, Value Objects and Domain Services
		for (obj : agg.domainObjects) {
			val lemmaStructure = mapSimpleDomainObject2ComplexType(obj)

			dataStructures.add(lemmaStructure)
		}

		return dataStructures

//		// Creating domain services
//		for (service : agg.services) {
//			val domainService = new LemmaStructure(service.name, "structure", "domainService")
//			domainService.attributeList.addAll(processDomainServiceOperations(service, listsToGenerate))
//
//			lemmaContext.structureList.add(domainService)
//		}
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
		val lemmaStructure = createDataStructure(obj.name)

		// Determine LEMMA Feature
		val feature = if (obj instanceof Entity) {
				ComplexTypeFeature.ENTITY
			} else if (obj instanceof ValueObject) {
				ComplexTypeFeature.VALUE_OBJECT
			} else { // Event
				ComplexTypeFeature.DOMAIN_EVENT
			}

		lemmaStructure.features.add(feature)

		// Add Operations
		// TODO
		// Add Attributes
		// TODO
		return lemmaStructure
	}

	/**
	 * Maps CML {@link org.contextmapper.tactic.dsl.tacticdsl.Enum} to LEMMA DML {@link Enumeration}
	 */
	private def dispatch ComplexType mapDomainObject2ConcreteComplexType(org.contextmapper.tactic.dsl.tacticdsl.Enum obj) {
		val lemmaEnum = createEnumeration(obj.name)

		obj.values.forEach [ enumValue |
			lemmaEnum.fields.add(createEnumerationField(enumValue.name))
		]

		return lemmaEnum
	}

	/**
	 * Create a new LEMMA DataModel from the given EObject instances
	 */
	private def DataModel createDataModel(List<EObject> eObjects) {
		val dataModel = DATA_FACTORY.createDataModel
//        val versions = <String, Version>newLinkedHashMap
//        val contexts = <String, Context>newLinkedHashMap
//        val complexTypes = <String, ComplexType>newLinkedHashMap
//
//        eObjects.forEach[
//            switch(it) {
//                Version: versions.put(it.name, it)
//                Context: contexts.put(qualifiedName(it), it)
//                ComplexType: complexTypes.put(qualifiedName(it), it)
//            }
//        ]
//
//        if (!versions.empty)
//            dataModel.versions.addAll(versions.values)
//        else if (!contexts.empty)
//            dataModel.contexts.addAll(contexts.values)
//        else
//            dataModel.complexTypes.addAll(complexTypes.values)
		return dataModel
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
}
