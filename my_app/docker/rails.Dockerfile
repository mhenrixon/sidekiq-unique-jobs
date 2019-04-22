FROM ruby:2.3
MAINTAINER Mika Hel <mikael@zoolutions.se>

# ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base git libc-dev linux-headers
# ENV RUBY_PACKAGES ruby ruby-io-console openssl-dev postgresql-dev ruby-bundler libxml2-dev libxslt-dev

# RUN apk update \
#     && apk upgrade \
#     && apk add $BUILD_PACKAGES \
#     && apk add $RUBY_PACKAGES \
#     && rm -rf /var/cache/apk/* \
#     && mkdir -p /usr/src/app \
#     && bundle config --global jobs 8

# WORKDIR /usr/src/app

# COPY Gemfile /usr/src/app/
# COPY Gemfile.lock /usr/src/app/

# ENV BUNDLE_GEMFILE /usr/src/app/Gemfile
# ENV BUNDLE_JOBS 8
# ENV BUNDLE_RETRY 5
# ENV BUNDLE_PATH /usr/local/bundle

# RUN bundle install --jobs 8 --retry 5

# COPY . /usr/src/app
