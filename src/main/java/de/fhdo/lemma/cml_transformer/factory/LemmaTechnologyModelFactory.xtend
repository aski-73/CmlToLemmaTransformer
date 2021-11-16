package de.fhdo.lemma.cml_transformer.factory

import de.fhdo.lemma.technology.TechnologyFactory
import de.fhdo.lemma.technology.CommunicationType
import de.fhdo.lemma.technology.AspectFeature
import de.fhdo.lemma.technology.JoinPointType
import de.fhdo.lemma.technology.ServiceAspect

/**
 * Mapping CML "implementationTechnology" to LEMMA Technology Model
 */
class LemmaTechnologyModelFactory {
	static val TECHNOLOGY_FACTORY = TechnologyFactory.eINSTANCE
	
	/**
	 * Default Service Aspects
	 */
	val ServiceAspect postAspect
	val ServiceAspect getAspect
	val ServiceAspect putAspect
	val ServiceAspect deleteAspect
	
	new () {
		postAspect = TECHNOLOGY_FACTORY.createServiceAspect
		postAspect.name = "POST"
		postAspect.features.add(AspectFeature.SINGLE_VALUED)
		postAspect.joinPoints.add(JoinPointType.OPERATIONS)
		
		getAspect = TECHNOLOGY_FACTORY.createServiceAspect
		getAspect.name = "GET"
		getAspect.features.add(AspectFeature.SINGLE_VALUED)
		getAspect.joinPoints.add(JoinPointType.OPERATIONS)
		
		putAspect = TECHNOLOGY_FACTORY.createServiceAspect
		putAspect.name = "PUT"
		putAspect.features.add(AspectFeature.SINGLE_VALUED)
		putAspect.joinPoints.add(JoinPointType.OPERATIONS)
		
		deleteAspect = TECHNOLOGY_FACTORY.createServiceAspect
		deleteAspect.name = "DELETE"
		deleteAspect.features.add(AspectFeature.SINGLE_VALUED)
		deleteAspect.joinPoints.add(JoinPointType.OPERATIONS)
	}

	/**
	 * Since CML does not have service aspects this method tries to determine a default service aspect
	 * by the provided name. Currently it only works with the RestTechnology since
	 * it uses the default aspects.
	 */
	def mapMethodNamesToServiceAspectNames(String methodName) {
		return if (methodName.startsWith("create")) {
			postAspect
		} else if(methodName.startsWith("read")) {
			getAspect
		} else if(methodName.startsWith("update")) {
			putAspect
		} else {
			deleteAspect
		}
	}

	/**
	 * Maps CML implementationTechnology Keyword to specific LEMMA Technologies
	 */
	def mapImplementationTechnologyToTechnologymodel(String implementationTechnology) {
		if (implementationTechnology.equals("RESTfulHttp")) {
			return createRestTechnology()
		} else {
			return null
		}
	}

	/**
	 * Creates a REST Technology with a rest "protocol". Note: REST is actually not
	 * a protocol. Its an architecture style. But for simplicity its treated as a protocol.
	 */
	private def createRestTechnology() {
		val restTech = TECHNOLOGY_FACTORY.createTechnology
		restTech.name = "Rest"
		
		// Add protocol
		val restProtocol = TECHNOLOGY_FACTORY.createProtocol
		restProtocol.name = "rest"
		restProtocol.communicationType = CommunicationType.SYNCHRONOUS
		val dataFormat = TECHNOLOGY_FACTORY.createDataFormat
		dataFormat.formatName = "application/json"
		restProtocol.dataFormats.add(dataFormat)
		
		restTech.protocols.add(restProtocol)
		
		// add default service aspects
		restTech.serviceAspects.addAll(#[postAspect, getAspect, putAspect, deleteAspect])
		
		return restTech
	}
}
