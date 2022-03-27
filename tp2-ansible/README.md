# TP2 : Ansible

Le but de ce TP est d'approfondir l'utilisation d'Ansible :

- construction de playbooks
- organisation de dépôt
- workflow de travail

> Il est strictement nécessaire d'avoir terminé les [TP0]() et [TP1]().

# Sommaire

- [TP2 : Ansible](#tp2--ansible)
- [Sommaire](#sommaire)
- [0. Setup](#0-setup)
- [I. Init repo](#i-init-repo)
- II. Un dépôt Ansible rangé
  - [1. Structure du dépôt : inventaires](#1-structure-du-dépôt--inventaires)
  - [2. Structure du dépôt : rôles](#2-structure-du-dépôt--rôles)
  - [3. Structure du dépôt : variables d'inventaire](#3-structure-du-dépôt--variables-dinventaire)
  - [4. Structure du dépôt : rôle avancé](#4-structure-du-dépôt--rôle-avancé)
  - [5. Gérer la suppression](#5-gérer-la-suppression)
- III. Repeat
  - [1. NGINX](#1-nginx)
  - [2. Common](#2-common)
  - [3. Dynamic Loadbalancer](#3-dynamic-loadbalancer)
- IV. Aller plus loin
  - [1. Vault Ansible](#1-vault-ansible)
  - [2. Support de plusieurs OS](#2-support-de-plusieurs-os)

# 0. Setup

> Je vous laisse le choix des OS GNU/Linux.

Pour réaliser le TP vous allez avoir besoin de :

- 1 poste avec Ansible : 

  le *control node*

  - votre PC sous Linux, ou une VM sous Linux

  - le fichier 

    ```
    hosts
    ```

     de cette machine doit être rempli pour pouvoir joindre les deux 

    managed nodes

     avec des noms plutôt qu'une IP :

    - `node1.tp2.cloud`
    - `node2.tp2.cloud`

- 2 machines Linux : 

  les *managed nodes*

  - déployées avec Vagrant

    - définissez leur une IP statique

  - préconfigurées avec 

    ```
    cloud-init
    ```

    - un utilisateur créé
    - cet utilisateur a accès aux droits de `root` *via* la commande `sudo`
    - déposez une clé SSH sur un utilisateur que vous avez créé

- un dépôt git dans lequel on stockera notre code Ansible

  - pour le moment, on va faire simple, et vous pouvez utilisez un fournisseur public comme Gitlab ou Github

Une fois les machines en place, assurez-vous que vous avez avoir une connexion SSH sans mot **de passe depuis le \*control node\* vers les \*managed nodes\***.

------

🌞 **Je veux un seul truc dans le rendu Markdown : le lien vers votre dépôt git qui contient tout le code Ansible**



# I. Init repo

➜ **Créez un répertoire de travail**

- sur le *control node*
- dans le *home directory* de l'utilisateur que vous utilisez
- ce répertoire doit être un dépôt git que vous avez créé sur une plateforme publique comme Gitlab, Github, etc.

> **Tous les fichiers Ansible devront être créés dans de dossier.**

➜ **Créez le fichier d'inventaire Ansible**

- référez-vous au [TP0]()

- créez un fichier 

  inventory

  ```
  hosts.ini
  ```

  - nommez le groupe d'hôtes `ynov`
  - les instructions du TP utiliseront `ynov` comme nom de groupe

- utilisez le module `ping` de Ansible pour tester qu'Ansible peut joindre les machines

```shell
$ ansible ynov -i hosts.ini -m ping 
```



➜ **Créez un playbook de test**

- dans le répertoire de travail Ansible, créez un sous-répertoire `playbooks/`

- créez un fichier `playbooks/test.yml`

- écrire le nécessaire dans le fichier pour installer 

  ```
  vim
  ```

   sur les 

  managed nodes

  - référez-vous au [fichier `nginx.yml` du TP0]()

# II. Un dépôt Ansible rangé

## 1. Structure du dépôt : inventaires

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `inventories/`
- créez un répertoire `inventories/vagrant_lab/`
- déplacez le fichier `hosts.ini` dans `inventories/vagrant_lab/hosts.ini`
- assurez vous que pouvez toujours déployer correctement avec une commande `ansible-playbook`

```bash
➜  tp2-ansible git:(master) ✗ ansible-playbook -i Ansible/inventories/vagrant_lab/hosts.ini Ansible/test.yml

PLAY [Install vim] *********************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************
The authenticity of host 'node2.tp2.cloud (192.168.56.5)' can't be established.
ECDSA key fingerprint is SHA256:NS8ww4SMoWGIODdUNPWy2Vwt9bcakE9fL7zk2JGlzPbw.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
The authenticity of host 'node1.tp2.cloud (192.168.56.4)' can't be established.
ECDSA key fingerprint is SHA256:FP/tYR0hUuiE85XpUHkiNv0HXC2XHJwYu+9bcakcsYwM.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [apt-get update] ******************************************************************************************************************************************
ok: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

TASK [install vim] *********************************************************************************************************************************************
ok: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

PLAY RECAP *****************************************************************************************************************************************************
node1.tp2.cloud            : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2.tp2.cloud            : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

## 2. Structure du dépôt : rôles

**Les \*rôles\* permettent de regrouper de façon logique les différentes configurations qu'un dépôt Ansible contient.**

Un *rôle* correspond à une configuration spécifique, ou une application spéficique. Ainsi on peut trouver un rôle `apache` qui installe le serveur web Apache, ou encore `mysql`, `nginx`, etc.

**Un rôle doit être générique.** Il ne doit pas être spécifique à telle ou telle machine.

Il existe des conventions et bonnes pratiques pour structurer les *rôles* Ansible, que nous allons voir dans cette partie.

On crée souvent un *rôle* `common` qui est appliqué sur toutes les machines du parc, et qui pose la configuration élémentaire, commune à toutes les machines.

➜ **Ajout d'un fichier de config Ansible**

- dans le répertoire de travail, créez un fichier `ansible.cfg` :

```ini
[defaults]
roles_path = ./roles
```



➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `roles/`
- créez un répertoire `roles/common/`
- créez un répertoire `roles/common/tasks/`
- créez un fichier `roles/common/tasks/main.yml` avec le contenu suivant :

```yaml
- name: Install common packages
  import_tasks: packages.yml
```



- créez un fichier 

  ```
  roles/common/tasks/packages.yml
  ```

   :

  - on va en profiter pour manipuler des variables Ansible

```yaml
- name: Install common packages
  ansible.builtin.package:
    name: "{{ item }}"
    state: present
  with_items: "{{ common_packages }}" # ceci permet de boucler sur la liste common_packages
```



- créez un répertoire `roles/common/defaults/`
- créez un fichier `roles/common/defaults/main.yml` :

```yaml
common_packages:
  - vim
  - git
```



- créez un fichier `playbooks/main.yml`

```yaml
- hosts: ynov
  roles:
    - common
```



➜ **Testez d'appliquer ce playbook avec une commande `ansible-playbook`**

## 3. Structure du dépôt : variables d'inventaire

Afin de garder la complexité d'un dépôt Ansible sous contrôle, il est récurrent d'user et abuser de l'utilisation des variables.

Il est possible dans un dépôt Ansible de déclarer à plusieurs endroits : on a déjà vu le répertoire `defaults/` à l'intérieur d'un rôle (comme notre `roles/common/defaults/`) que l'on a créé juste avant. Ce répertoire est utile pour déclarer des variables spécifiques au rôle.

Qu'en est-il, dans notre cas présent, si l'on souhaite installer un paquet sur une seule machine, mais qui est considéré comme un paquet de "base" ? On aimerait l'ajouter dans la liste dans `roles/common/defaults/main.yml` mais ce serait moche d'avoir une condition sur le nom de la machine à cet endroit (un rôle doit être générique).

**Pour cela on utilise les `host_vars`.**

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `inventories/vagrant_lab/host_vars/`
- créez un fichier `inventories/vagrant_lab/host_vars/node1.tp2.cloud.yml` :

```yaml
common_packages:
  - vim
  - git
  - rsync
```



➜ **Testez d'appliquer le playbook avec une commande `ansible-playbook`**

```bash
➜  Ansible git:(master) ✗ ansible-playbook -i inventories/vagrant_lab/hosts.ini playbooks/main.yml


PLAY [ynov] ****************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************
The authenticity of host 'node2.tp2.cloud (192.168.56.5)' can't be established.
ECDSA key fingerprint is SHA256:NS8ww4SMoWGIODdUNPWy2Vwt9bcakE9fL7zk2JGlzPbw.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
The authenticity of host 'node1.tp2.cloud (192.168.56.4)' can't be established.
ECDSA key fingerprint is SHA256:FP/tYR0hUuiE85XpUHkiNv0HXC2XHJwYu+9bcakusYwM.
Are you sure you want to continue connecting (yes/no/[fingerprint])? ok: [node2.tp2.cloud]
yes
ok: [node1.tp2.cloud]

TASK [common : Install common packages] ************************************************************************************************************************
ok: [node2.tp2.cloud] => (item=vim)
ok: [node1.tp2.cloud] => (item=vim)
ok: [node2.tp2.cloud] => (item=git)
ok: [node1.tp2.cloud] => (item=git)
ok: [node1.tp2.cloud] => (item=rsync)

PLAY RECAP *****************************************************************************************************************************************************
node1.tp2.cloud            : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2.tp2.cloud            : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```



------

Il est aussi possible d'attribuer des variables à un groupe de machines définies dans l'inventaire. **On utilise pour ça les `group_vars`.**

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `inventories/vagrant_lab/group_vars/`
- créez un fichier `inventories/vagrant_lab/group_vars/ynov.yml` :

```yaml
users:
  - le_nain
  - l_elfe
  - le_ranger
```



➜ **Modifiez le fichier `roles/common/tasks/main.yml`** pour inclure un nouveau fichier  `roles/common/tasks/users.yml` :

- il doit utiliser cette variable `users` pour créer des utilisateurs
- réutilisez la syntaxe avec le `with_items`
- la variable `users` est accessible, du moment que vous déployez sur les machines qui sont dans le groupe `ynov`

➜ **Vérifiez la bonne exécution du playbook**

```bash
➜  Ansible git:(master) ✗ ansible-playbook -i inventories/vagrant_lab/hosts.ini playbooks/main.yml


PLAY [ynov] ****************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************
ok: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

TASK [common : Install common packages] ************************************************************************************************************************
ok: [node1.tp2.cloud] => (item=vim)
ok: [node2.tp2.cloud] => (item=vim)
ok: [node1.tp2.cloud] => (item=git)
ok: [node2.tp2.cloud] => (item=git)
ok: [node1.tp2.cloud] => (item=rsync)

TASK [common : Create a users attached to ynov group] **********************************************************************************************************
changed: [node2.tp2.cloud] => (item=le_nain)
changed: [node1.tp2.cloud] => (item=le_nain)
changed: [node1.tp2.cloud] => (item=l_elfe)
changed: [node2.tp2.cloud] => (item=l_elfe)
changed: [node2.tp2.cloud] => (item=le_ranger)
[WARNING]: The input password appears not to have been hashed. The 'password' argument must be encrypted for this module to work properly.
changed: [node1.tp2.cloud] => (item=le_ranger)

PLAY RECAP *****************************************************************************************************************************************************
node1.tp2.cloud            : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2.tp2.cloud            : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```bash
vagrant@node1:~$ cat /etc/passwd | grep 'le_nain\|l_elfe\|le_ranger'
le_nain:x:1004:1006::/home/le_nain:/bin/sh
l_elfe:x:1005:1007::/home/l_elfe:/bin/sh
le_ranger:x:1006:1008::/home/le_ranger:/bin/sh
```



## 4. Structure du dépôt : rôle avancé

➜ **Créez un nouveau rôle `nginx`**

- créez le répertoire du rôle `roles/nginx/`
- créez un sous-répertoire `roles/nginx/tasks/` et un fichier `main.yml` à l'intérieur :

```yaml
- name: Install NGINX
  import_tasks: install.yml

- name: Configure NGINX
  import_tasks: config.yml

- name: Deploy VirtualHosts
  import_tasks: vhosts.yml
```



➜ **Remplissez le fichier `roles/nginx/tasks/install.yml`**

- il doit installer le paquet NGINX
  - je vous laisse gérer :)
  
  ```yaml
  - name: Install NGINX
    become: yes
    ansible.builtin.package:
      name: nginx
      state: present
  ```

➜ **On va y ajouter quelques mécaniques : fichiers et templates :**

- créez un répertoire `roles/nginx/files/`

- créez un fichier 

  ```
  roles/nginx/files/nginx.conf
  ```

  - récupérez un fichier `nginx.conf` par défaut (en faisant une install à la main par exemple)
  - ajoutez une ligne `include conf.d/*.conf;`

- créez un répertoire `roles/nginx/templates/`

- créez un fichier 

  ```
  roles/nginx/templates/vhost.conf.j2
  ```

   :

  - `.j2` c'pour Jinja2, c'est le nom du moteur de templating utilisé par Ansible

```nginx
server {
        listen {{ nginx_port }} ;
        server_name {{ nginx_servername }};

        location / {
            root {{ nginx_webroot }};
            index index.html;
        }
}
```



➜ **Remplissez le fichier `roles/nginx/tasks/config.yml`** :

```yaml
- name : Main NGINX config file
  copy:
    src: nginx.conf # pas besoin de préciser de path, il sait qu'il doit chercher dans le dossier files/
    dest: /etc/nginx/nginx.conf
```



➜ **Quelques variables `roles/nginx/defaults/main.yml`** :

```yaml
nginx_servername: test
nginx_port: 8080
nginx_webroot: /var/www/html/test
nginx_index_content: "<h1>teeeeeest</h1>"
```



➜ **Remplissez le fichier `roles/nginx/tasks/vhosts.yml`** :

```yaml
- name: Create webroot
  file:
    path: "{{ nginx_webroot }}"
    state: directory

- name: Create index
  copy:
    dest: "{{ nginx_webroot }}/index.html"
    content: "{{ nginx_index_content }}"

- name: NGINX Virtual Host
  template:
    src: vhost.conf.j2
    dest: /etc/nginx/conf.d/{{ nginx_servername }}.conf
```



➜ **Deploy !**

- ajoutez ce rôle `nginx` au playbook
- et déployez avec une commande `ansible-playbook`

```bash
➜  Ansible git:(master) ✗ ansible-playbook -i inventories/vagrant_lab/hosts.ini playbooks/main.yml 


PLAY [ynov] ****************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [common : Install common packages] ************************************************************************************************************************
ok: [node2.tp2.cloud] => (item=vim)
ok: [node1.tp2.cloud] => (item=vim)
ok: [node2.tp2.cloud] => (item=git)
ok: [node1.tp2.cloud] => (item=git)
ok: [node1.tp2.cloud] => (item=rsync)

TASK [common : Create a users attached to ynov group] **********************************************************************************************************
ok: [node2.tp2.cloud] => (item=le_nain)
ok: [node1.tp2.cloud] => (item=le_nain)
ok: [node2.tp2.cloud] => (item=l_elfe)
ok: [node1.tp2.cloud] => (item=l_elfe)
ok: [node2.tp2.cloud] => (item=le_ranger)
ok: [node1.tp2.cloud] => (item=le_ranger)

TASK [nginx : Install NGINX] ***********************************************************************************************************************************
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [nginx : Main NGINX config file] **************************************************************************************************************************
ok: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

TASK [nginx : Create webroot] **********************************************************************************************************************************
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [nginx : Create index] ************************************************************************************************************************************
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [nginx : NGINX Virtual Host] ******************************************************************************************************************************
changed: [node1.tp2.cloud]
changed: [node2.tp2.cloud]

PLAY RECAP *****************************************************************************************************************************************************
node1.tp2.cloud            : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2.tp2.cloud            : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```



## 5. Gérer la suppression

Déployer et ajouter des trucs c'est bien beau, mais comment on fait pour gérer le changement ?

**Bah c'est la galère.** Et il faut de la rigueur.

➜ **Créez un fichier qui permet de supprimer des Virtual Hosts NGINX**

```yaml
➜  tp2-ansible git:(master) ✗ cat Ansible/roles/nginx/tasks/add_vhosts.yml 
- name: Create webroot
  become: yes
  file:
    path: "{{ add_vhosts['nginx_webroot'] }}"
    state: directory

- name: Create index
  become: yes
  copy:
    dest: "{{ add_vhosts['nginx_webroot'] }}/index.html"
    content: "{{ add_vhosts['nginx_index_content'] }}"

- name: NGINX Virtual Host
  become: yes
  template:
    src: vhost.conf.j2
    dest: /etc/nginx/conf.d/{{ add_vhosts['nginx_servername'] }}.conf
```

```yaml
➜  tp2-ansible git:(master) ✗ cat Ansible/roles/nginx/tasks/remove_vhosts.yml 
- name: Remove index
  become: yes
  file:
    path: "{{ remove_vhosts['nginx_webroot'] }}/index.html"
    state: absent

- name: Remove NGINX Virtual Host
  become: yes
  file: 
    path: /etc/nginx/conf.d/{{ remove_vhosts['nginx_servername'] }}.conf
    state: absent
```



- testez que vous pouvez facilement ajouter ou supprimer des Virtual Hosts depuis le fichier `host_vars` d'une machine donnée

```yaml
➜  tp2-ansible git:(master) ✗ cat Ansible/inventories/vagrant_lab/host_vars/node1.tp2.cloud.yml 
common_packages:
  - vim
  - git
  - rsync

add_vhosts:
  nginx_servername: testnode3
  nginx_port: 8080
  nginx_webroot: /var/www/html/testnode3
  nginx_index_content: "<h1>teeeeeestnode3</h1>"

remove_vhosts:
  nginx_servername: testnode3
  nginx_port: 8080
  nginx_webroot: /var/www/html/testnode3
  nginx_index_content: "<h1>teeeeeestnode3</h1>"%
```

```yaml
➜  tp2-ansible git:(master) ✗ cat Ansible/inventories/vagrant_lab/host_vars/node2.tp2.cloud.yml
common_packages:
  - vim
  - git
  - rsync

add_vhosts:
  nginx_servername: testnode4
  nginx_port: 8080
  nginx_webroot: /var/www/html/testnode4
  nginx_index_content: "<h1>teeeeeestnode4</h1>"

remove_vhosts:
  nginx_servername:
  nginx_port:
  nginx_webroot: 
  nginx_index_content: %  
```

```bash
➜  Ansible git:(master) ✗ ansible-playbook -i inventories/vagrant_lab/hosts.ini playbooks/main.yml 

PLAY [ynov] ***************************************************************************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************************************************************
ok: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

TASK [common : Install common packages] ***********************************************************************************************************************************************
ok: [node1.tp2.cloud] => (item=vim)
ok: [node2.tp2.cloud] => (item=vim)
ok: [node1.tp2.cloud] => (item=git)
ok: [node2.tp2.cloud] => (item=git)
ok: [node1.tp2.cloud] => (item=rsync)
ok: [node2.tp2.cloud] => (item=rsync)

TASK [common : Create a users attached to ynov group] *********************************************************************************************************************************
ok: [node1.tp2.cloud] => (item=le_nain)
ok: [node2.tp2.cloud] => (item=le_nain)
ok: [node1.tp2.cloud] => (item=l_elfe)
ok: [node2.tp2.cloud] => (item=l_elfe)
ok: [node2.tp2.cloud] => (item=le_ranger)
ok: [node1.tp2.cloud] => (item=le_ranger)

TASK [nginx : Install NGINX] **********************************************************************************************************************************************************
ok: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

TASK [nginx : Main NGINX config file] *************************************************************************************************************************************************
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [nginx : Create webroot] *********************************************************************************************************************************************************
ok: [node2.tp2.cloud]
ok: [node1.tp2.cloud]

TASK [nginx : Create index] ***********************************************************************************************************************************************************
ok: [node2.tp2.cloud]
changed: [node1.tp2.cloud]

TASK [nginx : NGINX Virtual Host] *****************************************************************************************************************************************************
ok: [node2.tp2.cloud]
changed: [node1.tp2.cloud]

TASK [nginx : Remove index] ***********************************************************************************************************************************************************
changed: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

TASK [nginx : Remove NGINX Virtual Host] **********************************************************************************************************************************************
changed: [node1.tp2.cloud]
ok: [node2.tp2.cloud]

PLAY RECAP ****************************************************************************************************************************************************************************
node1.tp2.cloud            : ok=10   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2.tp2.cloud            : ok=10   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```



# III. Repeat

## 1. NGINX

➜ **On reste dans le rôle `nginx`**, faites en sorte que :

- on puisse déclarer la liste `vhosts` en *host_vars*
- si cette liste contient plusieurs `vhosts`, le rôle les déploie tous (exemple en dessous)
- le port précisé est automatiquement ouvert dans le firewall
- vous gérez explicitement les permissions de tous les fichiers

Exemple de fichier de variable avec plusieurs Virtual Hosts dans la liste `vhosts` :

```yaml
vhosts:
  - test2:
    nginx_servername: test2
    nginx_port: 8082
    nginx_webroot: /var/www/html/test2
    nginx_index_content: "<h1>teeeeeest 2</h1>"
  - test3:
    nginx_servername: test3
    nginx_port: 8083
    nginx_webroot: /var/www/html/test3
    nginx_index_content: "<h1>teeeeeest 3</h1>"
```

----

```yaml
➜  Ansible git:(master) ✗ cat inventories/vagrant_lab/host_vars/node1.tp2.cloud.yml 
common_packages:
  - vim
  - git
  - rsync

add_vhosts:
  - test1:
    nginx_servername: testnode33
    nginx_port: 8080
    nginx_webroot: /var/www/html/testnode33
    nginx_index_content: "<h1>teeeeeestnode3</h1>"
  - test2:
    nginx_servername: test23
    nginx_port: 8081
    nginx_webroot: /var/www/html/test23
    nginx_index_content: "<h1>teeeeeest 2</h1>"
  - test3:
    nginx_servername: test33
    nginx_port: 8082
    nginx_webroot: /var/www/html/test33
    nginx_index_content: "<h1>teeeeeest 3</h1>"

remove_vhosts:
  - test3:
    nginx_servername: test33
    nginx_port: 8082
    nginx_webroot: /var/www/html/test33
    nginx_index_content: "<h1>teeeeeest 3</h1>"% 
```

```yaml
➜  Ansible git:(master) ✗ cat inventories/vagrant_lab/host_vars/node2.tp2.cloud.yml
common_packages:
  - vim
  - git
  - rsync

add_vhosts:
  - test1:
    nginx_servername: testnode334
    nginx_port: 8080
    nginx_webroot: /var/www/html/testnode334
    nginx_index_content: "<h1>teeeeeestnode3</h1>"
  - test2:
    nginx_servername: test234
    nginx_port: 8081
    nginx_webroot: /var/www/html/test234
    nginx_index_content: "<h1>teeeeeest 2</h1>"
  - test3:
    nginx_servername: test334
    nginx_port: 8082
    nginx_webroot: /var/www/html/test334
    nginx_index_content: "<h1>teeeeeest 3</h1>"

remove_vhosts:
  - test2:
    nginx_servername: test234
    nginx_port: 8081
    nginx_webroot: /var/www/html/test234
    nginx_index_content: "<h1>teeeeeest 2</h1>"%   
```

```yaml
➜  Ansible git:(master) ✗ cat roles/nginx/tasks/remove_vhosts.yml 
- name: Remove webroot
  become: yes
  file:
    path: "{{ item.nginx_webroot }}"
    state: absent
  with_items: '{{ remove_vhosts }}'

- name: Remove index
  become: yes
  file:
    path: "{{ item.nginx_webroot }}/index.html"
    state: absent
  with_items: '{{ remove_vhosts }}'

- name: Remove NGINX Virtual Host
  become: yes
  file: 
    path: /etc/nginx/conf.d/{{ item.nginx_servername }}.conf
    state: absent
  with_items: '{{ remove_vhosts }}'
```

```yaml
➜  Ansible git:(master) ✗ cat roles/nginx/tasks/add_vhosts.yml 
- name: Create webroot
  become: yes
  file:
    path: "{{ item.nginx_webroot }}"
    state: directory
  with_items: '{{ add_vhosts }}'

- name: Create index
  become: yes
  copy:
    dest: "{{ item.nginx_webroot }}/index.html"
    content: "{{ item.nginx_index_content }}"
  with_items: '{{ add_vhosts }}'

- name: NGINX Virtual Host
  become: yes
  template:
    src: vhost.conf.j2
    dest: /etc/nginx/conf.d/{{ item.nginx_servername }}.conf
  with_items: '{{ add_vhosts }}'
```

➜ **Ajoutez une mécanique de `handlers/`**

- c'est un nouveau dossier à placer dans le rôle
- je vous laisse découvrir la mécanique par vous-mêmes et la mettre en place
- vous devez trigger un *handler* à chaque fois que la conf NGINX est modifiée
- vérifiez le bon fonctionnement
  - vous pouvez voir avec un `systemctl status` depuis quand une unité a été redémarrée

```yaml
➜  Ansible git:(master) cat roles/nginx/handlers/main.yml 
- name: Restart nginx
  become: yes
  service:
    name: nginx
    state: restarted%  
```

```yaml
➜  Ansible git:(master) cat roles/nginx/tasks/config.yml 
- name : Main NGINX config file
  become: yes
  copy:
    src: nginx.conf # pas besoin de préciser de path, il sait qu'il doit chercher dans le dossier files/
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx
```

## 2. Common

➜ **On revient sur le rôle `common`**, les utilisateurs déployés doivent** :

- avoir un password
- avoir un homedir
- avoir accès aux droits de `root` *via* `sudo`
- être dans un groupe `admin`
- avoir une clé SSH publique déposé dans leur `authorized_keys`

> Toutes ces données doivent être stockées dans les `group_vars`.

## 3. Dynamic loadbalancer

➜  **Créez un nouveau rôle : `webapp`**

- ce rôle déploie une application Web de votre choix, peu importe
- elle déploie aussi le serveur web nécessaire pour que ça tourne
  - vous pouvez clairement réutiliser le rôle NGINX d'avant qui déploie une bête page HTML

> Vraiment, peu importe, une bête page HTML, ou un truc open source comme un NextCloud. Ce qu'on veut, c'est simplement une interface visible.

➜  **Créez un nouveau rôle : `rproxy` (pour \*reverse proxy\*)**

- ce rôle déploie un NGINX
- NGINX est automatiquement configuré pour agir comme un reverse proxy vers une liste d'IP qu'on lui fournit en variables
  - à priori, vous allez gérer ça avec des `host_vars` et `group_vars`

➜ **Effectuez le déploiement suivant :**

- deux machines portent le rôle `webapp`
- une machine porte le rôle `rproxy`
- faites en sorte que :
  - si on déploie une nouvelle machine qui porte le rôle `webapp`, la conf du reverse proxy se met à jour en fonction
  - si on supprime une machine `webapp`, la conf du reverse proxy se met aussi à jour en fonction

> La configuration de votre loadbalancer devient dynamique, et plus aucune connexion manuelle n'est nécessaire pour ajuster la taille du parc en fonction de la charge.

# IV. Bonus : Aller plus loin

## 1. Vault Ansible

Afin de ne pas stocker de données sensibles en clair dans les fichiers Ansible, comme des mots de passe, on peut utiliser les [vault Ansible](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

Cela permet de stocker ces données, mais dans des fichiers chiffrés, à l'intérieur du dépôt Ansible.

➜ **Utilisez les Vaults pour stocker les clés publiques des utilisateurs**

## 2. Support de plusieurs OS

**Il est possible qu'un rôle donné fonctionne pour plusieurs OS.** Pour ça, on va utiliser des conditions en fonction de l'OS de la machine de destination.

A chaque fois qu'on déploie de la conf sur une machine, cette dernière nous donne beaucoup d'informations à son sujet : ses ***facts***. Par exemple, on récupère la liste des cartes réseau de la machine, la liste des utilisateurs, l'OS utilisé, etc.

On peut alors récupérer ces variables dans nos tasks, pour les insérer dans des templates par exemple, ou encore effectuer du travail conditionnel :

```yaml
  - name: Install apache
    apt: 
      name: apache
      state: latest
    when: ansible_distribution == 'Debian' or ansible_distribution == 'Ubuntu'

  - name: Install apache
    yum: 
      name: httpd # le nom du paquet est différent sous CentOS
      state: latest
    when: ansible_distribution == 'CentOS'
```



➜ **Ajoutez une machine d'un OS différent à votre `Vagrantfile` et adaptez vos playbooks**

- passez sur une CentOS si vous étiez sur une base Debian jusqu'alors
- ou vice-versa