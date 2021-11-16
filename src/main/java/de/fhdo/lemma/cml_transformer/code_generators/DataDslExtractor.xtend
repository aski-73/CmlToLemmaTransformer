package de.fhdo.lemma.cml_transformer.code_generators

import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.ComplexTypeImport
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.data.DataField
import de.fhdo.lemma.data.PrimitiveType
import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.ImportedComplexType
import de.fhdo.lemma.data.Type
import java.util.List
import java.util.function.Function

import static de.fhdo.lemma.cml_transformer.code_generators.Util.*
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.Enumeration
import de.fhdo.lemma.data.EnumerationField
import de.fhdo.lemma.data.ListType
import de.fhdo.lemma.data.Version
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.common.util.Enumerator
import de.fhdo.lemma.data.DataOperation
import de.fhdo.lemma.data.DataOperationParameter

/**
 * Model-to-text extractor for the Data DSL.
 * 
 * @author <a href="mailto:florian.rademacher@fh-dortmund.de">Florian Rademacher</a>
 */
class DataDslExtractor {
	/**
	 * Extract DataModel
	 */
	def String extractToString(DataModel dataModel) {
		val sb = new StringBuilder()
		sb.appendAsSeparatedLines(dataModel.complexTypeImports, [it.extractToString], false)
		sb.appendAsSeparatedLines(dataModel.versions, [it.extractToString], true)
		sb.appendAsSeparatedLines(dataModel.contexts, [it.extractToString], true)
		sb.appendAsSeparatedLines(dataModel.complexTypes, [it.extractTypeDefinitionToString], true)
		return sb.toString
	}

	/**
	 * Helper to append a list of lines to a StringBuilder and separate them from already existing
	 * lines in that StringBuilder by an empty line. If separateConvertedStrings is set to true,
	 * even the given lines are separated by an empty line.
	 */
	private def <T> void appendAsSeparatedLines(StringBuilder sb, List<T> lines, Function<T, String> stringConverter,
		boolean separateConvertedStrings) {
		if (lines.empty) {
			return
		}

		if (sb.length > 0 && !sb.toString.endsWith("\n\n")) {
			if (sb.toString.endsWith("\n"))
				sb.append("\n")
			else
				sb.append("\n\n")
		}

		val stringSeparator = if(separateConvertedStrings) "\n\n" else "\n"
		val stringLines = lines.map[stringConverter.apply(it)].join(stringSeparator)
		sb.append(stringLines)
	}

	/**
	 * Extract ComplexTypeImport
	 */
	def String extractToString(ComplexTypeImport complexTypeImport) {
		val lemmaName = lemmaName(complexTypeImport.name)
		'''import datatypes from «complexTypeImport.importURI» as «lemmaName»'''
	}

	/**
	 * Extract ComplexType
	 */
	def String extractTypeDefinitionToString(ComplexType complexType) {
		return switch (complexType) {
			DataStructure: complexType.extractToString
			Enumeration: complexType.extractToString
			ListType: complexType.extractToString
		}
	}

	/**
	 * Extract DataStructure
	 */
	def String extractToString(DataStructure dataStructure) {
		val preamble = '''structure «lemmaName(dataStructure.name)»'''
		if (dataStructure.dataFields.empty && dataStructure.operations.empty)
			return '''«preamble» {}'''

		// Set a separator between fields and operations if both exist 
		var setFieldOperationSeparator = dataStructure.operations.size > 0 && dataStructure.dataFields.size > 0

		'''
		«preamble» {
			«FOR f : dataStructure.dataFields SEPARATOR ','»
				«f.extractToString»
			«ENDFOR»
			«IF setFieldOperationSeparator»,«ENDIF»
			«FOR op : dataStructure.operations SEPARATOR ","»
				«op.extractToString»
			«ENDFOR»
		}
		'''
	}

	/**
	 * Extract DataField
	 */
	def String extractToString(DataField dataField) {
		val directFieldType = dataField.fieldType
		val type = switch (directFieldType) {
			Type: directFieldType.extractTypeReferenceToString(qualifiedName(dataField))
			ImportedComplexType: directFieldType.extractTypeReferenceToString
		}
		'''«type» «lemmaName(dataField.name)»«dataField.features.extractFeatures»'''
	}

	/**
	 * Get the type of a DataField
	 */
	private def Object fieldType(DataField dataField) {
		return if (dataField.primitiveType !== null)
			dataField.primitiveType
		else if (dataField.complexType !== null)
			dataField.complexType
		else
			dataField.importedComplexType
	}

	/**
	 * Extract DataOperation
	 */
	def String extractToString(DataOperation dataOperation) {
		val operationReturnType = dataOperation.operationReturnType
		val type = switch (operationReturnType) {
			Type: operationReturnType.extractTypeReferenceToString(qualifiedName(dataOperation))
			ImportedComplexType: operationReturnType.extractTypeReferenceToString
			default: ""
		}
		val operationKind = dataOperation.hasNoReturnType ? "procedure" : '''function «type»'''

		if (dataOperation.parameters.empty)
			return '''«operationKind» «lemmaName(dataOperation.name)»«dataOperation.features.extractFeatures»()'''
		else
			return '''
			    	«operationKind» «lemmaName(dataOperation.name)»«dataOperation.features.extractFeatures»(«FOR param : dataOperation.parameters SEPARATOR ", "»«param.extractToString»«ENDFOR»)
			'''
	}

