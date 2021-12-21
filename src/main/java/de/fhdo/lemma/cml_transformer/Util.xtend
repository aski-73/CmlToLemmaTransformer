package de.fhdo.lemma.cml_transformer

import java.util.List
import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.service.Import
import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.ComplexType
import org.eclipse.emf.ecore.util.EcoreUtil

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

	static def addComplexTypesIntoContext(Context targetCtx, List<ComplexType> cTypes) {
		// Only add complex types which are not already existing. A (domain object or) list type of the upstream might already
		// exist in the target context because in CML it's possible to reference domain objects (which can contain list types) from other bounded contexts
		// and the DomainDataModelFactory would already create it in the target context. But this behavior is not wanted because one 
		// bounded context (microservice) is assigned to one team. Every team must take care of their own (domain objects and) list types.
		// It's also possible to reference external (domain objects and) list types in LEMMA but it should not be done of the same reason.
		for (ComplexType cType : cTypes) {
			val checkComplexType = targetCtx.complexTypes.stream.filter([ checkMe |
				checkMe.name.equals(cType.name)
			]).findAny
			if (!checkComplexType.present) {
				targetCtx.complexTypes.add(EcoreUtil.copy(cType))
			}
		}
	}
}
