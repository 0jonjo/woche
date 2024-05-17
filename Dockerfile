FROM bash:latest

RUN mkdir /home/root/

RUN apk add --no-cache coreutils

WORKDIR /woche

COPY . /woche
