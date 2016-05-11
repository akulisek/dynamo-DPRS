# Base image
FROM ruby:latest

RUN apt-get update
RUN apt-get -y -q install rsyslog
ADD test.conf /etc/rsyslog.d/test.conf

ENV HOME /home/rails/webapp

EXPOSE 8080
EXPOSE 514/tcp 514/udp

# Install PGsql dependencies and js engine
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs && apt-get install net-tools

# Set Rails to run in production
ENV RAILS_ENV production
ENV RACK_ENV production

WORKDIR $HOME

# Install gems
ADD Gemfile* $HOME/
RUN bundle install

# Add the app code
ADD . $HOME

WORKDIR /etc/

ADD starter.sh starter.sh
RUN chmod 777 starter.sh

CMD sh starter.sh
