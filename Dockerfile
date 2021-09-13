FROM ruby:2

WORKDIR /usr/src/app

RUN adduser --system --group ruby && mkdir -p /usr/local/gems /usr/src/app/tmp/log && chown -R ruby /usr/local/gems /usr/src/app

COPY --chown=ruby  ["Procfile","Gemfile*","config.ru", "/usr/src/app/"]
COPY --chown=ruby lib/ /usr/src/app/lib/

ENV GEM_HOME=/usr/local/gems
EXPOSE 5000

RUN bundle update --bundler && \
    bundle install && chmod -R a-w /usr/src/app

USER ruby

CMD ["bundle", "exec", "foreman", "start"]
