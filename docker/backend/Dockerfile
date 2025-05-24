FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app
COPY . .
RUN ./gradlew clean bootJar -x test

FROM eclipse-temurin:21-jdk
WORKDIR /app
RUN mkdir -p /var/log/moongsan && chown -R 1000:1000 /var/log/moongsan
COPY --from=builder /app/build/libs/*.jar app.jar
CMD ["sh", "-c", "java -jar app.jar | tee -a /var/log/moongsan/be_moongsan.log"]