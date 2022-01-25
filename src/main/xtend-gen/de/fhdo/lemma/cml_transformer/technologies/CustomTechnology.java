package de.fhdo.lemma.cml_transformer.technologies;

import de.fhdo.lemma.technology.ServiceAspect;
import de.fhdo.lemma.technology.Technology;
import org.eclipse.xtend.lib.annotations.AccessorType;
import org.eclipse.xtend.lib.annotations.Accessors;
import org.eclipse.xtext.xbase.lib.Pure;

@SuppressWarnings("all")
public abstract class CustomTechnology {
  /**
   * Internal {@link Technology}. The custom technology decorates it.
   */
  @Accessors(AccessorType.PUBLIC_GETTER)
  protected Technology technology;
  
  @Accessors(AccessorType.PUBLIC_GETTER)
  protected String technologyModelPath;
  
  public CustomTechnology(final Technology technology, final String technologyModelPath) {
    this.technology = technology;
    this.technologyModelPath = technologyModelPath;
  }
  
  /**
   * Since CML does not have service aspects this method tries to determine a default service aspect
   * by the provided name. Currently it only works with the RestTechnology since
   * it uses the default aspects.
   */
  public abstract ServiceAspect mapMethodNamesToServiceAspect(final String methodName);
  
  @Pure
  public Technology getTechnology() {
    return this.technology;
  }
  
  @Pure
  public String getTechnologyModelPath() {
    return this.technologyModelPath;
  }
}