	/**
	 * Get the return type of a DataOperation
	 */
	private def Object operationReturnType(DataOperation dataOperation) {
		return if (dataOperation.complexReturnType !== null)
			dataOperation.complexReturnType
		else if (dataOperation.primitiveReturnType !== null)
			dataOperation.primitiveReturnType
		else if (dataOperation.importedComplexReturnType !== null)
			dataOperation.importedComplexReturnType
		else
			null
	}

	/**
	 * Extract DataOperationParameter
	 */
	def String extractToString(DataOperationParameter param) {
		val directFieldType = param.paramType
		val type = switch (directFieldType) {
			Type: directFieldType.extractTypeReferenceToString(qualifiedName(param))
			ImportedComplexType: directFieldType.extractTypeReferenceToString
		}
		'''«type» «lemmaName(param.name)»'''
	}

	/**
	 * Get the type of a DataOperationParameter
	 */
	private def Object paramType(DataOperationParameter param) {
		return if (param.complexType !== null)
			param.complexType
		else if (param.primitiveType !== null)
			param.primitiveType
		else
			param.importedComplexType
	}

	/**
	 * Extract Type reference
	 */
	def String extractTypeReferenceToString(Type type, String referringQualifier) {
		return switch (type) {
			PrimitiveType: type.extractTypeReferenceToString
			ComplexType: type.extractTypeReferenceToString(referringQualifier)
		}
	}

	/**
	 * Extract PrimitiveType reference
	 */
	def String extractTypeReferenceToString(PrimitiveType primitiveType) {
		primitiveType.typeName
	}

	/**
	 * Extract ComplexType reference
	 */
	def String extractTypeReferenceToString(ComplexType complexType, String referringQualifier) {
		return if (referringQualifier !== null)
			calculateRelativeQualifier(qualifiedName(complexType), referringQualifier)
		else
			lemmaName(complexType.name)
	}

	/**
	 * Extract ImportedComplexType reference
	 */
	def String extractTypeReferenceToString(ImportedComplexType importedComplexType) {
		val complexType = importedComplexType.importedType as ComplexType
		'''«lemmaName(importedComplexType.import.name)»::«qualifiedName(complexType)»'''
	}

	/**
	 * Extract Enumeration
	 */
	def String extractToString(Enumeration enumeration) {
		val preamble = '''enum «lemmaName(enumeration.name)»'''
		if (enumeration.fields.empty)
			return '''«preamble» {}'''

		'''
		«preamble» {
		    «FOR f : enumeration.fields SEPARATOR ','»
		    	«f.extractToString»
		    «ENDFOR»
		}'''
	}

	/**
	 * Extract EnumerationField
	 */
	private def String extractToString(EnumerationField field) {
		lemmaName(field.name)
	}

	/**
	 * Extract ListType
	 */
	def String extractToString(ListType listType) {
		val preamble = '''list «lemmaName(listType.name)»'''

		// Extract primitive list
		if (listType.isPrimitiveList)
			'''«preamble» { «listType.primitiveType.extractTypeReferenceToString» }'''
		// Extract structured list
		else if (listType.isStructuredList) {
			val fieldDefinitions = listType.dataFields.map [
				val fieldTypeReference = effectiveType.extractTypeReferenceToString(
					qualifiedName(listType)
				)
				'''«fieldTypeReference» «lemmaName(name)»'''
			].join(", ")

			'''«preamble» { «fieldDefinitions» }'''
		} // Empty list
		else
			'''«preamble» {}'''
	}

	/**
	 * Extract Context
	 */
	def String extractToString(Context context) {
		val preamble = '''context «lemmaName(context.name)»'''
		if (context.complexTypes.empty)
			return '''«preamble» {}'''

		'''
		«preamble» {
		    «FOR t : context.complexTypes SEPARATOR '\n'»
		    	«t.extractTypeDefinitionToString»
		    «ENDFOR»
		}'''
	}

	/**
	 * Extract Version
	 */
	def String extractToString(Version version) {
		val preamble = '''version «lemmaName(version.name)»'''
		if (version.contexts.empty && version.complexTypes.empty)
			return '''«preamble» {}'''

		'''
		«preamble» {
		    «FOR c : version.contexts SEPARATOR '\n'»
		    	«c.extractToString»
		    «ENDFOR»
		    «FOR t : version.complexTypes SEPARATOR '\n'»
		    	«t.extractTypeDefinitionToString»
		    «ENDFOR»
		}'''
	}

	/**
	 * Extract Features {@link ComplexTypeFeature}, {@link DataOperationFeature} and {@link DataFieldFeature}
	 */
	def private static extractFeatures(EList<? extends Enumerator> features) {
		return features.size > 0
			? ''' <«FOR feat : features SEPARATOR ", "»«Util.transformFeatureToCamelCase(feat)»«ENDFOR»>''' : "";
	}

}
