# Flutter 3.47.2 / Dart 3.13.2 matches this project's SDK constraint and
# .metadata revision d3b14c876900e553bc736ca19295fc09e3853e8e.
# The runtime image serves only the Flutter web release. Android and iOS
# toolchains are not installed and those project folders are not used.

FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_VERSION=3.47.2 \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/flutter/.pub-cache \
    PATH="/opt/flutter/bin:/home/flutter/.pub-cache/bin:${PATH}" \
    CI=true

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash flutter

RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && chown -R flutter:flutter /opt/flutter \
    && mkdir -p /app \
    && chown flutter:flutter /app

USER flutter

RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web

WORKDIR /app

COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY --chown=flutter:flutter . .

# Railway supplies this as a Docker build arg. Empty keeps the app's compiled default.
ARG API_BASE_URL=
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"; \
    else \
      flutter build web --release; \
    fi \
    && test -s build/web/index.html \
    && test -s build/web/main.dart.js

FROM nginx:1.28-alpine AS runtime

ENV PORT=8080

RUN rm -f /etc/nginx/conf.d/default.conf

COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
