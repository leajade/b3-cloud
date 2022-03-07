# TP1 : Cloud-init

[TOC]

## 0-prérequis

Pas besoin sur mac OS. 😉

## 1-premiers-pas

🌞 **Prouvez en vous connectant à la VM que les changements demandés dans le fichier cloud-init ont été effectués**

```bash
➜  tp1-cloud-init vagrant ssh     
==> vagrant: You have requested to enabled the experimental flag with the following features:
==> vagrant: 
==> vagrant: Features:  cloud_init, disks
==> vagrant: 
==> vagrant: Please use with caution, as some of the features may not be fully
==> vagrant: functional yet.
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.4.0-99-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon Feb 21 08:04:49 UTC 2022

  System load:  0.4               Processes:               120
  Usage of /:   4.4% of 38.71GB   Users logged in:         0
  Memory usage: 22%               IPv4 address for enp0s3: 10.0.2.15
  Swap usage:   0%


13 updates can be applied immediately.
10 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

vagrant@ubuntu:~$ cd /home/it4/
vagrant@ubuntu:/home/it4$ cd ..
vagrant@ubuntu:/home$ cd ..
vagrant@ubuntu:/$ ls
bin   dev  home  lib32  libx32      media  opt   root  sbin  srv  tmp  vagrant
boot  etc  lib   lib64  lost+found  mnt    proc  run   snap  sys  usr  var
vagrant@ubuntu:/$ cd home/
vagrant@ubuntu:/home$ ls
it4  vagrant
```

## 2-go-further

🌞 **Modifiez le `Vagrantfile` (ou créez en un nouveau), faites en sorte que :**

**Docker soit setup**

