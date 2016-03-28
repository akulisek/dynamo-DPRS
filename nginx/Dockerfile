FROM nginx:latest
EXPOSE 80
ARG CONSUL
ENV CON_IP=$CONSUL

ENV CONSUL_URL $CON_IP:8500
RUN rm -v /etc/nginx/conf.d/default.conf

ADD consul-template /usr/bin/

ADD start.sh /bin/start.sh
ADD templates/service.ctmpl /templates/

RUN service nginx start
CMD /bin/sh