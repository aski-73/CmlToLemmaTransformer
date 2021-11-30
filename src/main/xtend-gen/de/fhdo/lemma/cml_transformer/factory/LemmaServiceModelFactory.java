package de.fhdo.lemma.cml_transformer.factory;

import de.fhdo.lemma.cml_transformer.factory.context_map.OpenHostServiceUpstreamGenerator;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.service.Microservice;
import de.fhdo.lemma.service.MicroserviceType;
import de.fhdo.lemma.service.ServiceFactory;
import de.fhdo.lemma.service.ServiceModel;
import de.fhdo.lemma.service.Visibility;
import de.fhdo.lemma.technology.Technology;
import java.util.Collections;
import java.util.List;
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
public class LemmaServiceModelFactory {
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
          _switchResult = MicroserviceType.FUNCTIONAL;
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
  private ContextMappingModel cmlModel;
  
  /**
   * Input Model
   */
  private Context context;
  
  /**
   * Output Model (SML)
   */
  private ServiceModel serviceModel;
  
  /**
   * Created {@link Technology}s will be put in here
   */
  private List<Technology> technologies;
  
  public LemmaServiceModelFactory(final ContextMappingModel cmlModel, final Context context, final List<Technology> technologies) {
    this.cmlModel = cmlModel;
    this.context = context;
    this.technologies = technologies;
  }
  
  /**
   * Instantiates a Service Model for a {@link BoundedContext}/{@link Context} provided
   * in the ctor.
   * 
   * @param dataModelPath 	  Path containing all created Data Models (.data files)
   * @param serviceModelPath	  Path containing all created Service Models (.services files)
   * @param technologyModelPath Path containing all created Technology Models (.technology files)
   */
  public ServiceModel buildServiceModel(final String dataModelPath, final String serviceModelPath, final String technologyModelPath) {
    this.serviceModel = LemmaServiceModelFactory.SERVICE_FACTORY.createServiceModel();
    final Predicate<BoundedContext> _function = (BoundedContext bc) -> {
      return bc.getName().equals(this.context.getName());
    };
    final Optional<BoundedContext> boundedContext = this.cmlModel.getBoundedContexts().stream().filter(_function).findAny();
    boolean _isPresent = boundedContext.isPresent();
    if (_isPresent) {
      final Microservice microservice = LemmaServiceModelFactory.SERVICE_FACTORY.createMicroservice();
      String _name = this.context.getName();
      String _plus = ("org.my_organization." + _name);
      microservice.setName(_plus);
      microservice.getQualifiedNameParts().addAll(Collections.<String>unmodifiableList(CollectionLiterals.<String>newArrayList("org", "my_organization")));
      microservice.setVisibility(LemmaServiceModelFactory.mapBoundedContextTypeToServiceVisibility(boundedContext.get().getType()));
      microservice.setType(LemmaServiceModelFactory.mapBoundedContextTypeToServiceType(boundedContext.get().getType()));
      ContextMap _map = this.cmlModel.getMap();
      final OpenHostServiceUpstreamGenerator ohsUpstreamGenerator = new OpenHostServiceUpstreamGenerator(this.context, this.serviceModel, microservice, _map, dataModelPath, technologyModelPath, this.technologies);
      ohsUpstreamGenerator.mapOhsUpstream();
      this.serviceModel.getMicroservices().add(microservice);
    }
    return this.serviceModel;
  }
}
