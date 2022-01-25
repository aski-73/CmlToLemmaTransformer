package de.fhdo.lemma.cml_transformer;

import com.google.common.base.Objects;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.service.Endpoint;
import de.fhdo.lemma.service.Import;
import de.fhdo.lemma.service.ImportType;
import de.fhdo.lemma.service.ImportedProtocolAndDataFormat;
import de.fhdo.lemma.service.Interface;
import de.fhdo.lemma.service.Microservice;
import de.fhdo.lemma.service.Operation;
import de.fhdo.lemma.service.PossiblyImportedMicroservice;
import de.fhdo.lemma.service.ProtocolSpecification;
import de.fhdo.lemma.service.ServiceFactory;
import de.fhdo.lemma.service.ServiceModel;
import de.fhdo.lemma.service.Visibility;
import de.fhdo.lemma.technology.Technology;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;
import org.eclipse.emf.ecore.util.EcoreUtil;

@SuppressWarnings("all")
public class Util {
  private static final ServiceFactory SERVICE_FACTORY = ServiceFactory.eINSTANCE;
  
  public static boolean technologyExists(final List<Technology> technologies, final Technology technology) {
    for (final Technology t : technologies) {
      boolean _equals = t.getName().equals(technology.getName());
      if (_equals) {
        return true;
      }
    }
    return false;
  }
  
  public static boolean importExists(final List<Import> imports, final Import im) {
    for (final Import tempIm : imports) {
      if ((Objects.equal(tempIm.getImportType(), im.getImportType()) && tempIm.getImportURI().equals(im.getImportURI()))) {
        return true;
      }
    }
    return false;
  }
  
  public static void addComplexTypesIntoContext(final Context targetCtx, final List<? extends ComplexType> sourceListcTypes) {
    Util.mergeComplexTypeLists(targetCtx.getComplexTypes(), sourceListcTypes);
    final Consumer<ComplexType> _function = (ComplexType cType) -> {
      cType.setContext(targetCtx);
    };
    targetCtx.getComplexTypes().forEach(_function);
  }
  
  public static void mergeComplexTypeLists(final List<ComplexType> targetList, final List<? extends ComplexType> sourceList) {
    for (final ComplexType sourceElement : sourceList) {
      {
        final Predicate<ComplexType> _function = (ComplexType targetElement) -> {
          return targetElement.getName().equals(sourceElement.getName());
        };
        final Optional<ComplexType> checkSourceElement = targetList.stream().filter(_function).findAny();
        boolean _isPresent = checkSourceElement.isPresent();
        boolean _not = (!_isPresent);
        if (_not) {
          targetList.add(EcoreUtil.<ComplexType>copy(sourceElement));
        }
      }
    }
  }
  
  /**
   * Builds a {@link Import} for a {@link ServiceAspect} of a {@link Technology}
   */
  public static Import returnImportForTechnology(final Technology technology, final String technologyModelPath) {
    final Import import_ = Util.SERVICE_FACTORY.createImport();
    import_.setName(technology.getName());
    String _name = technology.getName();
    String _plus = ((technologyModelPath + "/") + _name);
    String _plus_1 = (_plus + ".technology");
    import_.setImportURI(_plus_1);
    import_.setImportType(ImportType.TECHNOLOGY);
    import_.setT_relatedImportAlias(technology.getName());
    return import_;
  }
  
  /**
   * Builds a {@link Import} for a {@link Microservice}
   */
  public static Import returnImportForMicroservice(final Microservice microservice, final String serviceModelPath) {
    final Import import_ = Util.SERVICE_FACTORY.createImport();
    import_.setName(Util.returnSimpleNameOfMicroservice(microservice));
    String _name = import_.getName();
    String _plus = ((serviceModelPath + "/") + _name);
    String _plus_1 = (_plus + ".services");
    import_.setImportURI(_plus_1);
    import_.setImportType(ImportType.MICROSERVICES);
    import_.setT_relatedImportAlias(import_.getName());
    return import_;
  }
  
  public static String returnSimpleNameOfMicroservice(final Microservice microservice) {
    final String[] split = microservice.getName().split("\\.");
    int _length = split.length;
    int _minus = (_length - 1);
    return split[_minus];
  }
  
