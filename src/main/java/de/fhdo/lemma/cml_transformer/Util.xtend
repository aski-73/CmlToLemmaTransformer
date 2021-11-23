package de.fhdo.lemma.cml_transformer

import java.util.List
import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.service.Import

class Util {
	static def technologyExists(List<Technology> technologies, Technology technology) {
		for (t : technologies) {
			if (t.name.equals(technology.name)) {
				return true
			}
		}

		return false
	}

	static def importExists(List<Import> imports, Import im) {
		for (Import tempIm : imports) {
			if (tempIm.importType == im.importType && tempIm.importURI.equals(im.importURI)) {
				return true
			}
		}

		return false
	}
}
