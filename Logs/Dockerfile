FROM willdurand/elk:kibana-4.4.2

ADD ./logstash.conf /etc/logstash/logstash.conf

ADD starter.sh /tmp/starter.sh
ADD starter.conf /etc/supervisor/conf.d/starter.conf

RUN chmod 777 /tmp/starter.sh

EXPOSE 5000