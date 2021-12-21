package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.data.Context
import java.util.stream.Collectors
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import de.fhdo.lemma.cml_transformer.factory.DomainDataModelFactory
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import de.fhdo.lemma.data.ComplexType
import de.fhdo.lemma.cml_transformer.Util

/**
 * Implements the Conformist relationship by inserting the exposed aggregates of the upstream context into the domain
 * of the downstream context.
 */
class ConformistGenerator extends AbstractRelationshipGenerator {

	new(Context context, ContextMap map) {
		// provide empty list instead of already instantiated data models since this class does need them
		super(context, map, newLinkedList)
	}

	/**
	 * Creates new domain objects (Data Modeling Language) for every exposed aggregate of the upstream context in the downstream context
	 */
	override map() {
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
				val cTypes = DomainDataModelFactory.mapAggregateToComplexType(agg)
				Util.addComplexTypesIntoContext(targetCtx, cTypes)
			])
		])
	}

	/**
	 * Filter the context maps where the targetBc is the downstream context since a Conformist is placed in a downstream context and the context mapping is CF
	 */
	override filter() {
		return inputMap.relationships.stream.filter([rel|rel instanceof UpstreamDownstreamRelationship]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstream.name.equals(targetCtx.name)
		]).filter([ rel |
			(rel as UpstreamDownstreamRelationship).downstreamRoles.contains(DownstreamRole.CONFORMIST)
		]).collect(Collectors.toList())
	}
}
