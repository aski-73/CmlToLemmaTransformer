package de.fhdo.lemma.cml_transformer.factory.context_map

import de.fhdo.lemma.data.Context
import org.contextmapper.dsl.contextMappingDSL.ContextMap
import org.contextmapper.dsl.contextMappingDSL.Relationship
import java.util.List
import de.fhdo.lemma.data.DataModel

/**
 * Generalizes Attributes for implementations of Context Map relations
 */
abstract class AbstractRelationshipGenerator {
	/**
	 * Mapped LEMMA DML {@link Context} which receives the relationship implementation
	 */
	protected Context targetCtx
	
		
	/**
	 * All instantiated LEMMA DataModels so far
	 */
	protected List<DataModel> mappedDataModels

	/**
	 * Context Map of the CML Model which contains  the required relationshipsof the LEMMA DML {@value context}. The {@link Context} must have the same name
	 * as the {@link BoundedContext} in the Context Map in order to map them.
	 */
	protected ContextMap inputMap

	new(Context context, ContextMap map, List<DataModel> dataModels) {
		this.targetCtx = context
		this.inputMap = map
		this.mappedDataModels = dataModels
	}
	
	protected def abstract List<Relationship> filter()
	
	def abstract void map()
}
