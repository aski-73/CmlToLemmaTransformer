package de.fhdo.lemma.cml_transformer.factory;

import de.fhdo.lemma.cml_transformer.technologies.RestTechnology;
import de.fhdo.lemma.technology.TechnologyFactory;

/**
 * Mapping CML "implementationTechnology" to LEMMA Technology Model
 */
@SuppressWarnings("all")
public class TechnologyModelFactory {
  private static final TechnologyFactory TECHNOLOGY_FACTORY = TechnologyFactory.eINSTANCE;
  
  private String technologyModelPath;
  
  public TechnologyModelFactory(final String technologyModelPath) {
    this.technologyModelPath = technologyModelPath;
  }
  
  /**
   * Maps CML implementationTechnology Keyword to specific LEMMA Technologies
   */
  public RestTechnology generateTechnologymodel(final String implementationTechnology) {
    if (((implementationTechnology != null) && implementationTechnology.equals("RESTfulHttp"))) {
      return this.createRestTechnology();
    } else {
      return null;
    }
  }
  
  /**
   * Creates a REST Technology with a rest "protocol". Note: REST is actually not
   * a protocol. Its an architecture style. But for simplicity its treated as a protocol.
   */
  private RestTechnology createRestTechnology() {
    return new RestTechnology(this.technologyModelPath);
  }
}
