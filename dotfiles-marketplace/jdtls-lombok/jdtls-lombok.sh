#!/bin/bash
# Wrapper script for jdtls that adds Lombok as a javaagent
# This allows JDTLS to understand Lombok-generated code (getters, builders, etc.)
export _JAVA_OPTIONS="-javaagent:$HOME/.m2/repository/org/projectlombok/lombok/1.18.42/lombok-1.18.42.jar"
exec jdtls "$@"
