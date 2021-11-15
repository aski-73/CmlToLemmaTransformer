package de.fhdo.lemma.cml_transformer.code_generators

import de.fhdo.lemma.data.DataField
import org.eclipse.emf.common.util.Enumerator
import org.eclipse.emf.common.util.EList
import de.fhdo.lemma.data.ListType
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataOperationParameter
import de.fhdo.lemma.data.DataOperation

class DomainDataModelCodeGenerator {

	def static String printDataModel(DataModel model) {
		val code = new StringBuilder()

		model.contexts.forEach[ctx|code.append(printDataModelContext(ctx))]

		return code.toString
	}

	def private static String printDataModelContext(Context context) {
		val text = '''
			context «context.name» {	
				«FOR complexType : context.complexTypes»
					«printDataModelComplexType(complexType)»
				«ENDFOR»
			}
		'''

		return text;
	}

	/**
	 * Generates LEMMA DML {@link DataStructure} (Value Objects, Entities etc.)
	 */
	def private static dispatch String printDataModelComplexType(DataStructure structure) {
		// Set a separator between fields and operations if both exist 
		var setFieldOperationSeparator = structure.operations.size > 0 && structure.dataFields.size > 0

		return '''
			««« First generate the fields / attributes
			««« Iteration over effectiveFileds not working ?
			««« Then generate the operations

			structure «structure.name» «printFeatures(structure.features)» {
				«FOR field : structure.dataFields SEPARATOR ","»
					«field.determineConcreteType» «field.name» «printFeatures(field.features)»
				«ENDFOR»
				«IF setFieldOperationSeparator»,«ENDIF»
				«FOR op : structure.operations SEPARATOR ","»
					«IF op.hasNoReturnType»procedure«ELSE»function «op.determineConcreteType»«ENDIF» «op.name» (
						«FOR param: op.parameters SEPARATOR ","»
							«param.determineConcreteType» «param.name»
						«ENDFOR»
					)
				«ENDFOR»
			}
		'''
	}

	/**
	 * Generates LEMMA DML {@link ListType} (Lists)
	 */
	def private static dispatch String printDataModelComplexType(ListType listType) {
		return '''
			list «listType.name» { «FOR field: listType.dataFields SEPARATOR ","» «field.determineConcreteType» «field.name» «ENDFOR» }
		'''
	}

	/**
	 * Generates LEMMA DML {@link Enumeration} (Enums)
	 */
	def private static dispatch String printDataModelComplexType(de.fhdo.lemma.data.Enumeration enumeration) {
		return '''
			enum «enumeration.name» {
				«FOR enumField : enumeration.fields SEPARATOR ","»
					«enumField.name»«IF enumField.initializationValue != null»(«enumField.initializationValue»)«ENDIF»
				«ENDFOR»
			}
		'''
	}

	/**
	 * Returns LEMMA DML Features {@link ComplexTypeFeature}, {@link DataOperationFeature} and {@link DataFieldFeature}
	 */
	def private static printFeatures(EList<? extends Enumerator> features) {
		return features.size > 0
			? '''<«FOR feat : features SEPARATOR ", "»«feat.transformFeatureToCamelCase»«ENDFOR»>''' : "";
	}

	/**
	 * Since {@link Type} has no general method to tell its concrete type we need helper methods.
	 * This one is for {@link DataField}
	 */
	def private static determineConcreteType(DataField field) {
		return field.complexType != null ? field.complexType.name : (field.primitiveType != null ? field.primitiveType.
			typeName : "notDetermined")
	}

	/**
	 * Since {@link Type} has no general method to tell its concrete type we need helper methods.
	 * This one is for the return value of {@link DataOperation}
	 */
	def private static determineConcreteType(DataOperation op) {
		return op.complexReturnType != null
			? op.complexReturnType.name : (op.primitiveReturnType != null ? op.primitiveReturnType.
			typeName : "notDetermined")
	}

	/**
	 * Since {@link Type} has no general method to tell its concrete type we need helper methods.
	 * This one is for {@link DataOperationParameter}
	 */
	def private static determineConcreteType(DataOperationParameter param) {
		return param.complexType != null ? param.complexType.name : (param.primitiveType != null ? param.primitiveType.
			typeName : "notDetermined")
	}

	/**
	 * value_object => valueObject etc.
	 */
	def private static transformFeatureToCamelCase(Enumerator enumValue) {
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
