FROM ruby:2.7-slim

LABEL "com.github.actions.name"="Middleman Github Pages Action"
LABEL "com.github.actions.description"="Deploying your Middleman repo to the gh-pages branch of the same repository"
LABEL "com.github.actions.icon"="box"
LABEL "com.github.actions.color"="teal"

LABEL "repository"="http://github.com/zooniverse/middleman-gh-pages-action"

RUN apt-get update; \
    apt-get install -y --no-install-recommends git nodejs && \
    apt-get clean && rm -fr /var/lib/apt/lists/*


ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
