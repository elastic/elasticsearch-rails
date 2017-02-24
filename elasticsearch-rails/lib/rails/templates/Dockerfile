# docker build --tag searchapp-01 --build-arg PATH_TO_APPLICATION=searchapp-01 .

FROM ruby:2.3

MAINTAINER karmi@elastic.co

ARG PATH_TO_APPLICATION

RUN apt-get update && apt-get install --yes --fix-missing \
  build-essential \
  sqlite3 \
  libsqlite3-dev \
  nodejs

RUN mkdir -p /app
WORKDIR /app

COPY ${PATH_TO_APPLICATION}/Gemfile ${PATH_TO_APPLICATION}/Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 4 --retry 3

COPY ${PATH_TO_APPLICATION} ./

EXPOSE 3000

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true

RUN rm -f /app/tmp/pids/server.pid

CMD ["bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]
