package de.fhdo.lemma.cml_transformer.factory;

import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.service.Microservice;
import de.fhdo.lemma.service.MicroserviceType;
import de.fhdo.lemma.service.ServiceFactory;
import de.fhdo.lemma.service.ServiceModel;
import de.fhdo.lemma.service.Visibility;
import java.util.Collections;
import java.util.Optional;
import java.util.function.Predicate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.BoundedContextType;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

/**
 * Creates for every {@link Context} defined in LEMMA {@link DataModel} a Microservice will be generated.
 * This factory assumes that a model transformation from CML to LEMMA DML has already been made.
 * 
 * 
 * Depending on the relations in the {@link ContextMap} further steps will be made.
 */
@SuppressWarnings("all")
public class ServiceModelFactory {
  private static final ServiceFactory SERVICE_FACTORY = ServiceFactory.eINSTANCE;
  
  /**
   * Mapping from CML bounded context types to LEMMA service types
   */
  public static MicroserviceType mapBoundedContextTypeToServiceType(final BoundedContextType type) {
    MicroserviceType _switchResult = null;
    if (type != null) {
      switch (type) {
        case APPLICATION:
          _switchResult = MicroserviceType.FUNCTIONAL;
          break;
        case TEAM:
          _switchResult = null;
          break;
        case FEATURE:
          _switchResult = MicroserviceType.FUNCTIONAL;
          break;
        case SYSTEM:
          _switchResult = MicroserviceType.INFRASTRUCTURE;
          break;
        default:
          _switchResult = MicroserviceType.FUNCTIONAL;
          break;
      }
    } else {
      _switchResult = MicroserviceType.FUNCTIONAL;
    }
    return _switchResult;
  }
  
  /**
   * Maps CML {@link BoundedContextType} to LEMMA SML {@link Visibility}.
   * Since CML does not have the same concept only assumptions can be made.
   */
  public static Visibility mapBoundedContextTypeToServiceVisibility(final BoundedContextType type) {
    Visibility _switchResult = null;
    if (type != null) {
      switch (type) {
        case APPLICATION:
          _switchResult = Visibility.PUBLIC;
          break;
        case TEAM:
          _switchResult = Visibility.INTERNAL;
          break;
        case FEATURE:
          _switchResult = Visibility.PUBLIC;
          break;
        case SYSTEM:
          _switchResult = Visibility.ARCHITECTURE;
          break;
        default:
          _switchResult = Visibility.PUBLIC;
          break;
      }
    } else {
      _switchResult = Visibility.PUBLIC;
    }
    return _switchResult;
  }
  
  /**
   * Input Model (CML)
   */
  private ContextMappingModel inputCml;
  
  /**
   * Input Model
   */
  private Context inputCtx;
  
  public ServiceModelFactory(final ContextMappingModel cmlModel, final Context context) {
    this.inputCml = cmlModel;
    this.inputCtx = context;
  }
  
  /**
   * Instantiates a Service Model for a {@link BoundedContext}/{@link Context} provided
   * in the ctor.
   * 
   * @param dataModelPath 	  Path containing all created Data Models (.data files)
   * @param serviceModelPath	  Path containing all created Service Models (.services files)
   * @param technologyModelPath Path containing all created Technology Models (.technology files)
   */
  public ServiceModel generateServiceModel(final String dataModelPath, final String serviceModelPath, final String technologyModelPath) {
    final ServiceModel serviceModel = ServiceModelFactory.SERVICE_FACTORY.createServiceModel();
    final Predicate<BoundedContext> _function = (BoundedContext bc) -> {
      return bc.getName().equals(this.inputCtx.getName());
    };
    final Optional<BoundedContext> boundedContext = this.inputCml.getBoundedContexts().stream().filter(_function).findAny();
    boolean _isPresent = boundedContext.isPresent();
    if (_isPresent) {
      final Microservice microservice = ServiceModelFactory.SERVICE_FACTORY.createMicroservice();
      String _name = this.inputCtx.getName();
      String _plus = ("org.my_organization." + _name);
      microservice.setName(_plus);
      microservice.getQualifiedNameParts().addAll(Collections.<String>unmodifiableList(CollectionLiterals.<String>newArrayList("org", "my_organization")));
      microservice.setVisibility(ServiceModelFactory.mapBoundedContextTypeToServiceVisibility(boundedContext.get().getType()));
      microservice.setType(ServiceModelFactory.mapBoundedContextTypeToServiceType(boundedContext.get().getType()));
      serviceModel.getMicroservices().add(microservice);
    }
    return serviceModel;
  }
}
