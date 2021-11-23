package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.cml_transformer.factory.LemmaTechnologyModelFactory
import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataFactory
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataOperation
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.service.Import
import de.fhdo.lemma.service.ImportType
import de.fhdo.lemma.service.Interface
import de.fhdo.lemma.service.Microservice
import de.fhdo.lemma.service.ServiceFactory
import de.fhdo.lemma.technology.CommunicationType
import de.fhdo.lemma.technology.ExchangePattern
import de.fhdo.lemma.technology.ServiceAspect
import de.fhdo.lemma.technology.Technology
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole
import java.util.List
import de.fhdo.lemma.service.ServiceModel
import org.eclipse.emf.ecore.util.EcoreUtil

/**
 * Upstream implementation of an OHS
 * 
 * Adds service {@link Interface} for every Application Service that exposes an aggregate.
 * The {@link ApplicationService} must follow the naming rule "ExposedAggregate"+"API".
 * If such an {@link ApplicationService} is not defined nothing will be done.
 */
class OpenHostServiceServiceModelGenerator {
	static val SERVICE_MODEL_IMPORT_ALIAS = "Services"

	static val SERVICE_FACTORY = ServiceFactory.eINSTANCE
	static val DATA_FACTORY = DataFactory.eINSTANCE

	/**
	 * Mapped LEMMA DML {@link Context} for which a Microservice will be generated
	 */
	private Context context

	/**
	 * The service model that contains the microservice. Needed in order to add the imports
	 */
	private ServiceModel serviceModel

	/**
	 * LEMMA {@link Microservice} that will get a new {@link ServiceInterface}. Either Api or Accessor. Depends on if its a upstream/downstream context.
	 */
	private Microservice service

	/**
	 * Context Map of the CML Model which contains  OHS-relations of the LEMMA DML {@link Context}. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the Context Map in order to map them.
	 */
	private ContextMap map

	private String domainDataModelPath

	private String technologyModelPath

	private val techFactory = new LemmaTechnologyModelFactory()

	new(
		Context context,
		ServiceModel serviceModel,
		Microservice service,
		ContextMap map,
		String domainDataModelPath,
		String technologyModelPath
	) {
		this.context = context
		this.serviceModel = serviceModel
		this.service = service
		this.map = map
		this.domainDataModelPath = domainDataModelPath
		this.technologyModelPath = technologyModelPath
	}

	/**
	 * The OHS upstream context receives service {@link Interface}s for every Application Service that is
	 * responsible for exposing the exposed aggregate.
	 * The Application Service must follow the naming rule "ExposedAggregateName"+"Api".
	 * The service {@link Interface} will have equivalent operations like the Application Service of the {@link DataModel}
	 */
	def mapOhsUpstream() {
		// Relationships in which the Context is the Upstream of an OHS relation
		val rr = filterUpstreamRelationships()
		if (rr.size == 0) {
			return
		}

		// For every exposed aggregate an interface will be generated (if it is not created yet. Different relationships with
		// the same OHS can expose different aggregates. But it is possible to expose the same)
		for (rel : rr) {

			(rel as UpstreamDownstreamRelationship).upstreamExposedAggregates.stream.forEach [ agg |
				// Look up the Application Service in the LEMMA Context that exposes the exposed aggregate 
				val appService = this.context.complexTypes.stream.filter([ cType |
					cType.name.equals(agg.name + "Api")
				]).findFirst()

				if (appService.isPresent) {
					// Create an service interface for the application service. The interface and its operation
					// use a technology that its mapped by the CML keyword "implementationTechnology"
					val technology = techFactory.
						mapImplementationTechnologyToTechnologymodel(rel.implementationTechnology)
					val interfaceImportPair = mapApplicationServiceToServiceInterface(appService.get as DataStructure,
						technology)

					// Put the created interface in the service model
					this.service.interfaces.add(interfaceImportPair.key)
					this.serviceModel.imports.addAll(interfaceImportPair.value)
				}
			]
		}
	}

