package de.fhdo.lemma.cml_transformer.factory;

import de.fhdo.lemma.technology.AspectFeature;
import de.fhdo.lemma.technology.CommunicationType;
import de.fhdo.lemma.technology.DataFormat;
import de.fhdo.lemma.technology.JoinPointType;
import de.fhdo.lemma.technology.Protocol;
import de.fhdo.lemma.technology.ServiceAspect;
import de.fhdo.lemma.technology.Technology;
import de.fhdo.lemma.technology.TechnologyFactory;
import java.util.Collections;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

/**
 * Mapping CML "implementationTechnology" to LEMMA Technology Model
 */
@SuppressWarnings("all")
public class LemmaTechnologyModelFactory {
  private static final TechnologyFactory TECHNOLOGY_FACTORY = TechnologyFactory.eINSTANCE;
  
  /**
   * Default Service Aspects
   */
  private final ServiceAspect postAspect;
  
  private final ServiceAspect getAspect;
  
  private final ServiceAspect putAspect;
  
  private final ServiceAspect deleteAspect;
  
  public LemmaTechnologyModelFactory() {
    this.postAspect = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createServiceAspect();
    this.postAspect.setName("POST");
    this.postAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
    this.postAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
    this.getAspect = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createServiceAspect();
    this.getAspect.setName("GET");
    this.getAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
    this.getAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
    this.putAspect = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createServiceAspect();
    this.putAspect.setName("PUT");
    this.putAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
    this.putAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
    this.deleteAspect = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createServiceAspect();
    this.deleteAspect.setName("DELETE");
    this.deleteAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
    this.deleteAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
  }
  
  /**
   * Since CML does not have service aspects this method tries to determine a default service aspect
   * by the provided name. Currently it only works with the RestTechnology since
   * it uses the default aspects.
   */
  public ServiceAspect mapMethodNamesToServiceAspectNames(final String methodName) {
    ServiceAspect _xifexpression = null;
    boolean _startsWith = methodName.startsWith("create");
    if (_startsWith) {
      _xifexpression = this.postAspect;
    } else {
      ServiceAspect _xifexpression_1 = null;
      boolean _startsWith_1 = methodName.startsWith("read");
      if (_startsWith_1) {
        _xifexpression_1 = this.getAspect;
      } else {
        ServiceAspect _xifexpression_2 = null;
        boolean _startsWith_2 = methodName.startsWith("update");
        if (_startsWith_2) {
          _xifexpression_2 = this.putAspect;
        } else {
          _xifexpression_2 = this.deleteAspect;
        }
        _xifexpression_1 = _xifexpression_2;
      }
      _xifexpression = _xifexpression_1;
    }
    return _xifexpression;
  }
  
  /**
   * Maps CML implementationTechnology Keyword to specific LEMMA Technologies
   */
  public Technology mapImplementationTechnologyToTechnologymodel(final String implementationTechnology) {
    boolean _equals = implementationTechnology.equals("RESTfulHttp");
    if (_equals) {
      return this.createRestTechnology();
    } else {
      return null;
    }
  }
  
  /**
   * Creates a REST Technology with a rest "protocol". Note: REST is actually not
   * a protocol. Its an architecture style. But for simplicity its treated as a protocol.
   */
  private Technology createRestTechnology() {
    final Technology restTech = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createTechnology();
    restTech.setName("Rest");
    final Protocol restProtocol = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createProtocol();
    restProtocol.setName("rest");
    restProtocol.setCommunicationType(CommunicationType.SYNCHRONOUS);
    final DataFormat dataFormat = LemmaTechnologyModelFactory.TECHNOLOGY_FACTORY.createDataFormat();
    dataFormat.setFormatName("application/json");
    restProtocol.getDataFormats().add(dataFormat);
    restTech.getProtocols().add(restProtocol);
    restTech.getServiceAspects().addAll(Collections.<ServiceAspect>unmodifiableList(CollectionLiterals.<ServiceAspect>newArrayList(this.postAspect, this.getAspect, this.putAspect, this.deleteAspect)));
    return restTech;
  }
}
