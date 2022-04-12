# TP5 : CI/CD

Dans ce TP on va mettre un peu les mains dans la CI/CD.

Il y a beaucoup de choses à discuter à ce sujet, nous allons ici nous concentrer sur des points essentiels.

Surtout, on va s'en servir pour l'appliquer dans le cadre de tout ce qu'on a vu précédemment dans le cours.

On va, dans ce TP, en particulier s'intéresser à la consommation du plateforme de CI/CD, sans en installer une nous-mêmes.
 Pour dire les mots : on va utilise https://gitlab.com et non pas un dépôt git configuré par nos soins.

> J'aurais aimé hein, mais c'est beaucoup de temps, que nous n'avons pas. Allons sur les trucs cools directement : l'utilisation de la plateforme.

# Sommaire

- [TP5 : CI/CD](#tp5--cicd)
- [Sommaire](#sommaire)
- I. Première approche
  - [1. Gitlab et la CI/CD](#1-gitlab-et-la-cicd)
  - [2. Où sont exécutées les commandes](#2-où-sont-exécutées-les-commandes)
  - [3. Appliqué à Terraform](#3-appliqué-à-terraform)
  - 4. Appliqué à Ansible
    - [A. Tests](#a-tests)
    - [B. Deploy](#b-deploy)
  - [5. Appliqué à Docker](#5-appliqué-à-docker)
- [II. Build your own](#ii-build-your-own)

# I. Première approche

## 1. Gitlab et la CI/CD

Dans Gitlab, la CI/CD est native. Vous pouvez voir dans le volet de gauche, sur chaque projet, un onglet "CI/CD".

Dans Gitlab, il est nécessaire d'avoir des *runners* associé à notre projet pour que la CI/CD fonctionne : ce sont des serveurs sur lesquels on a installé le *runner* Gitlab.
 Ces serveurs sont utilisés par Gitlab pour exécuter les commandes qu'on demande à exécuter grâce à la CI/CD.

Avec l'instance publique https://gitlab.com on peut bénéficier, de façon restreinte, de *runners* publics.

> Ca nous suffira pour le cours, évitez de spammer l'exécution de tâches pendant le TP, utilisez `git push` en conscience, avec parcimonie.

Afin de déclencher l'exécution d'une *pipeline* de CI/CD, c'est à dire une suite de commandes à exécuter, il suffit de créer un fichier `.gitlab-ci.yml` à la racine de votre dépôt, et `git push`. Baboom.

> Même s'il est tout pourri, ça aura le mérite de trigger une *pipeline*.

Un fichier `.gitlab-ci.yml` simpliste peut ressembler à :

```yaml
stages: # on déclare la liste des stages utilisés dans toute la pipeline
  - ynov_b3 # le nom des stages est arbitraire

b3_echo_hello: # le nom des jobs est arbitraire aussi
  stage: ynov_b3 # chaque job est dans un stage spécifique
  script: # script permet de donner une liste de commande à exécuter
    - echo "Hello, c ma premier pipelin ui"
```



➜ **Z'est parti**

- créez un dépôt sur l'instance publique de Gitlab
- récupérez-le en local (`git clone`)
- ajoutez-y un fichier `.gitlab-ci.yml` avec le contenu juste au dessus
- `git push`
- RDV dans l'onglet CI/CD de votre projet, cliquez sur l'onglet et baladez-vous un peu pour voir l'exécution de la *pipeline*

## 2. Où sont exécutées les commandes

Bah oui c'est vrai ça, où sont exécutés les commandes ? Sur les *runners* mais en l'occurrence, plus spécifiquement, dans des conteneurs Docker.

C'est un cas d'usage où la conteneurisation est le plus à sa place.

Le flow typique ressemble à :

- tu dév peinard

- tu `git push`

- le dépôt Git déclenche une *pipeline* de CI/CD

- pour chaque 

  job

   de la 

  pipeline

   :

  - un conteneur est lancé
  - il `git clone` tout le projet
  - les commandes demandées dans le *job* sont exécutées dans le conteneur
  - à la fin du *job*, le conteneur est détruit

On peut choisir, dans le `.gitlab-ci.yml` dans quelle *image* notre code va s'exécuter avec `image:` dans le stage :

```yaml
stages:
  - ynov_b3

b3_echo_hello:
  stage: ynov_b3
  image: alpine # là
  script:
    - cat /etc/os-release
```



➜ **Déclenchez une nouvelle pipeline avec ce fichier.** Constatez dans les logs qu'une image `alpine` est bien utilisée.

## 3. Appliqué à Terraform

Et bah, non, pas avec Azure, déso.

➜ **En ersatz** des VMs qu'on aurait créées dans cette partie si on avait pu :

- générez une paire de clés SSH

  - une nouvelle SVP, vous allez utiliser la clé privée dans la pipeline étou
  - donc pas la vôtre, parce que la vôtre, ELLE EST PRIVEE cjoizj foiezjficz

- créez manuellement une VM dans Azure (WebUI ou 

  ```
  az
  ```

   CLI ou Terraform) afin de pouvoir enchaîner sur la suite du TP

  - déposez dans la VM la clé publique nouvellement créée
  - je vous conseille plutôt Terraform, ça vous permettra de facilement delete/refaire la VM, ou en créer plusieurs (pour pas perdre de temps entre deux déploiements Ansible)

## 4. Appliqué à Ansible

On va utiliser des *pipelines* de CI/CD pour manipuler de la configuration Ansible.

**Le but** ici va être de

- stocker les fichiers Ansible dans un dépôt git
- effectuer des tests sur les fichiers Ansible
- déployer la configuration Ansible sur un serveur réel

**Ce qu'on doit mettre en place**

- écrire le fichier 

  ```
  .gitlab-ci.yml
  ```

  - il doit effectuer des tests sur les fichiers Ansible
  - il doit déployer la conf une fois les tests effectuées sur la machine Azure

- conf Ansible vers la machine Azure

  - pour rappel, Ansible utilise SSH pour se connecter aux machines de destination
  - pour que notre pipeline puisse pousser de la conf Ansible sur la machine Azure, il faut exécuter des commandes `ansible` dans la pipeline
  - ces commandes ne doivent pas prompt quoi que ce soit (aucune saisie utilisateur)
  - c'est à dire qu'il faut setup un accès SSH par clés (sans mot de passe)
  - et aussi qu'il faut trouver une mécanique pour pouvoir utiliser `become: true` dans Ansible qui prompt un mot de passe normalement
  - ha, et la machine Azure doit avoir Python d'installé aussi !

**Normalement, à ce stade, vous avez** :

- une nouvelle paire de clé générée au début du TP
- une VM dans Azure sur laquelle vous pouvez vous connecter grâce à cette nouvelle paire de clé
  - **testez la connexion si c'est pas fait**
  - elle est prête à recevoir de la conf
- un projet sur l'instance public de Gitlab avec un `.gitlab-ci.yml`

**On enchaîne donc.**

### A. Tests

➜ **Tests de syntaxe des fichiers**

- trouvez une commande qui permet de tester la bonne syntaxe des fichiers Ansible
- testez la localement
- puis intégrez-la dans votre `.gitlab-ci.yml` : créez un stage `syntax_check`
- dans l'idéal, choisissez une image qui dispose déjà de la commande dont vous avez besoin, pour limiter le temps d'exécution

> On peut aller beaucoup plus loin avec les tests, suivant les fichiers qu'on teste. Pour Ansible, par exemple, il existe la techno [Molecule](https://molecule.readthedocs.io/en/latest/) qui permet de créer à la volée des VMs ou des conteneurs, et d'y exécuter les playbooks Ansible, afin de vérifier qu'ils déroulent correctement, avant de les appliquer sur des machines réelles.

**Ca, c'est de l'intégration continue : de la CI. On teste de façon continue ce qu'on push.**

### B. Deploy

➜ **Dans la WebUI de Gitlab**

> Oui donc si c'était pas fait, je répète, GENEREZ UNE NOUVELLE PAIRE DE CLES SVP.

- sur l'interface liée à votre projet, dans le volet de gauche
  - cliquez sur Settings > CI/CD
  - allez dans la section "Variables"
  - créez une nouvelle variable `SSH_PRIVATE_KEY` et en valeur, collez la clé privée générée précédemment
  - ces variables sont accessibles dans le fichier `.gitlab-ci.yml`

➜ **Gérer le `become: true`**

- ce qu'on va pas faire (si ?) :

  - on peut préciser, dans l'inventaire Ansible, un mot de passe pour chaque hôte avec `ansible_sudo_pass`
  - on utilise la mécanique des Vaults Ansible pour stocker cette string de façon chiffrée
  - à chaque déploiement, on file une variable (un secret) à la pipeline qui est le mot de passe pour déchiffrer la Vault
  - c'est le plus propre mais c'est long

- ce qu'on va faire

  , c'est un peu moche mais c'est rapide pour notre cas d'utilisation

  - configurer la machine Azure pour que l'utilisateur n'ait pas besoin de taper de mot de passer pour utiliser `sudo`
  - ça se fait avec la clause `NOPASSWD` dans le fichier `/etc/sudoers`
  - et **testez** après qu'il n'a pas besoin de mot de passe

➜ **On est prêts, éditez le fichier `.gitlab-ci.yml` pour déployer la conf**

- créez un stage `deploy`

- il doit utiliser une commande 

  ```
  ansible-playbook
  ```

   afin de déployer de la conf sur la machine Azure

  - commencez avec un *playbook* Ansible simpliste

- pour que cela fonctionne, il faudra récupérer la clé privée nécessaire au déploiement

  - elle est disponible dans la variable `$SSH_PRIVATE_KEY`
  - un petit `echo $SSH_PRIVATE_KEY > .id_rsa` fera très bien l'affaire

- on peut indiquer à Ansible quelle clé privée utiliser

  - c'est une option sur la ligne de commande (commande `ansible` ou `ansible-playbook`)

**Ca, c'est du déploiement continu : de la CD. On déploie automatiquement ce qui est push, après la CI.**

## 5. Appliqué à Docker

Avec les conteneurs on a besoin d'automatiser :

- le build d'images
  - need CI pour ça
- le lancement de conteneurs
  - Ansible peut déjà faire le taff pour ça

Donc dans cette partie on va voir comment build des images dans une pipeline.

Bon on a quelques gros soucis : en cours on a utiliser `docker build`. Sauf que :

- dans la CI/CD, les commandes sont exécutées dans des conteneurs
- donc un conteneur devrait exécuter `docker build` ?
- donc un conteneur devrait être membre du groupe `docker` ou être `root` (ce qui est équivalent) sur le *runner* ?
- bon déjà c'est crade, et surtout là on est sur les runners publics Gitlab, donc c'est chaud

**En résumé : Docker caca**, ça tourne en `root`, et devoir être `root` pour juste build des images, bah c'est sad.

Je vous présente donc [Buildah](https://buildah.io/) à la rescousse. Un outil en ligne de commande, qui permet de build des images, mais sans avoir besoin des droits `root`.

Le principe est le suivant :

- à chaque dépôt git sur Gitlab est associé un registre d'images (un endroit pour push/pull des images de conteneurs)
- votre pipeline peut trigger le `build` d'une image
- puis une fois build, l'image est `push` sur le registre de votre dépôt
- par la suite il sera possible de `pull` cette image afin de lancer l'application

Afin d'écourter ce TP, on ne va pas le mettre en place ici, vous êtes libres de l'utiliser dans la partie suivante.

**Ici c'est encore de la CI. En effet, on considère que la CI comprend : le build, le packaging et les tests sur les applications.**

# II. Build your own

Cette partie va solliciter un peu tout ce qu'on a vu jusqu'à maintenant + un peu de votre créativité.

Le but : déployer de façon la plus automatisée possible une application donnée.

La marche à suivre :

- choisir une application (peu importe, un truc qui vous parle, de préférence un truc libre et Open Source)
- déterminer une méthode pour déployer l'application
  - conteneurs ?
  - uniquement Ansible ?
  - quel OS de base ?
- créer le nécessaire pour déployer cette application de façon automatisée
  - du Terraform/Vagrant pour automatiser la création des ressources virtuelles
  - cloud-init pour initialiser la VM avec une conf minimale
  - Ansible pour déposer toute la conf additionnelle
  - Ansible/Docker pour lancer l'application
- une fois que le déploiement est fonctionnel, poussez l'automatisation en mettant tout ça dans une pipeline de CI/CD
  - les fichiers doivent être testés
  - toute la stack (VM + conf + application) doit être déployé automatiquement

On discutera ensemble de ce que vous avez choisi et de la direction que ça prendra.

🌞 **En livrable attendu pour ce TP :**

- un dépôt git qui contient l'application
  - éventuellement des fichiers `Dockerfile` et `docker-compose.yml`
- un dépôt git qui contient :
  - les fichiers Ansible
  - les fichiers Terraform/Vagrant
  - les fichiers cloud-init