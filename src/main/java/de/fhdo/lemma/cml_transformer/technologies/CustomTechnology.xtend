package de.fhdo.lemma.cml_transformer.technologies

import de.fhdo.lemma.service.Microservice
import de.fhdo.lemma.technology.Technology
import org.eclipse.xtend.lib.annotations.Accessors
import de.fhdo.lemma.technology.ServiceAspect

abstract class CustomTechnology {
	/**
	 * Internal {@link Technology}. The custom technology decorates it.
	 */
	@Accessors(PUBLIC_GETTER) protected Technology technology
	@Accessors(PUBLIC_GETTER) protected String technologyModelPath

	new(Technology technology, String technologyModelPath) {
		this.technology = technology
		this.technologyModelPath = technologyModelPath
	}

	/**
	 * Since CML does not have service aspects this method tries to determine a default service aspect
	 * by the provided name. Currently it only works with the RestTechnology since
	 * it uses the default aspects.
	 */
	def abstract ServiceAspect mapMethodNamesToServiceAspect(String methodName)
}
