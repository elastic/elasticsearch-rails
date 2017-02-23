FROM ruby:2.3

MAINTAINER karmi@elastic.co

RUN apt-get update && apt-get install --yes --fix-missing \
  build-essential

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 4 --retry 3

COPY . ./

EXPOSE 3000

CMD ["bundle", "exec", "thin", "--port", "3000", "--rackup", "config.ru", "start"]
