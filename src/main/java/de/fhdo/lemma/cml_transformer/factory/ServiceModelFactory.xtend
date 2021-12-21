package de.fhdo.lemma.cml_transformer.factory

import de.fhdo.lemma.service.ServiceFactory
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
import de.fhdo.lemma.service.ServiceModel
import org.contextmapper.dsl.contextMappingDSL.BoundedContextType
import de.fhdo.lemma.service.MicroserviceType
import de.fhdo.lemma.service.Visibility
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import de.fhdo.lemma.data.Context
import java.util.List
import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceUpstreamGenerator

/**
 * Creates for every {@link Context} defined in LEMMA {@link DataModel} a Microservice will be generated. 
 * This factory assumes that a model transformation from CML to LEMMA DML has already been made.
 * 
 * 
 * Depending on the relations in the {@link ContextMap} further steps will be made.
 */
class ServiceModelFactory {
	static val SERVICE_FACTORY = ServiceFactory.eINSTANCE

	/**
	 * Mapping from CML bounded context types to LEMMA service types
	 */
	def static mapBoundedContextTypeToServiceType(BoundedContextType type) {
		return switch (type) {
			case BoundedContextType.APPLICATION: MicroserviceType.FUNCTIONAL
			case BoundedContextType.TEAM: null
			case BoundedContextType.FEATURE: MicroserviceType.FUNCTIONAL
			case BoundedContextType.SYSTEM: MicroserviceType.INFRASTRUCTURE
			default: MicroserviceType.FUNCTIONAL
		}
	}

	/**
	 * Maps CML {@link BoundedContextType} to LEMMA SML {@link Visibility}.
	 * Since CML does not have the same concept only assumptions can be made.
	 */
	def static mapBoundedContextTypeToServiceVisibility(BoundedContextType type) {
		return switch (type) {
			case BoundedContextType.APPLICATION: Visibility.PUBLIC
			case BoundedContextType.TEAM: Visibility.INTERNAL
			case BoundedContextType.FEATURE: Visibility.PUBLIC
			case BoundedContextType.SYSTEM: Visibility.ARCHITECTURE
			default: Visibility.PUBLIC
		}
	}

	/**
	 * Input Model (CML)
	 */
	ContextMappingModel inputCml

	/**
	 * Input Model
	 */
	Context inputCtx


	new(ContextMappingModel cmlModel, Context context) {
		this.inputCml = cmlModel
		this.inputCtx = context
	}

	/**
	 * Instantiates a Service Model for a {@link BoundedContext}/{@link Context} provided
	 * in the ctor.
	 * 
	 * @param dataModelPath 	  Path containing all created Data Models (.data files)
	 * @param serviceModelPath	  Path containing all created Service Models (.services files)
	 * @param technologyModelPath Path containing all created Technology Models (.technology files)
	 */
	def ServiceModel generateServiceModel(String dataModelPath, String serviceModelPath, String technologyModelPath) {
		val serviceModel = SERVICE_FACTORY.createServiceModel

		val boundedContext = this.inputCml.boundedContexts.stream.filter [ bc |
			bc.name.equals(this.inputCtx.name)
		].findAny()

		if (boundedContext.isPresent) {
			// create Microservice
			val microservice = SERVICE_FACTORY.createMicroservice
			microservice.name = "org.my_organization." + this.inputCtx.name
			microservice.qualifiedNameParts.addAll(#["org", "my_organization"]) // TODO wird das vom Extractor genutzt ? denke nicht
			microservice.visibility = mapBoundedContextTypeToServiceVisibility(boundedContext.get.type)
			microservice.type = mapBoundedContextTypeToServiceType(boundedContext.get.type)

			serviceModel.microservices.add(microservice)
		}

		return serviceModel
	}
}