  /**
   * Puts all used protocols of {@link Operation}s of an {@link Interface} into a collection.
   * Puts only distinct protocols into the list
   */
  public static Collection<ProtocolSpecification> returnMicroserviceProtocolSpecification(final Microservice service) {
    final HashMap<String, ProtocolSpecification> distinctProtocols = new HashMap<String, ProtocolSpecification>();
    final Function<Interface, Stream<Operation>> _function = (Interface iface) -> {
      return iface.getOperations().stream();
    };
    final Function<Operation, Stream<Endpoint>> _function_1 = (Operation operation) -> {
      return operation.getEndpoints().stream();
    };
    final Function<Endpoint, Stream<ImportedProtocolAndDataFormat>> _function_2 = (Endpoint endpoint) -> {
      return endpoint.getProtocols().stream();
    };
    final Consumer<ImportedProtocolAndDataFormat> _function_3 = (ImportedProtocolAndDataFormat importedProtAndDatFormat) -> {
      boolean _containsKey = distinctProtocols.containsKey(importedProtAndDatFormat.getImportedProtocol().getName());
      boolean _not = (!_containsKey);
      if (_not) {
        final ProtocolSpecification protocolSpec = Util.SERVICE_FACTORY.createProtocolSpecification();
        protocolSpec.setCommunicationType(importedProtAndDatFormat.getImportedProtocol().getCommunicationType());
        protocolSpec.setProtocol(EcoreUtil.<ImportedProtocolAndDataFormat>copy(importedProtAndDatFormat));
        distinctProtocols.put(importedProtAndDatFormat.getImportedProtocol().getName(), protocolSpec);
      }
    };
    service.getInterfaces().stream().<Operation>flatMap(_function).<Endpoint>flatMap(_function_1).<ImportedProtocolAndDataFormat>flatMap(_function_2).forEach(_function_3);
    return distinctProtocols.values();
  }
  
  /**
   * Insert into {@value targetService} a "required microservices" statement. It contains the upstream contexts
   * of its relationships.
   * 
   * @param targetService
   * @param serviceModels All created service models so far
   */
  public static void addRequiredStatementIfDownstream(final ServiceModel targetServiceModel, final List<ServiceModel> serviceModels, final ContextMap map, final String serviceModelPath) {
    final Predicate<Relationship> _function = (Relationship rel) -> {
      boolean _xifexpression = false;
      if ((rel instanceof UpstreamDownstreamRelationship)) {
        final UpstreamDownstreamRelationship udRel = ((UpstreamDownstreamRelationship) rel);
        return targetServiceModel.getMicroservices().get(0).getName().endsWith(udRel.getDownstream().getName());
      } else {
        _xifexpression = false;
      }
      return _xifexpression;
    };
    final Function<Relationship, Optional<ServiceModel>> _function_1 = (Relationship rel) -> {
      final Predicate<ServiceModel> _function_2 = (ServiceModel serviceModel) -> {
        return serviceModel.getMicroservices().get(0).getName().endsWith(((UpstreamDownstreamRelationship) rel).getUpstream().getName());
      };
      return serviceModels.stream().filter(_function_2).findFirst();
    };
    final List<Optional<ServiceModel>> upstreamServices = map.getRelationships().stream().filter(_function).<Optional<ServiceModel>>map(_function_1).collect(Collectors.<Optional<ServiceModel>>toList());
    final Consumer<Optional<ServiceModel>> _function_2 = (Optional<ServiceModel> upstreamService) -> {
      final PossiblyImportedMicroservice required = Util.SERVICE_FACTORY.createPossiblyImportedMicroservice();
      required.setImport(Util.returnImportForMicroservice(upstreamService.get().getMicroservices().get(0), serviceModelPath));
      targetServiceModel.getMicroservices().get(0).getRequiredMicroservices().add(required);
      required.setMicroservice(upstreamService.get().getMicroservices().get(0));
      targetServiceModel.getImports().add(required.getImport());
    };
    upstreamServices.forEach(_function_2);
  }
  
  /**
   * Adds an Interface with an "noOp" Method for Microservices whose corresponding CML Bounded Context does not
   * define any APIs. This is done in order to make it possible to generate a microservice none the less.
   */
  public static void addInterfaceWithNoOpToEmptyMicroservice(final Microservice targetService) {
    int _size = targetService.getInterfaces().size();
    boolean _greaterThan = (_size > 0);
    if (_greaterThan) {
      return;
    }
    final Interface iface = Util.SERVICE_FACTORY.createInterface();
    iface.setName(Util.returnSimpleNameOfMicroservice(targetService));
    final Operation noOp = Util.SERVICE_FACTORY.createOperation();
    noOp.setName("noOp");
    noOp.setVisibility(Visibility.INTERNAL);
    iface.getOperations().add(noOp);
    targetService.getInterfaces().add(iface);
  }
}
