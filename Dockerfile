FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG HARMONIX_API_BASE_URL=https://sonora.mhemery.fr
RUN flutter build web --release \
    --dart-define=HARMONIX_API_BASE_URL=${HARMONIX_API_BASE_URL} \
    && cp web/flutter_service_worker.js build/web/flutter_service_worker.js

FROM busybox:1.37.0-musl

COPY --from=builder /app/build/web /www

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

CMD ["httpd", "-f", "-p", "80", "-h", "/www"]
