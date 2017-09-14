## Webmail + letsencrypt free certificate + secure email server (IMAPS and SMTP-TLS) docker-compose cluster based on the following base images:

- [mailserver](https://github.com/tomav/docker-mailserver)
- [base for mailserver](https://hub.docker.com/_/ubuntu/)
- [php7fpm](https://docs.docker.com/samples/library/php)
- [webmail](https://docs.docker.com/samples/library/nginx)

In addition to the docker images, this [source tarball](https://github.com/roundcube/roundcubemail/releases/download/1.3.1}/roundcubemail-1.3.1-complete.tar.gz) is also used


## Quick Usage (links above have more extensive documentation):
#### letsencrypt should be enabled first to secure our email ports
`docker pull certbot/certbot`

#### get initial certificate, make sure DNS works for your domain
`docker run -it --rm -p 443:443 --name certbot -v /etc/letsencrypt:/etc/letsencrypt -v /var/log/letsencrypt:/var/log/letsencrypt certbot/certbot certonly --standalone -d DOMAIN.COM --email EMAIL@ADDRESS --agree-tos`

#### generate diffie-hellman for nginx
`openssl dhparam -out /etc/letsencrypt/dhparam.pem 2048`

#### start email-stack cluster, takes an extra minute or two to create and populate volumes
- `cp .env.tmpl .env`    # make adjustments to .env to match your desired environment
- `./email-stack-ctl.sh createvol`
- `./email-stack-ctl.sh startd`
#### stop email-stack cluster
`./email-stack-ctl.sh stop`

#### systemd, configured to run from /opt/email-stack
- `cp ./email-stack.service /lib/systemd/system/`
- `systemctl start email-stack.service`

#### adding email user(s)
`docker run --rm -e MAIL_USER=your@email.com -e MAIL_PASS=pickYourPassword -ti tvial/docker-mailserver:latest /bin/sh -c 'echo "$MAIL_USER|$(doveadm pw -s SHA512-CRYPT -u $MAIL_USER -p $MAIL_PASS)"' >> mailserver/config/postfix-accounts.cf`

#### generate dkim config
`docker run --rm -v "$(pwd)/mailserver/config":/tmp/docker-mailserver -ti tvial/docker-mailserver:latest generate-dkim-config`

\# also need to create DNS TXT record with the contents of ./mailserver/config/opendkim/keys/yourdomain.com/mail.txt
