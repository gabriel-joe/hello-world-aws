FROM gradle:jdk21 as builder
WORKDIR /app
COPY . ./
RUN gradle clean build
FROM amazoncorretto:21 as runner
WORKDIR /app
COPY --from=builder /app/build/libs/hello-world-aws-*.jar ./app.jar
CMD ["java", "-jar", "app.jar"]