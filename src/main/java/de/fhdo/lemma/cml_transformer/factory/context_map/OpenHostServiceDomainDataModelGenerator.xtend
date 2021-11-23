package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.data.Context
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole
import java.util.stream.Collectors
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.data.DataFactory
import de.fhdo.lemma.data.ComplexTypeFeature
import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory
import de.fhdo.lemma.data.DataOperation
import org.eclipse.emf.ecore.util.EcoreUtil

/**
 * Downstream implementation of an OHS
 * 
 * Adds a new Application Service in the {@link DataModel} that represents an "Accessor". Its task is to communicate with 
 * the Api of the OHS upstream that exposes an aggregate
 */
class OpenHostServiceDomainDataModelGenerator {
	static val DATA_FACTORY = DataFactory.eINSTANCE

	/**
	 * Mapped LEMMA DML {@link Context} which receives an Accessor
	 */
	private Context context

	/**
	 * The whole LEMMA DML Model in order to find the upstream part of the OHS relation.
	 */
	private DataModel dataModel

	/**
	 * Context Map of the CML Model which contains  OHS-relations of the LEMMA DML {@link Context}. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the Context Map in order to map them.
	 */
	private ContextMap map

	new(Context context, DataModel dataModel, ContextMap map) {
		this.context = context
		this.dataModel = dataModel
		this.map = map
	}

	def void mapOhsDownstream() {
		val rr = filterDownstreamRelationships()

		if (rr.size == 0) {
			return
		}

		// For every Application Service that is responsible for exposing an aggregate an Accessor will be generated.
		
		for (rel : rr) {
			val upstreamBoundedContext = (rel as UpstreamDownstreamRelationship).upstream
			// Look up the Context that contains the Application Services which expose the aggregates of the relationship
			this.dataModel.contexts.stream.filter [ context |
				context.name.equals(upstreamBoundedContext.name)
			].findFirst().ifPresent() [ upstreamContext |
				// For every exposed aggregate X look up the Application Service in the LEMMA Context that exposes X
				for (exposedAggregate : (rel as UpstreamDownstreamRelationship).upstreamExposedAggregates) {
					val appService = upstreamContext.complexTypes.stream.filter [ cType |
						cType.name.equals(exposedAggregate.name + "Api")
					].findFirst()

					// Check if an Accessor is already defined for the Api
					val accessorService = this.context.complexTypes.stream.filter [ cType |
						cType.name.equals(exposedAggregate.name + "Accessor")
					].findFirst()

					if (appService.isPresent && !accessorService.isPresent) {
						// Create accessor
						val newAccessorService = mapApplicationServiceToAccessor(appService.get as DataStructure)
						this.context.complexTypes.add(newAccessorService)
					}
				}
			]

		}
	}

	/**
	 * Maps an Application Service that represents the API exposing an Aggregate to another Application Service that
	 * represents an Accessor accessing the API
	 */
	private def mapApplicationServiceToAccessor(DataStructure appService) {
		val accessor = DATA_FACTORY.createDataStructure
		accessor.name = appService.name.replace("Api", "Accessor")
		accessor.features.add(ComplexTypeFeature.APPLICATION_SERVICE)
		
		// Add operations
		appService.operations.forEach[appServiceOp|
			// But only add those operations that have a Dtos as parameters or only primitive types
			// in order to keep the domain model save from the upstream domain model
			val dto = appServiceOp.parameters.filter [ param |
				param.complexType !== null && param.complexType.name.contains("Dto")
			]
 			
			if (dto.size == appServiceOp.parameters.size) {
				accessor.operations.add(EcoreUtil.copy(appServiceOp))
				// In order to use the dto, it must be added to the Context TODO s. Fragen
				//this.context.complexTypes.add(dto.get.complexType)
			} 
			else { // check for only primitives
				val primitives = appServiceOp.parameters.stream.filter [ param |
					param.primitiveType !== null
				].collect(Collectors.toList())
				if (primitives.size == appServiceOp.parameters.size) {
					accessor.operations.add(EcoreUtil.copy(appServiceOp))
				}
			}
		]

		return accessor
	}

	/**
	 * Filter the relations where {@link Context} is the downstream of a OHS relation. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the relation in order to map them.
	 */
	private def filterDownstreamRelationships() {
		return map.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstream.name.equals(context.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE)
		]).collect(Collectors.toList())
	}
}
