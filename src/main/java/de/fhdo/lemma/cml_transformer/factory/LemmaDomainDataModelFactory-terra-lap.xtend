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

class LemmaDomainDataModelFactory {
    static val DATA_FACTORY = DataFactory.eINSTANCE
    
	
	private ContextMappingModel cmlModel;
	
	
	
	/**
	 * Maps CML Model to LEMMA DML Model
	 */
	def DataModel generateDataModel() {
	}
	
	/**
	 * Maps CML {@link BoundedContext} to LEMMA DML {@link Context}
	 */
	private def Context mapBoundedContext2Context(BoundedContext bc) {
		
	}
	
	/**
	 * Maps CML {@link Aggregate} to LEMMA DML {@link DataStructure}
	 */
	private def DataStructure mapAggregate2DataStructure(Context ctx, Aggregate agg) {
		val lemmaAggregate = createDataStructure(agg.name)
		lemmaAggregate.context = ctx
		
		// A CML Aggregates contains Entities, Value Objects and Domain Services
		for (obj : agg.domainObjects) {
			val lemmaStructure = mapSimpleDomainObject2DataStructure(obj);
			
			
			
			ctx.complexTypes.add(lemmaStructure);
		}
		
		return lemmaAggregate

//		// Creating domain services
//		for (service : agg.services) {
//			val domainService = new LemmaStructure(service.name, "structure", "domainService")
//			domainService.attributeList.addAll(processDomainServiceOperations(service, listsToGenerate))
//
//			lemmaContext.structureList.add(domainService)
//		}
			
		
	}
	
	private def DataStructure mapSimpleDomainObject2DataStructure(SimpleDomainObject sObj) {
		val lemmaStructure = createDataStructure(sObj.name)
		
		// Depending on concrete Type of SimpleDomainObject call different Method.
		// TODO
		
		return lemmaStructure;
		
	}
	
	/** 
	 * Maps CML {@link ValueObject} and {@link Entity} to LEMMA DML {@link DataStructure}
	 * */
	private def DataStructure mapDomainObject2DataStructure(DomainObject obj) {
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
}
