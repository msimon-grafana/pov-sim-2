# Step 1: Use an official Gradle image to build the application
FROM gradle:8.3.0-jdk17 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the entire project to the container
COPY . .

# Build the application
RUN gradle clean bootJar

# Step 2: Use a Temurin runtime image that is available on Apple Silicon too
FROM eclipse-temurin:17-jre-jammy

# Set the working directory for the runtime container
WORKDIR /app

ARG PYROSCOPE_JAVA_AGENT_VERSION=2.5.1

# Copy the JAR file from the build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Expose the port the application runs on
EXPOSE 8080
# download the OTel JAR for java instrumentation
ADD --chmod=644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar /app/opentelemetry-javaagent.jar
# download the Pyroscope Java agent from Maven Central
ADD --chmod=644 https://repo1.maven.org/maven2/io/pyroscope/agent/${PYROSCOPE_JAVA_AGENT_VERSION}/agent-${PYROSCOPE_JAVA_AGENT_VERSION}.jar /app/pyroscope.jar

# Enable both OTEL tracing and Pyroscope profiling. The extra JVM flags are
# recommended for more accurate async-profiler stack traces.
ENV JAVA_TOOL_OPTIONS="-javaagent:/app/opentelemetry-javaagent.jar -javaagent:/app/pyroscope.jar -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints"


# Set the command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
