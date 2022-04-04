# TP3 : Conteneurisation

Dans ce TP on va aborder plusieurs points autour de la conteneurisation :

- Docker et son empreinte sur le système
- Manipulation d'images
- `docker-compose`

> *Vous trouverez des emojis 📁 et 🌞 dans ce TP. Référez-vous à [la présentation des TP]() pour leur signification (important pour le rendu).*

# Sommaire

- [TP3 : Conteneurisation](#tp3--conteneurisation)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
- I. Docker
  - [1. Install](#1-install)
  - [2. Vérifier l'install](#2-vérifier-linstall)
  - [3. L'installation de Docker](#3-linstallation-de-docker)
  - [4. Lancement de conteneurs](#4-lancement-de-conteneurs)
- [II. Images](#ii-images)
- [III. `docker-compose`](#iii-docker-compose)
- [IV. Bonus : Podman et sécurité](#iv-bonus--podman-et-sécurité)

# 0. Prérequis

➜ **Une machine GNU/Linux avec l'OS de votre choix, gérée avec Vagrant**

> Vous fournirez votre `Vagrantfile` dans le rendu.

# I. Docker

## 1. Install

🌞 **Installer Docker sur la machine**

- en suivant [la doc officielle](https://docs.docker.com/engine/install/)

- démarrer le service `docker` avec une commande `systemctl`

- ajouter votre utilisateur au groupe 

  ```
  docker
  ```

  - cela permet d'utiliser Docker sans avoir besoin de l'identité de `root`
  - avec la commande : `sudo usermod -aG docker $(whoami)`
  - déconnectez-vous puis relancez une session pour que le changement prenne effet

## 2. Vérifier l'install

➜ **Vérifiez que Docker est actif est disponible en essayant quelques commandes usuelles :**

```shell
# Info sur l'install actuelle de Docker
$ docker info

# Liste des conteneurs actifs
$ docker ps
# Liste de tous les conteneurs
$ docker ps -a

# Liste des images disponibles localement
$ docker images

# Lancer un conteneur debian
$ docker run debian
$ docker run -d debian sleep 99999
$ docker run -it debian bash

# Consulter les logs d'un conteneur
$ docker ps # on repère l'ID/le nom du conteneur voulu
$ docker logs <ID_OR_NAME>
$ docker logs -f <ID_OR_NAME> # suit l'arrivée des logs en temps réel

# Exécuter un processus dans un conteneur actif
$ docker ps # on repère l'ID/le nom du conteneur voulu
$ docker exec <ID_OR_NAME> <COMMAND>
$ docker exec <ID_OR_NAME> ls
$ docker exec -it <ID_OR_NAME> bash # permet de récupérer un shell bash dans le conteneur ciblé
```



➜ **Explorer un peu le help**, si c'est pas le man :

```shell
$ docker --help
$ docker run --help
```



## 3. L'installation de Docker

🌞 **Déterminez...**

- le path du dossier de données de Docker

  - l'endroit où tout ce qui est lié à Docker est stocké
  - les images, les données des conteneurs actifs, etc.

  ```bash
  vagrant@node1:~$ docker info
  [...]
  
  Server:
  [...]
   Docker Root Dir: /var/lib/docker
   [...]
  ```

  

- pourquoi est-ce qu'être membre du groupe docker permet de l'utiliser ?

```txt
Creating a Unix group called docker and adding users to it. When the Docker daemon starts, it creates a Unix socket accessible by members of the docker group. By the way, the docker group grants privileges equivalent to the root user.
```



- le path du fichier de conf de Docker

```bash
/etc/docker/daemon.json
```



🌞 **Editer le fichier de configuration du Démon Docker**

- modifier le OOM Score du démon Docker à -400
- changer le path du dossier qui contient les données (que vous aviez repéré à l'étape précédente)

```bash
vagrant@node1:~$ sudo vi /etc/docker/daemon.json
vagrant@node1:~$ cat /etc/docker/daemon.json 
{
    "oom-score-adjust": -400
    "data-root": "/var/lib/docker/docker"
}
```

📁 **Le fichier `.json` de configuration de Docker**

🌞 **Analyser les processus liés au démon**

- utliliser la commande `ps` pour lister les processus de la machine
- déterminer quel(s) processus sont liés au service Docker

```bash
vagrant@node1:~$ ps -eF | grep docker
root       19052       1  0 345478 84076  0 09:55 ?        00:00:00 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
vagrant    21856   21707  0  2040   724   1 10:26 pts/0    00:00:00 grep --color=auto docker
```

```
Le containerd de docker a un PID = 19052 et son PPID est le processus 1. 
```

🌞 **Analyse les processus liés à chaque conteneur**

- lancer un unique conteneur
- déterminer quel(s) processus sont liés à ce conteneur spécifique

```bash
vagrant@node1:~$ docker run -it ubuntu sleep 999
```

```bash
vagrant@node1:~$ docker ps
CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS          PORTS     NAMES
e96ff8f8cc4e   ubuntu    "sleep 999"   15 seconds ago   Up 14 seconds             inspiring_ramanujan
```

```bash
vagrant@node1:~$ ps -eF | grep docker
root       19052       1  0 363975 82676  0 09:55 ?        00:00:03 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
vagrant    22228   21707  0 337555 48560  1 10:27 pts/0    00:00:00 docker run -it ubuntu sleep 999
vagrant    23173   22401  0  2040   656   0 10:36 pts/1    00:00:00 grep --color=auto docker
```

```
Le PID de ce container est 22228 et son PPID = 21707
```



## 4. Lancement de conteneurs

La commande pour lancer des conteneurs est `docker run`.

Certaines options sont très souvent utilisées :

```shell
# L'option --name permet de définir un nom pour le conteneur
$ docker run --name web nginx

# L'option -d permet de lancer un conteneur en tâche de fond
$ docker run --name web -d nginx

# L'option -v permet de partager un dossier/un fichier entre l'hôte et le conteneur
$ docker run --name web -d -v /path/to/html:/usr/share/nginx/html nginx

# L'option -p permet de partager un port entre l'hôte et le conteneur
$ docker run --name web -d -v /path/to/html:/usr/share/nginx/html -p 8888:80 nginx
# Dans l'exemple ci-dessus, le port 8888 de l'hôte est partagé vers le port 80 du conteneur
```



🌞 **Utiliser la commande `docker run`**

- lancer un conteneur 

  ```
  nginx
  ```

  - avec un fichier de conf personnalisé
  
  - avec un fichier `index.html` personnalisé
  
  - l'application doit être joignable grâce à un partage de ports
  
  - vous limiterez l'utilisation de la RAM et du CPU de ce conteneur
  
  - le conteneur devra avoir un nom
  
  - le processus exécuté par le conteneur doit être un utilisateur de votre choix (pas `root`) 
  
    **-> LOLILOL Léo, comment configurer les droits des fichiers du container à mon user (qui n'est pas root) sans dockerfile ? 🧐**

```bash
Ici avec le UID de nginx (101) dans mon container (même résultat avec 1000) :

vagrant@node1:~$ sudo docker run --name nginx_web -d -v /data/nginx/index.html:/usr/share/nginx/index.html -v /home/vagrant/default.conf:/etc/nginx/conf.d/default.conf  -u 101 -p 8088:80 --cpus="1.5" -m 6m nginx
WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
933fb4c0c1cadf3fbb97b8410a2c75ce2bdad0030e1611692b1ccf27576d5581

vagrant@node1:~$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED             STATUS             PORTS                                   NAMES
4d85ee4f4ac0   nginx     "/docker-entrypoint.…"   46 minutes ago      Up 46 minutes      0.0.0.0:8888->80/tcp, :::8888->80/tcp   webnginx
66d18dadbb6c   nginx     "/docker-entrypoint.…"   About an hour ago   Up About an hour   0.0.0.0:80->80/tcp, :::80->80/tcp       mynginx1
```

```bash
Ici la même commande avec le user root :

vagrant@node1:~$ sudo docker run --name nginx_web_2 -d -v /data/nginx/index.html:/usr/share/nginx/index.html -v /home/vagrant/default.conf:/etc/nginx/conf.d/default.conf  --user="root" -p 8088:80 --cpus="1.5" -m 6m nginx
WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
dff9301705f969889e9109c2768313d6df1eb12f749fc40b684f2a8dfc2a599f

vagrant@node1:~$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED             STATUS             PORTS                                   NAMES
dff9301705f9   nginx     "/docker-entrypoint.…"   3 seconds ago       Up 2 seconds       0.0.0.0:8088->80/tcp, :::8088->80/tcp   nginx_web_2
4d85ee4f4ac0   nginx     "/docker-entrypoint.…"   47 minutes ago      Up 47 minutes      0.0.0.0:8888->80/tcp, :::8888->80/tcp   webnginx
66d18dadbb6c   nginx     "/docker-entrypoint.…"   About an hour ago   Up About an hour   0.0.0.0:80->80/tcp, :::80->80/tcp       mynginx1
vagrant@node1:~$ 
```

> Tout se fait avec des options de la commande `docker run`.

# II. Images

La construction d'image avec Docker est basée sur l'utilisation de fichiers `Dockerfile`.

🌞 **Construire votre propre image**

- image de base
  - une image du Docker Hub
  - digne de confiance
  - qui ne porte aucune application par défaut
- vous ajouterez
  - mise à jour du système
  - installation de Apache
  - page d'accueil Apache HTML personnalisée
- plus l'image sera légère, et plus vous aurez de points

📁 **`Dockerfile`**

# III. `docker-compose`

➜ **Installer `docker-compose` sur la machine**

- en suivant [la doc officielle](https://docs.docker.com/compose/install/)

`docker-compose` est un outil qui permet de lancer plusieurs conteneurs en une seule commande.

> En plus d'être pratique, il fournit des fonctionnalités additionnelles, liés au fait qu'il s'occupe à lui tout seul de lancer tous les conteneurs. On peut par exemple demander à un conteneur de ne s'allumer que lorsqu'un autre conteneur est devenu "healthy". Idéal pour lancer une application après sa base de données par exemple.

Le principe de fonctionnement de `docker-compose` :

- on écrit un fichier qui décrit les conteneurs voulus
  - c'est le `docker-compose.yml`
  - tout ce que vous écriviez sur la ligne `docker run` peut être écrit sous la forme d'un `docker-compose.yml`
- on se déplace dans le dossier qui contient le `docker-compose.yml`
- on peut utiliser les commandes `docker-compose` :

```shell
# Allumer les conteneurs définis dans le docker-compose.yml
$ docker-compose up
$ docker-compose up -d

# Eteindre
$ docker-compose down

# Explorer un peu le help, il y a d'autres commandes utiles
$ docker-compose --help
```



La syntaxe du fichier peut par exemple ressembler à :

```yaml
version: "3.8"

services:
  db:
    image: mysql:5.7
    restart: always
    ports:
      - '3306:3306'
    volumes:
      - "./db/mysql:/docker-entrypoint-initdb.d/"
      - "./db/mysql_files:/var/lib/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: plexdb
      MYSQL_USER: plexuser
      MYSQL_PASSWORD: plexpwd

  php:
    restart: always
    build: ./engine/php_server/
    volumes:
      - "./engine/html:/var/www/html"
    depends_on:
      - db
    links:
      - "db"
    ports: 
      - "80:80"

  plex:
    image: ghcr.io/linuxserver/plex
    container_name: plex
    ports:
      - "32400:32400"
    volumes:
      - ./plex/config:/config
      - ./downloads/complete/tv:/data/tv
    restart: unless-stopped
```



🌞 **Créer un `docker-compose.yml`**

- il doit contenir deux conteneurs : un web et une db
- le serveur web
  - une nouvelle image faite maison
  - basée sur votre image Apache précédente
  - contient l'application NextCloud
- sa base de données
  - est adaptée pour que NextCloud l'utilise
  - vous renseigner dans la doc

📁 **`docker-compose.yml`**

# IV. Bonus : Podman et sécurité

Si ça vous chante, **il y a [un mini-TP bonus]()** pour explorer vous-mêmes la notion de *namespaces* et pour **appréhender un autre outil que Docker pour faire de la conteneurisation : Podman**, que l'on utilise car plus orienté sécurité et robustesse que Docker.