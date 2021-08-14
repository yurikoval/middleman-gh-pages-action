FROM ruby:latest
ENV RUBYGEMS_VERSION=2.7.0
# Set default locale for the environment
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

LABEL "com.github.actions.name"="Middleman Github Pages Action"
LABEL "com.github.actions.description"="Deploying your Middleman repo to the gh-pages branch of the same repository"
LABEL "com.github.actions.icon"="box"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="http://github.com/yurikoval/middleman-gh-pages-action"

RUN apt-get update; \
  apt-get install -y --no-install-recommends nodejs

COPY pre-entrypoint.sh /pre-entrypoint.sh
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
