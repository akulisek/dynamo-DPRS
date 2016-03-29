FROM willdurand/elk:kibana-4.4.2

ADD ./logstash.conf /etc/logstash/logstash.conf

ADD starter.sh /tmp/starter.sh
ADD starter.conf /etc/supervisor/conf.d/starter.conf

EXPOSE 5000