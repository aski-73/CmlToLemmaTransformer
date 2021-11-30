package de.fhdo.lemma.cml_transformer

import de.fhdo.lemma.model_processing.AbstractModelProcessor

/** 
 * Entrypoint of the CML Transformer
 */
class CmlModelProcessor extends AbstractModelProcessor {
	/** 
	 * Program entrypoint
	 */
	def static void main(String[] args) {
		new CmlModelProcessor().run(args)
	}

	new() {
		// Package which contains the annotated classes
		super("de.fhdo.lemma.cml_transformer")
	}
}
