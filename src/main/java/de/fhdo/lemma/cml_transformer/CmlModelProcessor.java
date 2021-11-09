package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.model_processing.AbstractModelProcessor;

/**
 * Entrypoint of the CML Transformer
 */
public class CmlModelProcessor extends AbstractModelProcessor {
	
	/**
     * Program entrypoint
     */
    public static void main(String[] args) {
        new CmlModelProcessor().run(args);
    }

	public CmlModelProcessor() {
		// Package which contains the annotated classes
		super("de.fhdo.lemma.cml_transformer");
	}

}
