#!/bin/bash

dt=$(date '+%d/%m/%Y %H:%M:%S');
echo "$dt"
echo 'generation des certificats avec opessl'
# Generation des RootCA à faire qu'une fois si la premiere fois et si pas déja installé en local
# une fois generer ajouter les certificats localhost.crt et RootCA.crt en les installant:
# click droit : -> installer -> ordinateur local -> Autorités de certification racine de confiance :
#
#   openssl req -x509 -nodes -new -sha256 -days 9000 -newkey rsa:2048 -keyout ./certs/RootCA.key -out ./certs/RootCA.pem -subj "/C=US/CN=EALIS-DEV-Root-CA"
#   openssl x509 -outform pem -in ./certs/RootCA.pem -out ./certs/RootCA.crt
#   openssl req -new -nodes -newkey rsa:2048 -keyout ./certs/localhost.key -out ./certs/localhost.csr -subj "/C=FR/ST=FRANCE/L=PARIS/O=EALIS-DEV-Certificates/CN=localhost"

openssl x509 -req -sha256 -days 1024 \
        -in /home/openssl/certs/localhost.csr \
        -CA /home/openssl/certs/RootCA.pem \
        -CAkey /home/openssl/certs/RootCA.key \
        -CAcreateserial \
        -extfile /home/openssl/domains.ext \
        -out /home/openssl/certs/localhost.crt

#keep alive
echo 'tail -f /dev/null'
tail -f /dev/null
