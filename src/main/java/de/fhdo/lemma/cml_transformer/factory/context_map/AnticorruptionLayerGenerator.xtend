package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.data.ComplexTypeFeature
import de.fhdo.lemma.data.Context
import de.fhdo.lemma.data.DataFactory
import de.fhdo.lemma.data.DataModel
import de.fhdo.lemma.data.DataStructure
import java.util.List
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtend.lib.annotations.Data

/**
 * Adds a translator into the domain data model {@link DataModel}.
 * The translator translates between an exposed aggregate X of the upstream context and a domain object Y of
 * the downstream stream context (ACL). The domain object Y needs in the CML Model the keyword "hint" with a value conforming to
 * "ACL:EXPOSED_AGGREGATE_NAME" in order to tell the translator who X is.
 */
class AnticorruptionLayerGenerator {
	static val DATA_FACTORY = DataFactory.eINSTANCE
	
	/**
	 * Mapped LEMMA {@link DataModel} which contains all {@link Context}s
	 */
	private DataModel dataModel

	/**
	 * Mapped LEMMA DML {@link Context} which receives an Translator
	 */
	private Context context

	/**
	 * Context Map of the CML Model which contains  ACL-relations of the LEMMA DML {@value context}. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the Context Map in order to map them.
	 */
	private ContextMap map

	private List<String> errors

	new(Context context, DataModel dataModel, ContextMap map, List<String> errors) {
		this.dataModel = dataModel
		this.context = context
		this.map = map
		this.errors = errors
	}

	def mapAcl() {
		// Relationships in which the LEMMA context is the downstream context and the relationship is an ACL
		val rr = filter()
		if (rr.size == 0) {
			return
		}

		// CML Bounded Context. Get any downstream of the rr-Array since all are the same
		val cmlDownstreamContext = (rr.get(0) as UpstreamDownstreamRelationship).downstream

		val translators = <DataStructure>newLinkedList

		rr.stream.forEach([ rel |
			val cmlUpstreamContext = (rel as UpstreamDownstreamRelationship).upstream
			// Filter the matching LEMMA context. Use findAny because only one will be found at most
			val lemmaUpstreamContext = this.dataModel.contexts.stream.filter([ctx | ctx.name.equals(cmlUpstreamContext.name)]).findAny() 
			if (lemmaUpstreamContext.empty) {
				this.errors.add('''Mapping Error: A Mapping of the CML context «cmlUpstreamContext.name» was not found.''')
				return
			}
			
			cmlDownstreamContext.aggregates.stream.flatMap([agg|agg.domainObjects.stream]) // put all domain objects of all aggregates in one stream
			.filter([obj|obj.hint !== null && obj.hint.startsWith(DownstreamRole.ANTICORRUPTION_LAYER.literal + ":")]) // domain object has a hint starting with "ACL:"
			.map([ obj | // remove "ACL:" prefix => we get the desired source aggregate (X)
				obj.hint = obj.hint.replace(DownstreamRole.ANTICORRUPTION_LAYER.literal + ":", "")
				return obj
			]).map([ obj | // check if the aggregate provided by the hint keyword is an exposed aggregate of the relationship (semantic error checking)
				var check = false
				for (exposedAgg : (rel as UpstreamDownstreamRelationship).upstreamExposedAggregates) {
					if (exposedAgg.name.equals(obj.hint)) {
						// If the aggregate exists, it is also in the LEMMA dataModel because the aggregate must have
						// been mapped by the LemmaDomainDataModelFactory previously. Therefore the next steps
						// will use the LEMMA Domain Objects in order to work with the already mapped types.
						// Find X in the LEMMA upstream context and Y in the LEMMA downstream context and put them in a container object
						val x = lemmaUpstreamContext.get.complexTypes.stream.filter([cType| cType.name.equals(exposedAgg.name)]).findAny.get
						val y = this.context.complexTypes.stream.filter([cType| cType.name.equals(obj.name)]).findAny.get
						return new FromTo(x as DataStructure, y as DataStructure)
					}
				}

				if (!check) {
					this.errors.add(obj.hint + " is not an exposed aggregate")
				}

				return null
			]).filter([fromTo|fromTo !== null]) // ignore null values from errors => we get the FromTo-Objects
			.forEach([ fromTo |
				// Finally create the translator which represents the ACL implementation
				val aclTranslator = DATA_FACTORY.createDataStructure
				aclTranslator.name = fromTo.source.name + "Translator"
				aclTranslator.features.add(ComplexTypeFeature.DOMAIN_SERVICE)
				
				// Translation operation of the translator
				val opParam = DATA_FACTORY.createDataOperationParameter
				opParam.name = String.valueOf(fromTo.source.name.charAt(0)).toLowerCase
				opParam.complexType = fromTo.source
				val op = DATA_FACTORY.createDataOperation
				op.name = '''transform«fromTo.source.name»To«fromTo.target.name»'''
				op.complexReturnType = EcoreUtil.copy(fromTo.target)
				op.parameters.add(opParam)
				
				// Add operation to the translator DataStructure
				aclTranslator.operations.add(op)
				
				// Add translator into the LEMMA Context
				this.context.complexTypes.add(aclTranslator)
			])
		]);
	}

	/**
	 * Filter the context maps where the {@value context} is the downstream context since an ACL is placed in a downstream context
	 */
	private def filter() {
		return map.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstream.name.equals(context.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstreamRoles.contains(DownstreamRole.ANTICORRUPTION_LAYER)
		]).collect(Collectors.toList())
	}

	/**
	 * Container class that contains X and Y (see class description)
	 * source = X
	 * target = Y
	 */
	@Data static class FromTo {
		protected DataStructure source
		protected DataStructure target
	}
}
