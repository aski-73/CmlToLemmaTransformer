package de.fhdo.lemma.cml_transformer.factory

import de.fhdo.lemma.technology.TechnologyFactory
import de.fhdo.lemma.cml_transformer.technologies.RestTechnology

/**
 * Mapping CML "implementationTechnology" to LEMMA Technology Model
 */
class TechnologyModelFactory {
	static val TECHNOLOGY_FACTORY = TechnologyFactory.eINSTANCE
		
	String technologyModelPath
	
	new (String technologyModelPath) {
		this.technologyModelPath = technologyModelPath
	}

	/**
	 * Maps CML implementationTechnology Keyword to specific LEMMA Technologies
	 */
	def generateTechnologymodel(String implementationTechnology) {
		if (implementationTechnology !== null && implementationTechnology.equals("RESTfulHttp")) {
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
		return new RestTechnology(this.technologyModelPath)
	}
}
