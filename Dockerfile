

FROM openjdk:17-jdk-slim as builder
WORKDIR /app
COPY pom.xml .
COPY src ./src

# Install Maven

RUN apt-get update && apt-get install -y maven

# Build the application

RUN mvn clean package -DskipTests

# Runtime stage

FROM eclipse-temurin:17-jre-focal
WORKDIR /app

# Create non-root user

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copy the built JAR

COPY --from=builder /app/target/java-api-0.0.1-SNAPSHOT.jar app.jar

# Change ownership

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]