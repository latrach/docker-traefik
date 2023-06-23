# Openssl
generation des certificats pour les devs en local

Generation des RootCA à faire qu'une fois et si pas déja installé en local
une fois generer ajouter les certificats localhost.crt et RootCA.crt en les installant:
`click droit : -> installer -> ordinateur local -> Autorités de certification racine de confiance`

~~~sh
openssl req -x509 -nodes -new -sha256 -days 9000 -newkey rsa:2048 -keyout ./certs/RootCA.key -out ./certs/RootCA.pem -subj "/C=US/CN=EALIS-DEV-Root-CA"
openssl x509 -outform pem -in ./certs/RootCA.pem -out ./certs/RootCA.crt
openssl req -new -nodes -newkey rsa:2048 -keyout ./certs/localhost.key -out ./certs/localhost.csr -subj "/C=FR/ST=FRANCE/L=PARIS/O=EALIS-DEV-Certificates/CN=localhost"
~~~
# Traefik, a modern proxy manager

![Traefik](https://files.nes-france.com/gitlab/traefik.png)
