package de.fhdo.lemma.cml_transformer.technologies

import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.service.Microservice
import de.fhdo.lemma.technology.TechnologyFactory
import de.fhdo.lemma.technology.CommunicationType
import de.fhdo.lemma.technology.ServiceAspect
import de.fhdo.lemma.technology.AspectFeature
import de.fhdo.lemma.technology.JoinPointType
import de.fhdo.lemma.service.ServiceFactory
import de.fhdo.lemma.cml_transformer.Util

class RestTechnology extends CustomTechnology {
	static val TECHNOLOGY_FACTORY = TechnologyFactory.eINSTANCE

	static val SERVICE_FACTORY = ServiceFactory.eINSTANCE
	
	/**
	 * Default Service Aspects
	 */
	var ServiceAspect postAspect
	var ServiceAspect getAspect
	var ServiceAspect putAspect
	var ServiceAspect deleteAspect

	new(String technologyModelPath) {
		super(TECHNOLOGY_FACTORY.createTechnology, technologyModelPath)
		
		this.technology.name = "Rest"

		// Add protocol
		val restProtocol = TECHNOLOGY_FACTORY.createProtocol
		restProtocol.name = "rest"
		restProtocol.communicationType = CommunicationType.SYNCHRONOUS
		val dataFormat = TECHNOLOGY_FACTORY.createDataFormat
		dataFormat.formatName = "application/json"
		restProtocol.dataFormats.add(dataFormat)

		this.technology.protocols.add(restProtocol)

		// Add default service aspects
		createDefaultServiceAspects()
		this.technology.serviceAspects.addAll(#[postAspect, getAspect, putAspect, deleteAspect])
	}

	override ServiceAspect mapMethodNamesToServiceAspect(String methodName) {
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

	def createDefaultServiceAspects() {
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

}
