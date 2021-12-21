package de.fhdo.lemma.cml_transformer;

import com.google.common.base.Objects;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.service.Import;
import de.fhdo.lemma.technology.Technology;
import java.util.List;
import java.util.Optional;
import java.util.function.Predicate;
import org.eclipse.emf.ecore.util.EcoreUtil;

@SuppressWarnings("all")
public class Util {
  public static boolean technologyExists(final List<Technology> technologies, final Technology technology) {
    for (final Technology t : technologies) {
      boolean _equals = t.getName().equals(technology.getName());
      if (_equals) {
        return true;
      }
    }
    return false;
  }
  
  public static boolean importExists(final List<Import> imports, final Import im) {
    for (final Import tempIm : imports) {
      if ((Objects.equal(tempIm.getImportType(), im.getImportType()) && tempIm.getImportURI().equals(im.getImportURI()))) {
        return true;
      }
    }
    return false;
  }
  
  public static void addComplexTypesIntoContext(final Context targetCtx, final List<ComplexType> cTypes) {
    for (final ComplexType cType : cTypes) {
      {
        final Predicate<ComplexType> _function = (ComplexType checkMe) -> {
          return checkMe.getName().equals(cType.getName());
        };
        final Optional<ComplexType> checkComplexType = targetCtx.getComplexTypes().stream().filter(_function).findAny();
        boolean _isPresent = checkComplexType.isPresent();
        boolean _not = (!_isPresent);
        if (_not) {
          targetCtx.getComplexTypes().add(EcoreUtil.<ComplexType>copy(cType));
        }
      }
    }
  }
}
