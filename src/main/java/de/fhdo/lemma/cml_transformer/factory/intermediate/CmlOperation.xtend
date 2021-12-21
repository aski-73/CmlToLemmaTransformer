package de.fhdo.lemma.cml_transformer.factory.intermediate

import org.contextmapper.tactic.dsl.tacticdsl.Parameter
import org.eclipse.emf.common.util.EList
import org.contextmapper.tactic.dsl.tacticdsl.ComplexType

@org.eclipse.xtend.lib.annotations.Data class CmlOperation {
	String name
	ComplexType returnType
	EList<Parameter> parameters
}