	/**
	 * Maps a LEMMA Application Service to a LEMMA SML {@link Interface}
	 * See sml/metamodel-interfaces-operations.uxf and sml/metamodel-endpoints.uxf for reference
	 * 
	 * @return Pair: Mapped Interface -> List with the used imports
	 */
	private def Pair<Interface, List<Import>> mapApplicationServiceToServiceInterface(DataStructure appService,
		Technology technology) {
		val interface = SERVICE_FACTORY.createInterface
		interface.name = appService.name
		val imports = <Import>newLinkedList

		appService.operations?.forEach([ appServiceOp |
			val serviceOp = appServiceOp.mapDataOperationToServiceOperation(imports)
			if (technology !== null) {
				// Add Service Aspects for the operation
				val importedServiceAspect = SERVICE_FACTORY.createImportedServiceAspect
				// Try to map the operationName to a service aspect since its not possible
				// to determine it from the CML Model. Currenty only useable with the predefined
				// Rest Technology with the GET, POST, CREATE, DELETE Aspects
				importedServiceAspect.importedAspect = techFactory.mapMethodNamesToServiceAspectNames(serviceOp.name)
				importedServiceAspect.import = technology.returnImportForTechnology
				// Add Endpoint. URI is "/InterfaceName". Protocol is the first protocol of the technology
				// since its not possible to determine which protocol to use from the CML model
				val importedProtocol = SERVICE_FACTORY.createImportedProtocolAndDataFormat
				importedProtocol.dataFormat = technology.protocols.get(0).dataFormats.get(0)
				importedProtocol.importedProtocol = technology.protocols.get(0)
				importedProtocol.import = technology.returnImportForTechnology
				val endpoint = SERVICE_FACTORY.createEndpoint
				endpoint.addresses.add("/" + interface.name)
				endpoint.protocols.add(importedProtocol)
				serviceOp.endpoints.add(endpoint)
				
				serviceOp.aspects.add(importedServiceAspect)
					
				val technologyImport = technology.returnImportForTechnology
				if (!imports.importExists(technologyImport)) {
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
	 * Maps LEMMA {@link DataOperation} to a {@link Operation] of a {@link ServiceInterface} 
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
				
				// Need a deep copy because xcore models must contain unique objects
				val paramTypeImportClone = EcoreUtil.copy(paramTypeImport)
				if (!imports.importExists(paramTypeImportClone)) {
					imports.add(paramTypeImportClone)
				}
			} else { // Primitive
				returnParam.primitiveType = dataOperation.primitiveReturnType
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
				serviceOpParam.importedType.type = param.complexType
				
				// Need a deep copy because xcore models must contain unique objects
				val complexTypeImportClone = EcoreUtil.copy(complexTypeImport)
				if (!imports.importExists(complexTypeImportClone)) {
					imports.add(complexTypeImportClone)
				}
			} else { // Primitive
				serviceOpParam.primitiveType = param.primitiveType
			}
			operation.parameters.add(serviceOpParam)
		])

		return operation
	}

	/**
	 * Builds a {@link Import} for a {@link ComplexType} of the {@link DataModel}
	 */
	private def returnImportForComplexType(ComplexType cType) {
		val import = SERVICE_FACTORY.createImport
		import.name = cType.name
		import.importURI = this.domainDataModelPath + "/" + cType.name + ".data"
		import.importType = ImportType.DATATYPES
		import.t_relatedImportAlias = cType.name

		return import
	}

	/**
	 * Builds a {@link Import} for a {@link ServiceAspect} of a {@link Technology}
	 */
	private def returnImportForTechnology(Technology technology) {
		val import = SERVICE_FACTORY.createImport
		import.name = technology.name
		import.importURI = this.technologyModelPath + "/" + technology.name + ".technology"
		import.importType = ImportType.TECHNOLOGY
		import.t_relatedImportAlias = technology.name

		return import
	}

	/**
	 * Filter the relations where {@link Context} is the upstream of a OHS relation. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the relation in order to map them.
	 */
	private def filterUpstreamRelationships() {
		return map.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).upstream.name.equals(context.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE)
		]).collect(Collectors.toList())
	}
	
	private def importExists (List<Import> imports, Import im)  {
		for (Import tempIm: imports) {
			if (tempIm.importType == im.importType && tempIm.importURI.equals(im.importURI)) {
				return true
			}
		}
		
		return false
	}
}
