FROM ruby:2.7-bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    git \
    graphviz \
    imagemagick \
    less \
    liblzma-dev \
    libxml2 \
    libxml2-dev \
    libxslt-dev \
    mariadb-client \
    nodejs \
    npm \
    pkg-config \
    shared-mime-info \
    zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.2.16

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --global without production \
  && bundle install --jobs=8 --retry=3

ENV PATH="/app/dev/docker/bin:/app/bin:${PATH}"
EXPOSE 3000

CMD ["sleep", "infinity"]
