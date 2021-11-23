package de.fhdo.lemma.cml_transformer;

import com.google.common.base.Objects;
import de.fhdo.lemma.service.Import;
import de.fhdo.lemma.technology.Technology;
import java.util.List;

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
}