- Docker installé (suivez [la doc officielle pour Ubuntu](https://docs.docker.com/engine/install/ubuntu/))

- l'unité `docker.service` démarrée et active au boot de la machine (en cas de reboot)

- création d'un utilisateur dédié

  - son nom est `docker-admin`, il est membre du groupe `docker`

  - le groupe 

    ```
    docker
    ```

     est créé automatiquement à l'installation du paquet

    - ainsi, cet utilisateur doit pouvoir passer des commandes `docker` sans utiliser `sudo`

  - une clé SSH a été déployé pour pouvoir s'y connecter sans mot de passe

**La machine doit être prête à recevoir de la conf Ansible**

- `python` installé
- création d'un utilisateur dédié
  - son nom est `ansible-admin`
  - un utilisateur qui a les droits `sudo` complets
  - une clé SSH a été déployé pour pouvoir s'y connecter sans mot de passe

**La machine doit être configurée pour utiliser un serveur NTP spécifique**

- il existe des serveurs NTP libres d'accès sur internet : https://www.pool.ntp.org/fr/
- renseignez-vous pour savoir comment installer configurer un client NTP sur Ubuntu
- faites vos tests à la main, avant de mettre tout ça dans `cloud-init`



```bash
➜  tp1-cloud-init cat Vagrantfile 
Vagrant.configure("2") do |config|
  config.env.enable
  config.vbguest.auto_update = false
  config.vm.box_check_update = false

  config.vm.define "ubuntu-cloud-init"
  config.vm.box = "focal-server-cloudimg-amd64-vagrant"
  config.vm.box_url = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-vagrant.box"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.56.2"
  config.ssh.forward_agent = true
  
  config.vm.provider "virtualbox" do |v|
    v.name = "ubuntu-cloud-init"
  end
 
#  config.vm.provision "shell", path: "setup.sh"
 
  config.vm.cloud_init do |cloud_init|
    cloud_init.content_type = "text/cloud-config"
    cloud_init.path = "data.yml"
  end

end
```

```bash
➜  tp1-cloud-init cat data.yml 
#cloud-config

package_update: true
packages:
 - git

users:
 - name: leaduvigneau
   sudo: ALL=(ALL) NOPASSWD:ALL
   groups: adm,sys
   home: /home/lea
   shell: /bin/bash
   ssh-authorized-keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+8IteKPBkpW8xt879HyjoBR2a0mLFFf9JFziUO+B6nXLYjmQgt8hBRNfOhJ2nWDtHMEOJ9/yb694aCNW9vN7gSsZ95OGhc0gS2bVuPPOtnWgOahm0rHCBQhbOU8LfG1TYtzXTonQPEp8mwmkzEKBEmmEg0GTwTpER7VNl7x5O1dLfz5urZb8K2J/Fnxv0rjZoFsZC0AKzvrtRzmRB41hxlYQp584vMEosoIMrT8hrLFCmz2nVfpruZibUKwEU+joNrfVoY7YmguKQD2uA90UgmuPYuvFuCgBw/qD+3C7BXWyG9R6N7wzh5MdCVyzYNZ9Ao/PTg3CM1rH3smuE4acwFsTFtE5cauNJhVuwzNQXNznaOEQATI9Mi7OSiHheu27BgGLyrAhJmbglcKAWfkR3TZY1t7SuG6AK3mXFixwLzyI8pzSVqyS5v8HT3F08eDCCm1xruwTxuWEEqYfezWTkyu7nRYcU40qAIY3bOabjRaeiPms3s5WJk1sFMU4W65U= leaduvigneau@mbp-de-lea.home
 - name: docker-admin
   sudo: ALL=(ALL) NOPASSWD:ALL
   groups: adm,sys,docker
   home: /home/docker-admin
   shell: /bin/bash
   ssh-authorized-keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+8IteKPBkpW8xt879HyjoBR2a0mLFFf9JFziUO+B6nXLYjmQgt8hBRNfOhJ2nWDtHMEOJ9/yb694aCNW9vN7gSsZ95OGhc0gS2bVuPPOtnWgOahm0rHCBQhbOU8LfG1TYtzXTonQPEp8mwmkzEKBEmmEg0GTwTpER7VNl7x5O1dLfz5urZb8K2J/Fnxv0rjZoFsZC0AKzvrtRzmRB41hxlYQp584vMEosoIMrT8hrLFCmz2nVfpruZibUKwEU+joNrfVoY7YmguKQD2uA90UgmuPYuvFuCgBw/qD+3C7BXWyG9R6N7wzh5MdCVyzYNZ9Ao/PTg3CM1rH3smuE4acwFsTFtE5cauNJhVuwzNQXNznaOEQATI9Mi7OSiHheu27BgGLyrAhJmbglcKAWfkR3TZY1t7SuG6AK3mXFixwLzyI8pzSVqyS5v8HT3F08eDCCm1xruwTxuWEEqYfezWTkyu7nRYcU40qAIY3bOabjRaeiPms3s5WJk1sFMU4W65U= leaduvigneau@mbp-de-lea.home
 - name: ansible-admin
   sudo: ALL=(ALL) NOPASSWD:ALL
   groups: adm,sys,ansible
   home: /home/ansible-admin
   shell: /bin/bash
   ssh-authorized-keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+8IteKPBkpW8xt879HyjoBR2a0mLFFf9JFziUO+B6nXLYjmQgt8hBRNfOhJ2nWDtHMEOJ9/yb694aCNW9vN7gSsZ95OGhc0gS2bVuPPOtnWgOahm0rHCBQhbOU8LfG1TYtzXTonQPEp8mwmkzEKBEmmEg0GTwTpER7VNl7x5O1dLfz5urZb8K2J/Fnxv0rjZoFsZC0AKzvrtRzmRB41hxlYQp584vMEosoIMrT8hrLFCmz2nVfpruZibUKwEU+joNrfVoY7YmguKQD2uA90UgmuPYuvFuCgBw/qD+3C7BXWyG9R6N7wzh5MdCVyzYNZ9Ao/PTg3CM1rH3smuE4acwFsTFtE5cauNJhVuwzNQXNznaOEQATI9Mi7OSiHheu27BgGLyrAhJmbglcKAWfkR3TZY1t7SuG6AK3mXFixwLzyI8pzSVqyS5v8HT3F08eDCCm1xruwTxuWEEqYfezWTkyu7nRYcU40qAIY3bOabjRaeiPms3s5WJk1sFMU4W65U= leaduvigneau@mbp-de-lea.home

runcmd:
  - git --version > /tmp/b3_git_version
  - apt update -y
  - apt upgrade -y
  - apt-get install python3.9 -y
  - apt install docker.io -y
  - systemctl enable docker.service
  - systemctl enable containerd.service
  - apt-get install ntp -y
  - echo "pool 0.fr.pool.ntp.org" >> /etc/ntp.conf
  - service ntp restart
  - apt install ansible -y
```



## 3-ansible-again

🌞 **Déployer NGINX sur la machine avec Ansible**

```bash
➜  tp1-cloud-init cat hosts.ini 
[ynov]
192.168.56.2
```

```yaml
➜  tp1-cloud-init cat nginx.yml 
---
- name: Install nginx
  hosts: ynov
  become: yes
  tasks:
  - name: "apt-get update"
    apt:
      update_cache: yes
      cache_valid_time: 3600

  - name: "install nginx"
    apt:
      name: ['nginx']
      state: latest

  - name: Insert Index Page
    template:
      src: index.html.j2
      dest: /var/www/b3_tp1/index.html

  - name: copy nginx config file
    template: 
      src: /Users/leaduvigneau/Documents/ynov/b3/cloud/tp1-cloud-init/nginx.conf 
      dest: /etc/nginx/sites-available/default
    
  - name: enable configuration
    file: >
      dest=/etc/nginx/sites-enabled/default
      src=/etc/nginx/sites-available/default
      state=link
  
  - name: Start NGiNX
    service:
      name: nginx
      state: restarted
```

```bash
➜  tp1-cloud-init cat index.html.j2 
Hello from {{ ansible_default_ipv4.address }}
```

```bash
➜  tp1-cloud-init cat nginx.conf 
server {
        listen 8080 default_server;
        listen [::]:8080 default_server ipv6only=on;

        root /var/www/b3_tp1/;
        index index.html index.html.j2;

        server_name ynov;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

```bash
➜  tp1-cloud-init ansible-playbook -i hosts.ini nginx.yml

PLAY [Install nginx] ************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************
ok: [192.168.56.2]

TASK [apt-get update] ***********************************************************************************************
ok: [192.168.56.2]

TASK [install nginx] ************************************************************************************************
ok: [192.168.56.2]

TASK [Insert Index Page] ********************************************************************************************
ok: [192.168.56.2]

TASK [copy nginx config file] ***************************************************************************************
ok: [192.168.56.2]

TASK [enable configuration] *****************************************************************************************
ok: [192.168.56.2]

TASK [Start NGiNX] **************************************************************************************************
changed: [192.168.56.2]

PLAY RECAP **********************************************************************************************************
192.168.56.2               : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

##  4-So, here we are !

Vérifions sur ma machine virtuelle que tout est correctement déployé :

```bash
ansible-admin@ubuntu:/etc/nginx/sites-available$ curl 192.168.56.2
curl: (7) Failed to connect to 192.168.56.2 port 80: Connection refused

ansible-admin@ubuntu:/etc/nginx/sites-available$ curl 192.168.56.2:8080
Hello from 10.0.2.15

```



