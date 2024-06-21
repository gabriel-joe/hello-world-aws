FROM gradle:jdk21 as builder
WORKDIR /app
COPY . ./
RUN gradle clean build
ENV JAR_PATH=/app/build/libs/hello-world-aws-*.jar
FROM amazoncorretto:21 as runner
WORKDIR /app
COPY --from=builder $JAR_PATH app.jar
CMD ["java", "-jar", "app.jar"]