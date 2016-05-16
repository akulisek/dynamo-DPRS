# Consul
#
# VERSION 0.1

FROM progrium/consul
MAINTAINER Adam Kulisek <akulisek@gmail.com>

ADD config_updater.rb /usr/bin/config_updater.rb
RUN chmod +x /usr/bin/config_updater.rb

ADD config_notifier.rb /usr/bin/config_notifier.rb
RUN chmod +x /usr/bin/config_notifier.rb

ADD unregister.sh /usr/bin/unregister.sh
RUN chmod 777 /usr/bin/unregister.sh

ADD unregister.sh /usr/bin/initScript.sh
RUN chmod 777 /usr/bin/initScript.sh

RUN apk update && apk upgrade && apk --update add ruby ruby-json
