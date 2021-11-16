package de.fhdo.lemma.cml_transformer.code_generators

import org.eclipse.emf.ecore.EObject
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.DataOperation
import de.fhdo.lemma.data.DataOperationParameter
import de.fhdo.lemma.data.DataField
import de.fhdo.lemma.data.EnumerationField
import org.eclipse.emf.common.util.Enumerator

/**
 * This class collects _static_ utility methods for the Data DSL extractor.
 *
 * @author <a href="mailto:florian.rademacher@fh-dortmund.de">Florian Rademacher</a>
 */
final class Util {
    /**
     * Build the qualified name for an EObject that is an instance of a concept from the Data DSL
     */
    static def String qualifiedName(EObject eObject) {
        return switch(eObject) {
            Context: eObject.buildQualifiedName(".")
            ComplexType: eObject.buildQualifiedName(".")
            DataOperation: eObject.buildQualifiedName(".")
            DataOperationParameter: eObject.buildQualifiedName(".")
            DataField: eObject.buildQualifiedName(".")
            EnumerationField: eObject.buildQualifiedName(".")
            default: throw new IllegalArgumentException("Building fully-qualified name for " +
                '''EObjects of type «eObject.class.simpleName» is not supported''')
        }
    }

    /**
     * Calculate the relative qualifier of a full qualifier relative to another full qualifier. For
     * example, the relative qualifier of the full qualifier "org.example.lemma.data.Structure" in
     * the context of another full qualifier "org.example.lemma" is "data.Structure".
     */
    static def String calculateRelativeQualifier(String qualifier, String relativeTo) {
        val qualifierParts = qualifier.split("\\.").toList
        val relativeToParts = relativeTo.split("\\.")
        val minIndex = Math.min(qualifierParts.size, relativeToParts.size)

        var index = 0
        var differenceIndex = -1
        while (index < minIndex && differenceIndex == -1) {
            if (qualifierParts.get(index) != relativeToParts.get(index))
                differenceIndex = index
            index++
        }

        return qualifierParts.joinFromIndex(".", differenceIndex)
    }

    /**
     * Join entries of an Iterable separated by an arbitrary String and starting from a given
     * (inclusive) index
     */
    static def String joinFromIndex(Iterable<?> iterable, String separator, int index) {
        val joinElements = iterable.indexed.filter[it.key >= index].map[it.value]
        return joinElements.join(separator)
    }

    /**
     * List of reserved keywords of the Data DSL
     */
    static val RESERVED_KEYWORDS = #[
        "as",
        "context",
        "datatypes",
        "enum",
        "from",
        "import",
        "list",
        "structure",
        "version"
    ]

    /**
     * Escape Data DSL keyword
     */
    static def String lemmaName(String name) {
        return if (RESERVED_KEYWORDS.contains(name))
                '''^«name»'''
            else
                name
    }
    
	/**
	 * Transform feature names into camelCase.
	 * value_object => valueObject etc.
	 */
	def static transformFeatureToCamelCase(Enumerator enumValue) {
		val s = enumValue.name.toLowerCase
		val newS = new StringBuilder()
		var makeNextCharUpperCase = false
		for (var i = 0; i < s.length; i++) {
			if ((s.charAt(i) as byte) == 95) { // 95 == underscore
				makeNextCharUpperCase = true
			} else {
				if (makeNextCharUpperCase) {
					newS.append(String.valueOf(s.charAt(i)).toUpperCase)
					makeNextCharUpperCase = false
				} else {
					newS.append(s.charAt(i))
				}

			}
		}

		return newS.toString
	}
}