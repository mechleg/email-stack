FROM tvial/docker-mailserver:latest
LABEL maintainer="mechleg <mechleg@mechleg.com>"

COPY spam.sieve /etc/dovecot/sieve/
COPY 15-mailboxes.conf /etc/dovecot/conf.d/
RUN sed -i -e 's|#\?\(sieve_after =.*\)|\1 /etc/dovecot/sieve/spam.sieve|g' /etc/dovecot/conf.d/90-sieve.conf \
 && sievec /etc/dovecot/sieve/
