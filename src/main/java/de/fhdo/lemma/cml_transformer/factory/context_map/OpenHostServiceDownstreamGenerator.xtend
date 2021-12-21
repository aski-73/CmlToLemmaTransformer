package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.data.ComplexTypeFeature
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataFactory
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataStructure
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole
import org.eclipse.emf.ecore.util.EcoreUtil
import java.util.List
import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory
import de.fhdo.lemma.cml_transformer.Util

/**
 * Downstream implementation of an OHS
 * 
 * Adds a new Application Service in the {@link DataModel} that represents an "Accessor". Its task is to communicate with 
 * the Api of the OHS upstream that exposes an aggregate
 */
class OpenHostServiceDownstreamGenerator extends AbstractRelationshipGenerator {
	static val DATA_FACTORY = DataFactory.eINSTANCE

	new(Context context, ContextMap map, List<DataModel> dataModels) {
		super(context, map, dataModels)
	}

	override map() {
		val rr = filter()

		if (rr.size == 0) {
			return
		}

		// For every Application Service that is responsible for exposing an aggregate an Accessor will be generated.
		for (rel : rr) {
			val upstreamBoundedContext = (rel as UpstreamDownstreamRelationship).upstream
			val allContexts = mappedDataModels.stream().flatMap([dataModel|dataModel.contexts.stream()])
			// Look up the Context that contains the Application Services which expose the aggregates of the relationship
			allContexts.filter [ context |
				context.name.equals(upstreamBoundedContext.name)
			].findFirst().ifPresent() [ upstreamContext |
				// For every exposed aggregate X look up the Application Service in the LEMMA Context that exposes X
				for (exposedAggregate : (rel as UpstreamDownstreamRelationship).upstreamExposedAggregates) {


					// "Api"-Service that must already exist in the DML DataModel
					val appService = upstreamContext.complexTypes.stream.filter [ cType |
						cType.name.equals(exposedAggregate.name + "Api")
					].findFirst()

					// Check if an Accessor is already defined for the Api
					val accessorService = this.targetCtx.complexTypes.stream.filter [ cType |
						cType.name.equals(exposedAggregate.name + "Accessor")
					].findFirst()

					if (appService.isPresent && accessorService.empty) {
						// Create accessor
						val newAccessorService = createAccessor(appService.get as DataStructure)
						targetCtx.complexTypes.add(newAccessorService)

						// Add the exposed aggregate into the downstream domain model (if not existing yet)
						val exposedAggregateInCml = targetCtx.complexTypes.stream.filter [ cType |
							cType.name.equals(exposedAggregate.name)
						].findAny()

						if (exposedAggregateInCml.empty) {
							val cTypes = DomainDataModelFactory.mapAggregateToComplexType(exposedAggregate)
							Util.addComplexTypesIntoContext(targetCtx, cTypes)
						}
					}
				}
			]

		}
	}

	/**
	 * Maps an Application Service that represents the API exposing an Aggregate to another Application Service that
	 * represents an Accessor accessing the API.
	 * If the exposed aggregate is not in the 
	 * 
	 * @param appService DML application service representing the upstream Api
	 * @param exposedAggregate CML aggregate representing the aggregate that is accessed by the Accessor.
	 */
	private def createAccessor(DataStructure appService) {
		val accessor = DATA_FACTORY.createDataStructure
		accessor.name = appService.name.replace("Api", "Accessor")
		accessor.features.add(ComplexTypeFeature.APPLICATION_SERVICE)

		// Add operations
		appService.operations.forEach [ appServiceOp |
			// But only add those operations that have a Dtos as parameters or only primitive types
			// in order to keep the domain model save from the upstream domain model
			val dto = appServiceOp.parameters.filter [ param |
				param.complexType !== null && param.complexType.name.contains("Dto")
			]

			if (dto.size == appServiceOp.parameters.size) {
				accessor.operations.add(EcoreUtil.copy(appServiceOp))
			// In order to use the dto, it must be added to the Context
			} else { // check for only primitives
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
	override filter() {
		return inputMap.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstream.name.equals(targetCtx.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE)
		]).collect(Collectors.toList())
	}
}
