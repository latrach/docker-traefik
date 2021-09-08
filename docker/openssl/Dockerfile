FROM bash:5.1

RUN apk add --update openssl && \
    rm -rf /var/cache/apk/*

CMD ["bash", "/openssl/openssl.sh"]
