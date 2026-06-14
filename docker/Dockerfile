# Generic runtime image for the Spring Petclinic microservices.
#
# The JAR is built ahead of time with Maven (see scripts/build-and-push.sh) and
# passed in via the JAR_FILE build argument. The base image is multi-arch, so
# `docker buildx --platform linux/arm64` produces a Graviton-compatible image.
FROM eclipse-temurin:17

ARG JAR_FILE

WORKDIR /app

COPY ${JAR_FILE} app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
