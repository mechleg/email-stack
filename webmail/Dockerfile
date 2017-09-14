FROM nginx:alpine
LABEL maintainer="mechleg <mechleg@mechleg.com>"

ARG SERVERNAME
ARG DOMAIN

COPY roundcube.conf.tmpl /etc/nginx/conf.d/default.conf
RUN sed -i -e "s/\${SERVERNAME}/${SERVERNAME}.${DOMAIN}/g" /etc/nginx/conf.d/default.conf
EXPOSE 443

VOLUME /var/lib/roundcube
