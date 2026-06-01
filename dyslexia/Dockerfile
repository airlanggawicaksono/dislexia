FROM ghcr.io/cirruslabs/flutter:3.41.6 AS build
WORKDIR /app
COPY . .
RUN flutter build web

FROM nginx:alpine AS nginx-base

FROM alpine:3.21
RUN apk add --no-cache pcre2 zlib && adduser -D -H -u 101 nginx
COPY --from=nginx-base /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-base /usr/lib/libssl.so.3 /usr/lib/libssl.so.3
COPY --from=nginx-base /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3
COPY --from=nginx-base /etc/nginx /etc/nginx
COPY --from=nginx-base /var/log/nginx /var/log/nginx
RUN rm -rf /etc/nginx/modules /etc/nginx/modules.conf && \
    sed -i '/load_module/d' /etc/nginx/nginx.conf && \
    mkdir -p /var/cache/nginx
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
