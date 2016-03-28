FROM nginx:latest
EXPOSE 80
ARG CONSUL
ENV CON_IP=$CONSUL

ENV CONSUL_URL $CON_IP:8500
RUN rm -v /etc/nginx/conf.d/default.conf

ADD https://github.com/hashicorp/consul-template/releases/download/v0.7.0/consul-template_0.7.0_linux_amd64.tar.gz /usr/bin/
RUN tar -C /usr/local/bin --strip-components 1 -zxf /usr/bin/consul-template_0.7.0_linux_amd64.tar.gz

ADD start.sh /bin/start.sh
ADD templates/service.ctmpl /templates/

RUN service nginx start
CMD /bin/sh