# syntax=docker/dockerfile:1
FROM alpine:3.14
RUN apk -i update && apk -i add apache2
COPY index.html /var/www/localhost/htdocs
