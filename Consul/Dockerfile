FROM progrium/consul

ADD config_updater.rb /usr/bin/config_updater.rb
RUN chmod +x /usr/bin/config_updater.rb

ADD config_notifier.rb /usr/bin/config_notifier.rb
RUN chmod +x /usr/bin/config_notifier.rb

RUN apk update && apk upgrade && apk --update add ruby ruby-json



