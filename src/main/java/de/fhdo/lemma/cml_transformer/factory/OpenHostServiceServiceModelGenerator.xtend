package de.fhdo.lemma.cml_transformer.factory

import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataOperation
import de.fhdo.lemma.data.DataStructure
import de.fhdo.lemma.service.Import
import de.fhdo.lemma.service.ImportType
import de.fhdo.lemma.service.Interface
import de.fhdo.lemma.service.Microservice
import de.fhdo.lemma.service.Operation
import de.fhdo.lemma.service.ServiceFactory
import de.fhdo.lemma.service.ServiceModel
import de.fhdo.lemma.technology.CommunicationType
import de.fhdo.lemma.technology.ExchangePattern
import java.util.Collections
import java.util.LinkedList
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole
import de.fhdo.lemma.data.PrimitiveType
import de.fhdo.lemma.data.DataFactory

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
	static  val DATA_FACTORY = DataFactory.eINSTANCE

	/**
	 * Mapped LEMMA DML {@link Context} for which a Microservice will be generated
	 */
	private Context context

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

	new(Context context, Microservice service, ContextMap map, String domainDataModelPath, String technologyModelPath) {
		this.context = context
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
		rr.stream.flatMap([rel|(rel as UpstreamDownstreamRelationship).upstreamExposedAggregates.stream]) // put all exposed aggregates of all relationships into one stream
		.forEach([ agg |
			// Look up the Application Service in the LEMMA Context that exposes the exposed aggregate 
			val appService = this.context.complexTypes.stream.filter([ cType |
				cType.name.equals(agg.name + "Api")
			]).findFirst()

			if (appService.isPresent) {
				// Create an service interface for the application service
				val interface = mapApplicationServiceToServiceInterface(appService.get as DataStructure)

				// Put the created interface in the service model
				this.service.interfaces.add(interface)
			}
		])
	}

	/**
	 * Maps a LEMMA Application Service to a LEMMA SML {@link Interface}
	 */
	private def mapApplicationServiceToServiceInterface(DataStructure appService) {
		val interface = SERVICE_FACTORY.createInterface
		interface.name = appService.name

		appService.operations?.forEach([ appServiceOp |
			val serviceOp = appServiceOp.mapDataOperationToServiceOperation
			interface.operations.add(serviceOp)
		])

		return interface
	}

	/**
	 * Maps LEMMA {@link DataOperation} to a {@link ReferredOperation] of a {@link ServiceInterface} 
	 */
	private def mapDataOperationToReferredOperation(DataOperation dataOperation) {
		val referredOperation = SERVICE_FACTORY.createReferredOperation

		referredOperation.operation = dataOperation.mapDataOperationToServiceOperation

		return referredOperation
	}


	/**
	 * Maps LEMMA {@link DataOperation} to a {@link Operation] of a {@link ServiceInterface} 
	 */
	private def mapDataOperationToServiceOperation(DataOperation dataOperation) {
		val operation = SERVICE_FACTORY.createOperation
		operation.name = dataOperation.name

		if (!dataOperation.hasNoReturnType) { // a return type is an "out" parameter
			val returnParam = SERVICE_FACTORY.createParameter
			returnParam.name = "returnParam"
			if (dataOperation.complexReturnType !== null) { // Complex Type				
				returnParam.communicationType = CommunicationType.SYNCHRONOUS
				val importedType = SERVICE_FACTORY.createImportedType
				importedType.import = returnImportForComplexType(dataOperation.complexReturnType)
				returnParam.importedType = importedType
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
				importedType.import = returnImportForComplexType(param.complexType)
				serviceOpParam.importedType = importedType
				serviceOpParam.importedType.type = param.complexType
			} else { // Primitive
				serviceOpParam.primitiveType = param.primitiveType
			}
			operation.parameters.add(serviceOpParam)
		])
		
		return operation
	}

	/**
	 * Builds a {@link Import for a {@link ComplexType} of the {@link DataModel}
	 */
	private def returnImportForComplexType(ComplexType cType) {
		val import = SERVICE_FACTORY.createImport
		import.name = cType.name
		import.importURI = this.technologyModelPath + "/" + cType.name + ".data"
		import.importType = ImportType.DATATYPES
		import.t_relatedImportAlias = cType.name

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
}
