FROM ubuntu:14.04

EXPOSE 80
ARG CONSUL
ENV CON_IP=$CONSUL

ENV CONSUL_URL $CON_IP:8500

ADD consul-template /usr/bin/
RUN chmod 777 /usr/bin/consul-template
RUN apt-get -y update && apt-get -y install \
  nginx-extras \
  ca-certificates
RUN apt-get install -y libossp-uuid-perl 
RUN rm -v /etc/nginx/sites-available/default
RUN rm -v /etc/nginx/sites-enabled/default

ADD start.sh /bin/start.sh
ADD templates/service.ctmpl /templates/

RUN service nginx start
CMD ["/bin/sh","/bin/start.sh"]
