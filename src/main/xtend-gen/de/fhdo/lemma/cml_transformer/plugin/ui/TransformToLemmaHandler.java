package de.fhdo.lemma.cml_transformer.plugin.ui;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;

@SuppressWarnings("all")
public class TransformToLemmaHandler extends AbstractHandler {
  @Override
  public Object execute(final ExecutionEvent event) throws ExecutionException {
    System.out.println("Hallo Plugin");
    return null;
  }
}
