FROM alpine

RUN apk add --no-cache openssl
COPY add_files/gen.sh /gen.sh
COPY add_files/openssl.cnf /etc/ssl/openssl.cnf
RUN chmod +x /gen.sh

VOLUME /pki

ENTRYPOINT [ "/gen.sh" ]
