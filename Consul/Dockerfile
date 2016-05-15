# Consul
#
# VERSION 0.1

FROM progrium/consul
MAINTAINER Adam Kulisek <akulisek@gmail.com>

ADD config_updater.rb /usr/bin/config_updater.rb
RUN chmod +x /usr/bin/config_updater.rb

RUN apk update && apk upgrade && apk --update add ruby ruby-json

ENV SOME_ENV_VAR 0.0.0.1

ADD config_notifier.rb /usr/bin/config_notifier.rb
RUN chmod +x /usr/bin/config_notifier.rb

RUN apk update && apk upgrade && apk --update add ruby ruby-json
