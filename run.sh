#!/usr/bin/env bash

# Run the "build.sh" script before this script to ensure that the standalone JAR file exists.

# Make sure to run the following line with Java 11 or higher
java -jar build/libs/cml_transformer-standalone.jar \
  -s "./example models/cml/smallinsurance/small_insurance.cml" \
  -i "./example models/cml/smallinsurance/small_insurance.cml" \
  -t "/tmp/cml/"