# Base image
FROM ruby:latest

RUN apt-get update
RUN apt-get -y -q install rsyslog
ADD test.conf /etc/rsyslog.d/test.conf

ENV HOME /home/rails/webapp

# Install PGsql dependencies and js engine
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

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
