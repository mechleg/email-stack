FROM nginx:alpine
LABEL maintainer="mechleg <mechleg@mechleg.com>"

ARG SERVERNAME
ARG DOMAIN
ARG DOMAIN2

COPY roundcube.conf.tmpl /etc/nginx/conf.d/${DOMAIN}.conf
COPY roundcube.conf.tmpl /etc/nginx/conf.d/${DOMAIN2}.conf
RUN sed -i -e "s/\${SERVERNAME}/${SERVERNAME}.${DOMAIN}/g" /etc/nginx/conf.d/${DOMAIN}.conf \
 && sed -i -e "s/\${SERVERNAME}/${SERVERNAME}.${DOMAIN2}/g" /etc/nginx/conf.d/${DOMAIN2}.conf
EXPOSE 443

VOLUME /var/lib/roundcube
