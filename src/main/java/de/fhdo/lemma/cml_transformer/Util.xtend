package de.fhdo.lemma.cml_transformer

import java.util.List
import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.service.Import
import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.ComplexType
import org.eclipse.emf.ecore.util.EcoreUtil
import de.fhdo.lemma.service.ServiceFactory
import de.fhdo.lemma.service.ImportType
import de.fhdo.lemma.service.Microservice
import de.fhdo.lemma.service.ServiceModel
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import de.fhdo.lemma.service.ProtocolSpecification
import java.util.HashMap
import java.util.Collection
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import java.util.stream.Collectors
import java.util.Optional
import de.fhdo.lemma.service.Visibility

class Util {
	static val SERVICE_FACTORY = ServiceFactory.eINSTANCE

	static def technologyExists(List<Technology> technologies, Technology technology) {
		for (t : technologies) {
			if (t.name.equals(technology.name)) {
				return true
			}
		}

		return false
	}

	static def importExists(List<Import> imports, Import im) {
		for (Import tempIm : imports) {
			if (tempIm.importType == im.importType && tempIm.importURI.equals(im.importURI)) {
				return true
			}
		}

		return false
	}

	static def addComplexTypesIntoContext(Context targetCtx, List<? extends ComplexType> sourceListcTypes) {
		// Only add complex types which are not already existing. A (domain object or) list type of the upstream might already
		// exist in the target context because in CML it's possible to reference domain objects (which can contain list types) from other bounded contexts
		// and the DomainDataModelFactory would already create it in the target context. But this behavior is not wanted because one 
		// bounded context (microservice) is assigned to one team. Every team must take care of their own (domain objects and) list types.
		// It's also possible to reference external (domain objects and) list types in LEMMA but it should not be done of the same reason.
		mergeComplexTypeLists(targetCtx.complexTypes, sourceListcTypes)

		targetCtx.complexTypes.forEach [ cType |
			cType.context = targetCtx
		]
	}

	static def mergeComplexTypeLists(List<ComplexType> targetList, List<? extends ComplexType> sourceList) {
		for (ComplexType sourceElement : sourceList) {
			val checkSourceElement = targetList.stream.filter([ targetElement |
				targetElement.name.equals(sourceElement.name)
			]).findAny
			if (!checkSourceElement.present) {
				targetList.add(EcoreUtil.copy(sourceElement))
			}
		}
	}

	/**
	 * Builds a {@link Import} for a {@link ServiceAspect} of a {@link Technology}
	 */
	static def returnImportForTechnology(Technology technology, String technologyModelPath) {
		val import = SERVICE_FACTORY.createImport
		import.name = technology.name
		import.importURI = technologyModelPath + "/" + technology.name + ".technology"
		import.importType = ImportType.TECHNOLOGY
		import.t_relatedImportAlias = technology.name

		return import
	}

	/**
	 * Builds a {@link Import} for a {@link Microservice}
	 */
	static def returnImportForMicroservice(Microservice microservice, String serviceModelPath) {
		val import = SERVICE_FACTORY.createImport
		import.name = microservice.returnSimpleNameOfMicroservice
		import.importURI = serviceModelPath + "/" + import.name + ".services"
		import.importType = ImportType.MICROSERVICES
		import.t_relatedImportAlias = import.name

		return import
	}

	static def returnSimpleNameOfMicroservice(Microservice microservice) {
		val split = microservice.name.split("\\.")
		return split.get(split.length - 1)
	}

	/**
	 * Puts all used protocols of {@link Operation}s of an {@link Interface} into a collection.
	 * Puts only distinct protocols into the list
	 */
	static def Collection<ProtocolSpecification> returnMicroserviceProtocolSpecification(Microservice service) {
		// Endpoints of operations refer to an importedProtocolAndDataFormat. We extract those and
		// put a copy of them into a ProtocolSpecficiation which a microservice can refer to.
		val distinctProtocols = new HashMap<String, ProtocolSpecification>()
		service.interfaces.stream.flatMap[iface|iface.operations.stream].flatMap[operation|operation.endpoints.stream].
			flatMap[endpoint|endpoint.protocols.stream].forEach [ importedProtAndDatFormat |
				if (!distinctProtocols.containsKey(importedProtAndDatFormat.importedProtocol.name)) {
					val protocolSpec = SERVICE_FACTORY.createProtocolSpecification
					protocolSpec.communicationType = importedProtAndDatFormat.importedProtocol.communicationType
					protocolSpec.protocol = EcoreUtil.copy(importedProtAndDatFormat)
					distinctProtocols.put(importedProtAndDatFormat.importedProtocol.name, protocolSpec)
				}
			]

		return distinctProtocols.values
	}

	/**
	 * Insert into {@value targetService} a "required microservices" statement. It contains the upstream contexts
	 * of its relationships.
	 * 
	 * @param targetService
	 * @param serviceModels All created service models so far
	 */
	static def addRequiredStatementIfDownstream(ServiceModel targetServiceModel, List<ServiceModel> serviceModels,
		ContextMap map, String serviceModelPath) {
		// Filter upstream service models of targetService
		val List<Optional<ServiceModel>> upstreamServices = map.relationships.stream.filter [ rel |
			// Return the relevant relationships of the target service.
			// These are those CML relationships whose downstream context name is equal to the targetService
			if (rel instanceof UpstreamDownstreamRelationship) {
				val udRel = rel as UpstreamDownstreamRelationship
				// we use "endsWith" since the targetService is a fully qualified name like org.xyz.ContextName
				return targetServiceModel.microservices.get(0).name.endsWith(udRel.downstream.name)
			} else
				false
		].map [ rel |
			// return the upstream services. Return those services whose name is equal to the upstream context of the relationship
			return serviceModels.stream.filter [ serviceModel |
				serviceModel.microservices.get(0).name.endsWith((rel as UpstreamDownstreamRelationship).upstream.name)
			].findFirst()
		].collect(Collectors.toList())

		upstreamServices.forEach [ upstreamService |
			// Build required statement
			val required = SERVICE_FACTORY.createPossiblyImportedMicroservice
			required.import = returnImportForMicroservice(upstreamService.get().microservices.get(0), serviceModelPath)
			targetServiceModel.microservices.get(0).requiredMicroservices.add(required)
			required.microservice = upstreamService.get().microservices.get(0)
			
			// Add import for required microservice into service model of targetService
			targetServiceModel.imports.add(required.import)
			
		]
	}
	
	/**
	 * Adds an Interface with an "noOp" Method for Microservices whose corresponding CML Bounded Context does not
	 * define any APIs. This is done in order to make it possible to generate a microservice none the less.
	 */
	static def addInterfaceWithNoOpToEmptyMicroservice(Microservice targetService) {
		if (targetService.interfaces.size > 0)
			return
			
		val iface = SERVICE_FACTORY.createInterface
		iface.name = targetService.returnSimpleNameOfMicroservice
		val noOp = SERVICE_FACTORY.createOperation
		noOp.name = "noOp"
		noOp.visibility = Visibility.INTERNAL
		iface.operations.add(noOp)
		
		targetService.interfaces.add(iface)
	}
}
