package de.fhdo.lemma.cml_transformer.technologies;

import de.fhdo.lemma.service.ServiceFactory;
import de.fhdo.lemma.technology.AspectFeature;
import de.fhdo.lemma.technology.CommunicationType;
import de.fhdo.lemma.technology.DataFormat;
import de.fhdo.lemma.technology.JoinPointType;
import de.fhdo.lemma.technology.Protocol;
import de.fhdo.lemma.technology.ServiceAspect;
import de.fhdo.lemma.technology.TechnologyFactory;
import java.util.Collections;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

@SuppressWarnings("all")
public class RestTechnology extends CustomTechnology {
  private static final TechnologyFactory TECHNOLOGY_FACTORY = TechnologyFactory.eINSTANCE;
  
  private static final ServiceFactory SERVICE_FACTORY = ServiceFactory.eINSTANCE;
  
  /**
   * Default Service Aspects
   */
  private ServiceAspect postAspect;
  
  private ServiceAspect getAspect;
  
  private ServiceAspect putAspect;
  
  private ServiceAspect deleteAspect;
  
  public RestTechnology(final String technologyModelPath) {
    super(RestTechnology.TECHNOLOGY_FACTORY.createTechnology(), technologyModelPath);
    this.technology.setName("Rest");
    final Protocol restProtocol = RestTechnology.TECHNOLOGY_FACTORY.createProtocol();
    restProtocol.setName("rest");
    restProtocol.setCommunicationType(CommunicationType.SYNCHRONOUS);
    final DataFormat dataFormat = RestTechnology.TECHNOLOGY_FACTORY.createDataFormat();
    dataFormat.setFormatName("application/json");
    restProtocol.getDataFormats().add(dataFormat);
    this.technology.getProtocols().add(restProtocol);
    this.createDefaultServiceAspects();
    this.technology.getServiceAspects().addAll(Collections.<ServiceAspect>unmodifiableList(CollectionLiterals.<ServiceAspect>newArrayList(this.postAspect, this.getAspect, this.putAspect, this.deleteAspect)));
  }
  
  @Override
  public ServiceAspect mapMethodNamesToServiceAspect(final String methodName) {
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
  
  public boolean createDefaultServiceAspects() {
    boolean _xblockexpression = false;
    {
      this.postAspect = RestTechnology.TECHNOLOGY_FACTORY.createServiceAspect();
      this.postAspect.setName("POST");
      this.postAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
      this.postAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
      this.getAspect = RestTechnology.TECHNOLOGY_FACTORY.createServiceAspect();
      this.getAspect.setName("GET");
      this.getAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
      this.getAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
      this.putAspect = RestTechnology.TECHNOLOGY_FACTORY.createServiceAspect();
      this.putAspect.setName("PUT");
      this.putAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
      this.putAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
      this.deleteAspect = RestTechnology.TECHNOLOGY_FACTORY.createServiceAspect();
      this.deleteAspect.setName("DELETE");
      this.deleteAspect.getFeatures().add(AspectFeature.SINGLE_VALUED);
      _xblockexpression = this.deleteAspect.getJoinPoints().add(JoinPointType.OPERATIONS);
    }
    return _xblockexpression;
  }
}
