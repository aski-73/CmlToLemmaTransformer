package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.cml_transformer.factory.LemmaDomainDataModelFactory
import de.fhdo.lemma.data.Context
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.BoundedContext
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship

/**
 * Implements the Conformist relationship by inserting the exposed aggregates of the upstream context into the domain
 * of the downstream context.
 */
class ConformistGenerator {
	/**
	 * CML Model that contains a context Map of the CML Model. Itcontains  ACL-relations of the LEMMA DML {@value context}. 
	 * The {@link Context} must have the same name as the {@link BoundedContext} in the Context Map in order to map them.
	 */
	private ContextMappingModel cmlModel

	/**
	 * Mapped LEMMA DML {@link Context} which receives an Translator
	 */
	private Context context

	private LemmaDomainDataModelFactory dmlFactory

	new(Context context, ContextMappingModel cmlModel, LemmaDomainDataModelFactory dmlFactory) {
		this.context = context
		this.cmlModel = cmlModel
		this.dmlFactory = dmlFactory
	}

	/**
	 * Creates new domain objects (Data Modeling Language) for every exposed aggregate of the upstream context in the downstream context
	 */
	def mapCof() {
		// Relationships in which targetBc is the downstream context and the relationship is a CF
		val rr = filter()
		if (rr.size == 0) {
			return
		}

		rr.stream.forEach([ rel |
			// Copy each domain object of the exposed aggregate into the downstream context. This is done
			// by using the LEMMADomainDataModelFactory. The factory creates new instances of DataStructures 
			// and also tells which ListTypes are used.
			(rel as UpstreamDownstreamRelationship).upstreamExposedAggregates.stream.forEach([ agg |
				val cTypes = LemmaDomainDataModelFactory.mapAggregate2ComplexType(cmlModel, agg)
				this.context.complexTypes.addAll(cTypes)
				this.context.complexTypes.addAll(this.dmlFactory.listsToGenerate)
			])
		])
	}

	/**
	 * Filter the context maps where the targetBc is the downstream context since a Conformist is placed in a downstream context and the context mapping is CF
	 */
	private def filter() {
		return cmlModel.map.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstream.name.equals(context.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstreamRoles.contains(DownstreamRole.CONFORMIST)
		]).collect(Collectors.toList())
	}
}
