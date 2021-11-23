package de.fhdo.lemma.cml_transformer.factory

import de.fhdo.lemma.service.ServiceFactory
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
import de.fhdo.lemma.service.ServiceModel
import org.contextmapper.dsl.contextMappingDSL.BoundedContextType
import de.fhdo.lemma.service.MicroserviceType
import de.fhdo.lemma.service.Visibility
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceServiceModelGenerator

/**
 * Creates for every {@link Context} defined in LEMMA {@link DataModel} a Microservice will be generated. 
 * This factory assumes that a model transformation from CML to LEMMA DML has already been made.
 * 
 * 
 * Depending on the relations in the {@link ContextMap} further steps will be made.
 */
class LemmaServiceModelFactory {
	static val SERVICE_FACTORY = ServiceFactory.eINSTANCE

	/**
	 * Mapping from CML bounded context types to LEMMA service types
	 */
	def static mapBoundedContextTypeToServiceType(BoundedContextType type) {
		return switch (type) {
			case BoundedContextType.APPLICATION: MicroserviceType.FUNCTIONAL
			case BoundedContextType.TEAM: MicroserviceType.FUNCTIONAL
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
	private ContextMappingModel cmlModel

	/**
	 * Input Model
	 */
	private Context context

	/** 
	 * Output Model (SML)
	 */
	private ServiceModel serviceModel

	new(ContextMappingModel cmlModel, Context context) {
		this.cmlModel = cmlModel
		this.context = context
	}

	def ServiceModel buildServiceModel() {
		this.serviceModel = SERVICE_FACTORY.createServiceModel

		val boundedContext = this.cmlModel.boundedContexts.stream.filter [ bc |
			bc.name.equals(this.context.name)
		].findAny()

		if (boundedContext.isPresent) {
			// create Microservice
			val microservice = SERVICE_FACTORY.createMicroservice
			microservice.name = "org.my_organization." + this.context.name
			microservice.qualifiedNameParts.addAll(#["org", "my_organization"]) // TODO wird das vom Extractor genutzt ? denke nicht
			microservice.visibility = mapBoundedContextTypeToServiceVisibility(boundedContext.get.type)
			microservice.type = mapBoundedContextTypeToServiceType(boundedContext.get.type)

			// use OHS Upstream Generator to fill the microservice
			val ohsUpstreamGenerator = new OpenHostServiceServiceModelGenerator(this.context, this.serviceModel, microservice,
				cmlModel.map, "../domain", "../service")
			ohsUpstreamGenerator.mapOhsUpstream()

			this.serviceModel.microservices.add(microservice)
		}

		return this.serviceModel
	}
}
