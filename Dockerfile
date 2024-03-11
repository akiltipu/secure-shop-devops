FROM openjdk:8u151-jdk-alpine3.7

EXPOSE 8070

COPY ./target/shopping-cart*.jar /usr/app/

WORKDIR /usr/app

CMD java -jar shopping-cart*.jar