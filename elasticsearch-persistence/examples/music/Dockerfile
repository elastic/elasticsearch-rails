FROM ruby:2.3

MAINTAINER karmi@elastic.co

RUN apt-get update && apt-get install --yes --fix-missing \
  build-essential \
  nodejs

RUN mkdir -p /app
WORKDIR /app

COPY ./music/Gemfile ./music/Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 4 --retry 3

COPY ./music ./

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]

ENV RAILS_ENV=production

# ENV ELASTICSEARCH_URL=${ELASTICSEARCH_URL}

CMD ["rails", "server", "-p", "3000", "-b", "0.0.0.0"]
