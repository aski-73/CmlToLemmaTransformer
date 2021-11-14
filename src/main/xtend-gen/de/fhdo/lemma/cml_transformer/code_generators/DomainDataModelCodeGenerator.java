package de.fhdo.lemma.cml_transformer.code_generators;

import com.google.common.base.Objects;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataField;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.Enumeration;
import de.fhdo.lemma.data.EnumerationField;
import de.fhdo.lemma.data.ListType;
import de.fhdo.lemma.data.PrimitiveType;
import de.fhdo.lemma.data.PrimitiveValue;
import java.util.Arrays;
import java.util.function.Consumer;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.common.util.Enumerator;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.StringExtensions;

@SuppressWarnings("all")
public class DomainDataModelCodeGenerator {
  public static String printDataModel(final DataModel model) {
    final StringBuilder code = new StringBuilder();
    final Consumer<Context> _function = (Context ctx) -> {
      code.append(DomainDataModelCodeGenerator.printDataModelContext(ctx));
    };
    model.getContexts().forEach(_function);
    return code.toString();
  }
  
  private static String printDataModelContext(final Context context) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("context ");
    String _name = context.getName();
    _builder.append(_name);
    _builder.append(" {\t");
    _builder.newLineIfNotEmpty();
    {
      EList<ComplexType> _complexTypes = context.getComplexTypes();
      for(final ComplexType complexType : _complexTypes) {
        _builder.append("\t");
        String _printDataModelComplexType = DomainDataModelCodeGenerator.printDataModelComplexType(complexType);
        _builder.append(_printDataModelComplexType, "\t");
        _builder.newLineIfNotEmpty();
      }
    }
    _builder.append("}");
    _builder.newLine();
    final String text = _builder.toString();
    return text;
  }
  
  /**
   * Generates LEMMA DML {@link DataStructure} (Value Objects, Entities etc.)
   */
  private static String _printDataModelComplexType(final DataStructure structure) {
    int _size = structure.getOperations().size();
    boolean setFieldOperationSeparator = (_size > 0);
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("\t\t\t\t\t\t\t\t\t");
    _builder.newLine();
    _builder.append("structure ");
    String _name = structure.getName();
    _builder.append(_name);
    _builder.append(" ");
    String _printFeatures = DomainDataModelCodeGenerator.printFeatures(structure.getFeatures());
    _builder.append(_printFeatures);
    _builder.append(" {");
    _builder.newLineIfNotEmpty();
    {
      EList<DataField> _dataFields = structure.getDataFields();
      boolean _hasElements = false;
      for(final DataField field : _dataFields) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(",", "\t");
        }
        _builder.append("\t");
        String _determineConcreteType = DomainDataModelCodeGenerator.determineConcreteType(field);
        _builder.append(_determineConcreteType, "\t");
        _builder.append(" ");
        String _name_1 = field.getName();
        _builder.append(_name_1, "\t");
        _builder.append(" ");
        String _printFeatures_1 = DomainDataModelCodeGenerator.printFeatures(field.getFeatures());
        _builder.append(_printFeatures_1, "\t");
        _builder.newLineIfNotEmpty();
      }
    }
    _builder.append("\t");
    {
      if (setFieldOperationSeparator) {
        _builder.append(",");
      }
    }
    _builder.newLineIfNotEmpty();
    {
      EList<DataOperation> _operations = structure.getOperations();
      boolean _hasElements_1 = false;
      for(final DataOperation op : _operations) {
        if (!_hasElements_1) {
          _hasElements_1 = true;
        } else {
          _builder.appendImmediate(",", "\t");
        }
        _builder.append("\t");
        {
          boolean _isHasNoReturnType = op.isHasNoReturnType();
          if (_isHasNoReturnType) {
            _builder.append("procedure");
          } else {
            _builder.append("function ");
            String _string = op.getPrimitiveOrComplexReturnType().toString();
            _builder.append(_string, "\t");
          }
        }
        _builder.append(" ");
        String _name_2 = op.getName();
        _builder.append(_name_2, "\t");
        _builder.append(" (");
        _builder.newLineIfNotEmpty();
        _builder.append("\t");
        _builder.append("\t");
        {
          EList<DataOperationParameter> _parameters = op.getParameters();
          boolean _hasElements_2 = false;
          for(final DataOperationParameter param : _parameters) {
            if (!_hasElements_2) {
              _hasElements_2 = true;
            } else {
              _builder.appendImmediate(",", "\t\t");
            }
            String _determineConcreteType_1 = DomainDataModelCodeGenerator.determineConcreteType(param);
            _builder.append(_determineConcreteType_1, "\t\t");
            _builder.append(" ");
            String _name_3 = param.getName();
            _builder.append(_name_3, "\t\t");
          }
        }
        _builder.newLineIfNotEmpty();
        _builder.append("\t");
        _builder.append(")");
        _builder.newLine();
      }
    }
    _builder.append("}");
    _builder.newLine();
    return _builder.toString();
  }
  
  /**
   * Generates LEMMA DML {@link ListType} (Lists)
   */
  private static String _printDataModelComplexType(final ListType listType) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("list ");
    String _name = listType.getName();
    _builder.append(_name);
    _builder.append("List { ");
    String _name_1 = listType.getName();
    _builder.append(_name_1);
    _builder.append(" ");
    char _charAt = StringExtensions.toFirstLower(listType.getName()).charAt(0);
    _builder.append(_charAt);
    _builder.append(" }");
    _builder.newLineIfNotEmpty();
    return _builder.toString();
  }
  
  /**
   * Generates LEMMA DML {@link Enumeration} (Enums)
   */
  private static String _printDataModelComplexType(final Enumeration enumeration) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("enum ");
    String _name = enumeration.getName();
    _builder.append(_name);
    _builder.append(" {");
    _builder.newLineIfNotEmpty();
    {
      EList<EnumerationField> _fields = enumeration.getFields();
      boolean _hasElements = false;
      for(final EnumerationField enumField : _fields) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(",", "\t");
        }
        _builder.append("\t");
        String _name_1 = enumField.getName();
        _builder.append(_name_1, "\t");
        {
          PrimitiveValue _initializationValue = enumField.getInitializationValue();
          boolean _notEquals = (!Objects.equal(_initializationValue, null));
          if (_notEquals) {
            _builder.append("(");
            PrimitiveValue _initializationValue_1 = enumField.getInitializationValue();
            _builder.append(_initializationValue_1, "\t");
            _builder.append(")");
          }
        }
        _builder.newLineIfNotEmpty();
      }
    }
    _builder.append("}");
    _builder.newLine();
    return _builder.toString();
  }
  
  /**
   * Returns LEMMA DML Features {@link ComplexTypeFeature}, {@link DataOperationFeature} and {@link DataFieldFeature}
   */
  private static String printFeatures(final EList<? extends Enumerator> features) {
    String _xifexpression = null;
    int _size = features.size();
    boolean _greaterThan = (_size > 0);
    if (_greaterThan) {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("<");
      {
        boolean _hasElements = false;
        for(final Enumerator feat : features) {
          if (!_hasElements) {
            _hasElements = true;
          } else {
            _builder.appendImmediate(", ", "");
          }
          String _transformFeatureToCamelCase = DomainDataModelCodeGenerator.transformFeatureToCamelCase(feat);
          _builder.append(_transformFeatureToCamelCase);
        }
      }
      _builder.append(">");
      _xifexpression = _builder.toString();
    } else {
      _xifexpression = "";
    }
    return _xifexpression;
  }
  
  /**
   * Since {@link Type} has no general method to tell its concrete type we need helper methods.
   * This one is for {@link DataField}
   */
  private static String determineConcreteType(final DataField field) {
    String _xifexpression = null;
    ComplexType _complexType = field.getComplexType();
    boolean _notEquals = (!Objects.equal(_complexType, null));
    if (_notEquals) {
      _xifexpression = field.getComplexType().getName();
    } else {
      String _xifexpression_1 = null;
      PrimitiveType _primitiveType = field.getPrimitiveType();
      boolean _notEquals_1 = (!Objects.equal(_primitiveType, null));
      if (_notEquals_1) {
        _xifexpression_1 = field.getPrimitiveType().getTypeName();
      } else {
        _xifexpression_1 = "notDetermined";
      }
      _xifexpression = _xifexpression_1;
    }
    return _xifexpression;
  }
  
  /**
   * Since {@link Type} has no general method to tell its concrete type we need helper methods.
   * This one is for {@link DataOperationParameter}
   */
  private static String determineConcreteType(final DataOperationParameter param) {
    String _xifexpression = null;
    ComplexType _complexType = param.getComplexType();
    boolean _notEquals = (!Objects.equal(_complexType, null));
    if (_notEquals) {
      _xifexpression = param.getComplexType().getName();
    } else {
      String _xifexpression_1 = null;
      PrimitiveType _primitiveType = param.getPrimitiveType();
      boolean _notEquals_1 = (!Objects.equal(_primitiveType, null));
      if (_notEquals_1) {
        _xifexpression_1 = param.getPrimitiveType().getTypeName();
      } else {
        _xifexpression_1 = "notDetermined";
      }
      _xifexpression = _xifexpression_1;
    }
    return _xifexpression;
  }
  
  /**
   * value_object => valueObject etc.
   */
  private static String transformFeatureToCamelCase(final Enumerator enumValue) {
    final String s = enumValue.getName().toLowerCase();
    final StringBuilder newS = new StringBuilder();
    boolean makeNextCharUpperCase = false;
    for (int i = 0; (i < s.length()); i++) {
      char _charAt = s.charAt(i);
      boolean _equals = (((byte) _charAt) == 95);
      if (_equals) {
        makeNextCharUpperCase = true;
      } else {
        if (makeNextCharUpperCase) {
          newS.append(String.valueOf(s.charAt(i)).toUpperCase());
          makeNextCharUpperCase = false;
        } else {
          newS.append(s.charAt(i));
        }
      }
    }
    return newS.toString();
  }
  
  private static String printDataModelComplexType(final ComplexType structure) {
    if (structure instanceof DataStructure) {
      return _printDataModelComplexType((DataStructure)structure);
    } else if (structure instanceof Enumeration) {
      return _printDataModelComplexType((Enumeration)structure);
    } else if (structure instanceof ListType) {
      return _printDataModelComplexType((ListType)structure);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(structure).toString());
    }
  }
}
