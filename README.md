# docker-traefik — Proxy local de développement

Stack Docker locale fournissant un point d'entrée TLS unique pour les projets de développement : **Traefik v2** (reverse proxy), **Portainer**, **Maildev**, et génération de certificats SSL auto-signés via **OpenSSL**.

![Traefik](https://files.nes-france.com/gitlab/traefik.png)

## Services

| Service   | Image                           | URL locale                          | Ports          |
|-----------|---------------------------------|-------------------------------------|----------------|
| Traefik   | `traefik:2.9.8`                 | https://traefik.docker.localhost    | 80, 443, 8080  |
| Portainer | `portainer/portainer-ce:2.19.4` | https://portainer.docker.localhost  | 9000           |
| Maildev   | `maildev/maildev:2.0.5`         | https://maildev.docker.localhost    | 1025, 1080     |
| OpenSSL   | `slatrach/openssl:1.1`          | — (génère les certificats)          | —              |

Les conteneurs d'autres projets se rattachent au réseau Docker partagé `traefik` pour être exposés automatiquement.

## Démarrage

~~~sh
# Démarrer la stack
docker compose up -d

# Voir les logs de Traefik
docker compose logs -f traefik

# Arrêter la stack
docker compose down
~~~

## Certificats SSL

### 1. RootCA (une seule fois)

Générer la RootCA puis l'installer dans le magasin de confiance de l'OS :
`clic droit -> installer -> ordinateur local -> Autorités de certification racine de confiance`

~~~sh
openssl req -x509 -nodes -new -sha256 -days 9000 -newkey rsa:2048 -keyout ./certs/RootCA.key -out ./certs/RootCA.pem -subj "/C=US/CN=LATRACH-DEV-Root-CA"
openssl x509 -outform pem -in ./certs/RootCA.pem -out ./certs/RootCA.crt
openssl req -new -nodes -newkey rsa:2048 -keyout ./certs/localhost.key -out ./certs/localhost.csr -subj "/C=FR/ST=FRANCE/L=PARIS/O=LATRACH-DEV-Certificates/CN=localhost"
~~~

Installer ensuite `certs/RootCA.crt` **et** `certs/localhost.crt` dans les autorités racine de confiance.

### 2. Signer le certificat localhost

Le service `openssl` signe `localhost.csr` avec la RootCA en appliquant les SAN de `openssl/domains.ext` :

~~~sh
docker compose run --rm openssl
~~~

**SAN couverts** (`openssl/domains.ext`) : `localhost`, `docker.localhost`, `*.docker.localhost`, `docker.dev`, `*.docker.dev`.
Pour un domaine supplémentaire, ajouter une entrée `DNS.x` dans `openssl/domains.ext` puis régénérer.

> Le dossier `certs/` contient les clés privées — **il n'est pas versionné**.

## Ajouter un service

Dans `docker-compose.yml`, ajouter les labels Traefik (`port` = port **interne** du conteneur) :

~~~yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<nom>.entrypoints=http,https"
  - "traefik.http.routers.<nom>.rule=Host(`<nom>.docker.localhost`)"
  - "traefik.http.routers.<nom>.tls=true"
  - "traefik.http.services.<nom>.loadbalancer.server.port=<PORT_INTERNE>"
~~~

Le provider Docker est en `exposedByDefault: false` : seul un service portant `traefik.enable=true` est routé.

## Git

`origin` = GitLab, `github` = GitHub. Cibles du `Makefile` :

~~~sh
make help                     # liste les cibles
make git-commit m="message"   # commit + push origin + github + .ai-brain
make git-push                 # push origin + github
make git-pull                 # pull github + .ai-brain
~~~

