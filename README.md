# About

This project aims to incorporate the [DDD](https://martinfowler.com/bliki/DomainDrivenDesign.html) strategic design 
to [LEMMA](https://seelabfhdo.github.io/lemma-docs/) by transforming [CML](https://contextmapper.org/) models 
to various LEMMA models.
This repository provides a model-to-model transformer, CmlToLemmaTransformer, and uses code extractors for code generation.

# Prerequisite

You need [Java 11](https://adoptopenjdk.net/)

# How to use

Clone project and change directory.

``
git clone https://github.com/aski-73/CmlToLemmaTransformer.git
``

``
cd CmlToLemmaTransformer
``

Run the build.sh in order to build a .jar file.

``
./build.sh
``

In order to run the transformer, execute the run.sh file.

``
./run.sh
``

By inspecting the run.sh you'll see that the transformer takes 2 inputs:
- the CML model that should be transformed
- an outputfolder

By default it takes the example cml model residing in [here](https://github.com/aski-73/CmlToLemmaTransformer/tree/main/example%20models/cml/smallinsurance/) 
and puts the generated LEMMA models in the directory "generated code" in your working directory (will be generated if not existing yet).



