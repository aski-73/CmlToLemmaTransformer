package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.cml_transformer.Util
import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataOperation
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.service.Import
import de.fhdo.lemma.service.ImportType
import de.fhdo.lemma.service.Interface
import de.fhdo.lemma.service.Microservice
import de.fhdo.lemma.service.ServiceFactory
import de.fhdo.lemma.service.ServiceModel
import de.fhdo.lemma.technology.CommunicationType
import de.fhdo.lemma.technology.ExchangePattern
import de.fhdo.lemma.technology.ServiceAspect
import de.fhdo.lemma.technology.Technology
import java.util.List
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole
import org.eclipse.emf.ecore.util.EcoreUtil
import de.fhdo.lemma.cml_transformer.factory.TechnologyModelFactory
import de.fhdo.lemma.cml_transformer.technologies.CustomTechnology

/**
 * Upstream implementation of an OHS
 * 
 * Adds service {@link Interface} for every Application Service that exposes an aggregate.
 * The {@link ApplicationService} must follow the naming rule "ExposedAggregate"+"API".
 * If such an {@link ApplicationService} is not defined nothing will be done.
 */
class OpenHostServiceUpstreamGenerator extends AbstractRelationshipGenerator {
	static val SERVICE_FACTORY = ServiceFactory.eINSTANCE

	/**
	 * List of LEMMA {@link Technology}-Model. Newly created technologies that are identified
	 * by the implementationTechnology key word will be put in here
	 */
	List<Technology> technologies

	/**
	 * The service model that contains the microservice. Needed in order to add the imports
	 */
	ServiceModel serviceModel

	/**
	 * LEMMA {@link Microservice} that will get a new {@link ServiceInterface}. Either Api or Accessor. Depends on if its a upstream/downstream context.
	 */
	Microservice service

	String domainDataModelPath

	String technologyModelPath

	val TechnologyModelFactory techFactory

	new(
		Context context,
		ServiceModel serviceModel,
		Microservice service,
		ContextMap map,
		String domainDataModelPath,
		String technologyModelPath,
		List<Technology> technologies
	) {
		// provide empty list instead of already instantiated data models since this class does need them
		super(context, map, newLinkedList)
		this.serviceModel = serviceModel
		this.service = service
		this.domainDataModelPath = domainDataModelPath
		this.technologyModelPath = technologyModelPath
		this.technologies = technologies
		this.techFactory = new TechnologyModelFactory(technologyModelPath)
	}

	/**
	 * The OHS upstream context receives service {@link Interface}s for every Application Service that is
	 * responsible for exposing the exposed aggregate.
	 * The Application Service must follow the naming rule "ExposedAggregateName"+"Api".
	 * The service {@link Interface} will have equivalent operations like the Application Service of the {@link DataModel}
	 */
	override map() {
		// Relationships in which the Context is the Upstream of an OHS relation
		val rr = filter()
		if (rr.size == 0) {
			return
		}

		// For every exposed aggregate an interface will be generated (if it is not created yet. Different relationships with
		// the same OHS can expose different aggregates. But it is possible to expose the same)
		for (rel : rr) {

			(rel as UpstreamDownstreamRelationship).upstreamExposedAggregates.stream.forEach [ agg |
				// Look up the Application Service in the LEMMA Context that exposes the exposed aggregate 
				val appService = this.targetCtx.complexTypes.stream.filter([ cType |
					cType.name.equals(agg.name + "Api")
				]).findFirst()

				if (appService.isPresent) {
					// Create an service interface for the application service. The interface and its operation
					// use a technology that its mapped by the CML keyword "implementationTechnology"
					val CustomTechnology cTechnology = techFactory.generateTechnologymodel(rel.implementationTechnology)
					val interfaceImportPair = mapApplicationServiceToServiceInterface(appService.get as DataStructure,
						cTechnology)

					// Put the created interface in the service model
					this.service.interfaces.add(interfaceImportPair.key)
					/* Add technology annotation by adding the import. The ServiceDslExtractor automatically inserts
					 * the @technology annotation. And add import in general */
					this.serviceModel.imports.addAll(interfaceImportPair.value)

					if (!Util.technologyExists(this.technologies, cTechnology.technology)) {
						this.technologies.add(cTechnology.technology)
					}

				}
			]
		}
	}

