package de.fhdo.lemma.cml_transformer.factory.intermediate;

import org.contextmapper.tactic.dsl.tacticdsl.ComplexType;
import org.contextmapper.tactic.dsl.tacticdsl.Parameter;
import org.eclipse.emf.common.util.EList;
import org.eclipse.xtend.lib.annotations.Data;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

@Data
@SuppressWarnings("all")
public class CmlOperation {
  private final String name;
  
  private final ComplexType returnType;
  
  private final EList<Parameter> parameters;
  
  public CmlOperation(final String name, final ComplexType returnType, final EList<Parameter> parameters) {
    super();
    this.name = name;
    this.returnType = returnType;
    this.parameters = parameters;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + ((this.name== null) ? 0 : this.name.hashCode());
    result = prime * result + ((this.returnType== null) ? 0 : this.returnType.hashCode());
    return prime * result + ((this.parameters== null) ? 0 : this.parameters.hashCode());
  }
  
  @Override
  @Pure
  public boolean equals(final Object obj) {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (getClass() != obj.getClass())
      return false;
    CmlOperation other = (CmlOperation) obj;
    if (this.name == null) {
      if (other.name != null)
        return false;
    } else if (!this.name.equals(other.name))
      return false;
    if (this.returnType == null) {
      if (other.returnType != null)
        return false;
    } else if (!this.returnType.equals(other.returnType))
      return false;
    if (this.parameters == null) {
      if (other.parameters != null)
        return false;
    } else if (!this.parameters.equals(other.parameters))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("name", this.name);
    b.add("returnType", this.returnType);
    b.add("parameters", this.parameters);
    return b.toString();
  }
  
  @Pure
  public String getName() {
    return this.name;
  }
  
  @Pure
  public ComplexType getReturnType() {
    return this.returnType;
  }
  
  @Pure
  public EList<Parameter> getParameters() {
    return this.parameters;
  }
}
