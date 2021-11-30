package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.model_processing.AbstractModelProcessor;

/**
 * Entrypoint of the CML Transformer
 */
@SuppressWarnings("all")
public class CmlModelProcessor extends AbstractModelProcessor {
  /**
   * Program entrypoint
   */
  public static void main(final String[] args) {
    new CmlModelProcessor().run(args);
  }
  
  public CmlModelProcessor() {
    super("de.fhdo.lemma.cml_transformer");
  }
}
