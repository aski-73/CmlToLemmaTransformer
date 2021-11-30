package de.fhdo.lemma.cml_transformer;

import de.fhdo.lemma.model_processing.annotations.LanguageDescriptionProvider;
import de.fhdo.lemma.model_processing.languages.LanguageDescription;
import de.fhdo.lemma.model_processing.languages.LanguageDescriptionProviderI;
import de.fhdo.lemma.model_processing.languages.XtextLanguageDescription;
import org.contextmapper.dsl.ContextMappingDSLStandaloneSetup;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingDSLPackage;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * At runtime, a language
 * description provider informs the model processing framework about the modeling languages of the input models to
 * process. Among others, these information allow the framework to parse the input models and hide the related
 * complexity from the model processor implementer.
 */
@LanguageDescriptionProvider
@SuppressWarnings("all")
public class LanguageDescriptions implements LanguageDescriptionProviderI {
  /**
   * The {@link de.fhdo.lemma.model_processing.languages.LanguageDescriptionProviderI} interface defines the{@link de.fhdo.lemma.model_processing.languages.LanguageDescriptionProviderI#getLanguageDescription} method. At
   * runtime, the model processing framework invokes the method with a namespace (for XMI-based models) or file
   * extension (for models that do not contain directly extractable information about their namespace, e.g.,
   * Xtext-based models in their textual form) that identify an Eclipse-based modeling language. The flags{@code forLanguageNamespace} and {@code forFileExtension} flags inform model processors about whether the{@code languageNamespaceOrFileExtension} parameter contains a namespace or file extension. The model processing
   * framework then expects the{@link de.fhdo.lemma.model_processing.languages.LanguageDescriptionProviderI#getLanguageDescription} method to
   * return an instance of {@link de.fhdo.lemma.model_processing.languages.LanguageDescription}, which comprises all
   * relevant information for the framework to, e.g., parse an input model.
   */
  @Nullable
  @Override
  public LanguageDescription getLanguageDescription(final boolean forLanguageNamespace, final boolean forFileExtension, @NotNull final String languageNamespaceOrFileExtension) {
    if (languageNamespaceOrFileExtension != null) {
      switch (languageNamespaceOrFileExtension) {
        case "cml":
          ContextMappingDSLStandaloneSetup _contextMappingDSLStandaloneSetup = new ContextMappingDSLStandaloneSetup();
          return new XtextLanguageDescription(ContextMappingDSLPackage.eINSTANCE, _contextMappingDSLStandaloneSetup);
        default:
          return null;
      }
    } else {
      return null;
    }
  }
}
