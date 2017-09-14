FROM nginx:alpine
LABEL maintainer="mechleg <mechleg@mechleg.com>"

ARG SERVERNAME
ARG DOMAIN

COPY roundcube.conf.tmpl /etc/nginx/conf.d/default.conf
#RUN sed -i -e "s/\${SERVERNAME}/${SERVERNAME:-mail.example.com}/g" /etc/nginx/conf.d/default.conf
RUN sed -i -e "s/\${SERVERNAME}/${SERVERNAME}.${DOMAIN}/g" /etc/nginx/conf.d/default.conf
#COPY config.inc.php /var/lib/roundcube/src/config/
#COPY config.inc.php /etc/roundcube/
EXPOSE 443

VOLUME /var/lib/roundcube
