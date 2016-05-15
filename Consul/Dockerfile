# Consul
#
# VERSION 0.1

FROM progrium/consul
MAINTAINER Adam Kulisek <akulisek@gmail.com>

ADD config_notifier.rb /usr/bin/config_notifier.rb
RUN chmod +x /usr/bin/config_notifier.rb

RUN apk update && apk upgrade && apk --update add ruby ruby-json

ENV SOME_ENV_VAR 0.0.0.1

LABEL Description="This image is used to start ..."

RUN apt-get update -qq && apt-get -y install curl