	/**
	 * TODO Must also use the CML Application Service in order to get the visibilty of the operations
	 * 
	 * Maps a LEMMA Application Service to a LEMMA SML {@link Interface}
	 * See sml/metamodel-interfaces-operations.uxf and sml/metamodel-endpoints.uxf for reference
	 * 
	 * @return Pair: Mapped Interface -> List with the used imports
	 */
	private def Pair<Interface, List<Import>> mapApplicationServiceToServiceInterface(DataStructure appService,
		CustomTechnology cTechnology) {
		val interface = SERVICE_FACTORY.createInterface
		interface.name = appService.name
		val imports = <Import>newLinkedList

		appService.operations?.forEach([ appServiceOp |
			val serviceOp = appServiceOp.mapDataOperationToServiceOperation(imports)
			if (cTechnology !== null) {
				// Add Service Aspects for the operation
				val importedServiceAspect = SERVICE_FACTORY.createImportedServiceAspect
				// Try to map the operationName to a service aspect since its not possible
				// to determine it from the CML Model. Currenty only useable with the predefined
				// Rest Technology with the GET, POST, CREATE, DELETE Aspects
				importedServiceAspect.importedAspect = cTechnology.mapMethodNamesToServiceAspect(serviceOp.name)
				importedServiceAspect.import = Util.returnImportForTechnology(cTechnology.technology, this.technologyModelPath)
				// Add Endpoint. URI is "/InterfaceName". Protocol is the first protocol of the technology
				// since its not possible to determine which protocol to use from the CML model.
				// As for now only a Rest-Technology exists that contains one protocoll ("rest")
				val importedProtocol = SERVICE_FACTORY.createImportedProtocolAndDataFormat
				importedProtocol.dataFormat = cTechnology.technology.protocols.get(0).dataFormats.get(0)
				importedProtocol.importedProtocol = cTechnology.technology.protocols.get(0)
				importedProtocol.import = Util.returnImportForTechnology(cTechnology.technology, this.technologyModelPath)
				val endpoint = SERVICE_FACTORY.createEndpoint
				endpoint.addresses.add("/" + interface.name)
				endpoint.protocols.add(importedProtocol)
				serviceOp.endpoints.add(endpoint)

				serviceOp.aspects.add(importedServiceAspect)

				val technologyImport = Util.returnImportForTechnology(cTechnology.technology, this.technologyModelPath)
				if (!Util.importExists(imports, technologyImport)) {
					imports.add(technologyImport)
				}
			}

			interface.operations.add(serviceOp)
		])

		return interface -> imports
	}

	/**
	 * Maps LEMMA {@link DataOperation} to a {@link ReferredOperation] of a {@link ServiceInterface} 
	 */
	private def mapDataOperationToReferredOperation(DataOperation dataOperation, List<Import> imports) {
		val referredOperation = SERVICE_FACTORY.createReferredOperation

		referredOperation.operation = dataOperation.mapDataOperationToServiceOperation(imports)

		return referredOperation
	}

	/**
	 * Maps LEMMA {@link DataOperation} to a {@link Operation} of a {@link ServiceInterface} 
	 */
	private def mapDataOperationToServiceOperation(DataOperation dataOperation, List<Import> imports) {
		val operation = SERVICE_FACTORY.createOperation
		operation.name = dataOperation.name

		if (!dataOperation.hasNoReturnType) { // a return type is an "out" parameter
			val returnParam = SERVICE_FACTORY.createParameter
			returnParam.name = "returnParam"
			if (dataOperation.complexReturnType !== null) { // Complex Type				
				returnParam.communicationType = CommunicationType.SYNCHRONOUS
				val importedType = SERVICE_FACTORY.createImportedType
				val paramTypeImport = returnImportForComplexType(dataOperation.complexReturnType)
				importedType.import = paramTypeImport
				returnParam.importedType = importedType
				returnParam.importedType.type = EcoreUtil.copy(dataOperation.complexReturnType)

				// Need a deep copy because xcore models must contain unique objects
				val paramTypeImportClone = EcoreUtil.copy(paramTypeImport)
				if (!Util.importExists(imports, paramTypeImportClone)) {
					imports.add(paramTypeImportClone)
				}
			} else { // Primitive
				returnParam.primitiveType = EcoreUtil.copy(dataOperation.primitiveReturnType)
			}
			returnParam.exchangePattern = ExchangePattern.OUT
			operation.parameters.add(returnParam)
		}

		// Add DataOperationParameters
		dataOperation.parameters.forEach([ param |
			val serviceOpParam = SERVICE_FACTORY.createParameter
			serviceOpParam.name = param.name
			if (param.complexType !== null) { // Complex Type				
				serviceOpParam.communicationType = CommunicationType.SYNCHRONOUS
				val importedType = SERVICE_FACTORY.createImportedType
				val complexTypeImport = returnImportForComplexType(param.complexType)
				importedType.import = complexTypeImport
				serviceOpParam.importedType = importedType
				serviceOpParam.importedType.type = EcoreUtil.copy(param.complexType)

				// Need a deep copy because xcore models must contain unique objects
				val complexTypeImportClone = EcoreUtil.copy(complexTypeImport)
				if (!Util.importExists(imports, complexTypeImportClone)) {
					imports.add(complexTypeImportClone)
				}
			} else { // Primitive
				serviceOpParam.primitiveType = EcoreUtil.copy(param.primitiveType)
			}
			operation.parameters.add(serviceOpParam)
		])

		return operation
	}

	/**
	 * Builds a {@link Import} for a {@link ComplexType} which must be located in targetCtx.
	 * A microservice can only import types from the own data model since one team is responsible
	 * for all of their domain concepts.
	 */
	private def returnImportForComplexType(ComplexType cType) {
		val import = SERVICE_FACTORY.createImport
		import.name = targetCtx.name // alias
		import.importURI = this.domainDataModelPath + "/" + targetCtx.name + ".data"
		import.importType = ImportType.DATATYPES
		import.t_relatedImportAlias = targetCtx.name

		val check = targetCtx.complexTypes.stream.filter [ tempComplexType |
			tempComplexType.name.equals(cType.name)
		].findAny
		if (check.isEmpty) {
			System.out.println("Complex Type " + cType.name + " doesn't exist in context " + targetCtx.name)
		}

		return import
	}

	/**
	 * Filter the relations where {@link Context} is the upstream of a OHS relation. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the relation in order to map them.
	 */
	override filter() {
		return inputMap.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).upstream.name.equals(targetCtx.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE)
		]).collect(Collectors.toList())
	}
}
