# Build image
FROM swift:4.1 as builder
RUN apt-get -qq update && apt-get -q -y install \
  libmysqlclient-dev \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

# Production image
FROM ubuntu:16.04

RUN apt-get -qq update && apt-get install -y \
  libicu55 libxml2 libbsd0 libcurl3 libatomic1 \
  tzdata \
  libmysqlclient20 \
  cron vim \
  && rm -r /var/lib/apt/lists/*

COPY crontab /etc/cron.d/jp-cronjobs

RUN chmod 0644 /etc/cron.d/jp-cronjobs

WORKDIR /app

COPY --from=builder /build/bin/Run .
COPY --from=builder /build/lib/* /usr/lib/
COPY .prod.env .
COPY crontab_update_youtube_videos.sh .
COPY docker-entrypoint.sh .

RUN mkdir /app/images

EXPOSE 8080

ENTRYPOINT ["/app/docker-entrypoint.sh"]