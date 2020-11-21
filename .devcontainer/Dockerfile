ARG VARIANT=latest
FROM elixir:${VARIANT}

RUN apt-get update && \
    apt-get install -y inotify-tools && \
    apt-get install -y nodejs && \
    apt-get install -y git && \
    mix local.hex --force && \
    mix archive.install hex phx_new ${PHX_VERSION} --force && \
    mix local.rebar --force

# Default powerline10k theme, no plugins installed
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.1/zsh-in-docker.sh)"

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

EXPOSE 4000
