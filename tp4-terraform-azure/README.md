# Terraform

**Dans ce TP on va explorer une utilisation basique de Terraform.**

Dans notre cas, on va utiliser Azure (sorry). On va donc explorer un peu la plateform Azure et ses concepts, avant d'y déployer des machins avec Terraform.

On utilisera ensuite Terraform pour automatiser la création de machines dans Azure.

# Sommaire

- [Terraform](#terraform)
- [Sommaire](#sommaire)
- I. Azure
  - [1. Une première VM](#1-une-première-vm)
  - [2. Azure CLI](#2-azure-cli)
- II. Terraform
  - [1. Un premier plan](#1-un-premier-plan)
  - [2. Do it](#2-do-it)
  - [3. Do it yourself](#3-do-it-yourself)
  - [4. Bonus](#4-bonus)

# I. Azure

## 1. Une première VM

➜ **Avant de passer à la suite, il sera nécessaire d'activer votre offre Azure for Students.**

On va utiliser un peu l'interface graphique Web d'Azure pour créer vos premières VMs.
 N'allez pas trop loin dans la configuration ce n'est pas l'objectif du TP.

Pour ce faire, **depuis la WebUI** :

➜ **Créer un \*Resource Group\***

➜ **Créer une \*Virtual Machine\***

- appartient au *Resource Group* précédemment créé
- je vous conseille les instances "B1Sl" qui vous coûteront rien ou quasiment rien
- placez une clé SSH publique à vous
- peu importe le reste de la config

➜ **Une fois la VM déployée, assurez-vous que vous pouvez vous y connecter en SSH**

## 2. Azure CLI

La WebUI, c'est gentil, mais c'est SI LENT. On va s'approcher d'une démarche un peu plus programmatique en utilisant le Azure CLI.

Le Azure CLI est un outil qui permet de mettre en placer toutes les fonctionnalités d'Azure, mais depuis la ligne de commande.

➜ Je vous laisse suivre **[la documentation officielle](https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli)** pour l'installer sur votre PC

➜ **Une fois installé...**

- assurez-vous d'avoir la commande `az` dispo dans votre shell préféré

- **exécutez un `az login`** pour vous connecter à votre compte Microsoft depuis la ligne de commande.

- ```
  az
  ```

   est un CLI standard : 

  ```
  az <RESSOURCE> <ACTION>
  ```

  - pour lister vos *Resource Groups* : `az group list`
  - pour lister vos VMs : `az vm list`

- explorez un peu

  - `az --help`
  - `az vm --help`

Petits hints :

- `az interactive` lance le CLI en mode interactif avec plein d'auto-complétions stylées
- toutes les commandes qui output du JSON horrible peuvent être converties en un output sympa pour les humains avec `-o table`

# II. Terraform

Terraform va permettre d'automatiser la création de ressources dans Azure, *Resource Group* comme VMs, ou tout autre type de ressource que sait gérer Azure.

➜ Je vous laisse là encore suivre **[la documentation officielle de Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)** pour l'installer sur votre poste

## 1. Un premier plan

Les fichiers Terraform pourtent l'extension `.tf` et la syntaxe utilisée est appelée HCL.

> Une énième syntaxe pour simplement déclarer des clés et des valeurs :)

**On appelle \*Plan\* un fichier Terraform qui contient des ressources à créer, à l'aide d'un \*Provider\* donné.**

> Dans notre cas, on utilisera le provider `azurerm`.

Voici le minimum requis, recommandé dans la doc, pour créer une VM avec Azure en provider :

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-b3-vm1" {
  name     = "b3-vm1"
  location = "eastus"
}

resource "azurerm_virtual_network" "vn-b3-vm1" {
  name                = "b3-vm1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
}

resource "azurerm_subnet" "s-b3-vm1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg-b3-vm1.name
  virtual_network_name = azurerm_virtual_network.vn-b3-vm1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic-b3-vm1" {
  name                = "example-nic"
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.s-b3-vm1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm-b3-vm1" {
  name                = "b3-vm1"
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
  location            = azurerm_resource_group.rg-b3-vm1.location
  size                = "Standard_B1s"
  admin_username      = "it4"
  network_interface_ids = [
    azurerm_network_interface.nic-b3-vm1.id,
  ]

  admin_ssh_key {
    username   = "it4"
    public_key = file("/path/to/your/public/key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
```



➜ **Remarquez dans fichier plusieurs choses**

- le bloc `terraform {}` tout en haut du doc

  - nécessaire
  - définit notamment le *provider* nécessaire pour que l'on puisse appliquer ce *plan*

- le bloc `provider "azurerm" {}`

  - nécessaire, même si non-utilisé (comme ici)

- les blocs `resource`

  - sont les ressources que l'on souhaite créer

  - elles sont spécifiques au 

    provider

     choisi

    - par exemple, le nom `azurerm_linux_virtual_machine` est spécifique au *provider* `azurerm`

- utilisation de variables

  - plutôt que ré-écrire un truc qu'on a déjà écrit, on peut utiliser un système d'objets pour récup des trucs déjà définis

  - comme par exemple 

    ```
    azurerm_resource_group.rg-b3-vm1.location
    ```

     :

    - c'est la valeur de `location`
    - dans le *resource group* `b3-vm1`

## 2. Do it

> *Pour rappel, Terraform est à utiliser depuis votre poste. Les fichiers à créer sont donc aussi à créer sur votre poste.*

➜ **Créer un \*plan\* Terraform**

- créer un nouveau répertoire de travail

- créer un fichier 

  ```
  main.tf
  ```

  - dans le répertoire de travail
  - remplissez-le avez le fichier d'exemple présenté au dessus
  - remplacez `/path/to/your/public/key.pub` avec le chemin vers votre clé publique à déposer dans la VM
  - remplacez le nom d'utilisateur `it4` par un nom de votre choix

➜ **Depuis un shell, appliquer le plan Terraform**

- depuis un shell, se déplacer dans le répertoire de travail
- exécuter les commandes suivantes :

```shell
# Récupération du provider azurerm
$ terraform init

# Vérification de la validité du plan
$ terraform plan

# Déploiement du plan
$ terraform apply
```



➜ **Constater le déploiement**

- depuis la WebUI

- depuis le CLI 

  ```
  az
  ```

  - `az vm list`
  - `az vm show --name b3-vm1 --resource-group b3-vm1`
  - `az group list`
  - n'oubliez pas que vous pouvez ajouter `-o table` pour avoir un output plus lisible par un humain :)

➜ **Autres commandes Terraform**

```shell
# Vérifier que votre fichier .tf est valide
$ terraform validate

# Formate un fichier .tf au format standard
$ terraform fmt

# Afficher les ressources du déploiement
$ terraform state list

# Afficher les détails d'une des ressources du déploiement
$ terraform state show <RESSOURCE>

# Détruit les ressources déployées
$ terraform destroy
```



## 3. Do it yourself

🌞 **Créer un \*plan Terraform\* avec les contraintes suivantes**

- ```
  node1
  ```

  - Ubuntu 18.04
  - 1 IP Publique
  - 1 IP Privée

- ```
  node2
  ```

  - CentOS
  - 1 IP Privée

```hcl
➜  terraform git:(master) ✗ cat main.tf 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-b3-vm1" {
  name     = "b3-vm1"
  location = "eastus"
}

resource "azurerm_virtual_network" "vn-b3-vm1" {
  name                = "b3-vm1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
}

resource "azurerm_subnet" "s-b3-vm1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg-b3-vm1.name
  virtual_network_name = azurerm_virtual_network.vn-b3-vm1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "ip-public" {
  name                    = "test-pip"
  location                = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name     = azurerm_resource_group.rg-b3-vm1.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "test"
  }
}

resource "azurerm_network_interface" "nic-b3-vm1" {
  name                = "example-nic"
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.s-b3-vm1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic-b3-vm2" {
  name                = "example-nic-vm2"
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.s-b3-vm1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-public.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-b3-vm1" {
  name                = "node1"
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
  location            = azurerm_resource_group.rg-b3-vm1.location
  size                = "Standard_B1s"
  admin_username      = "leaduvigneau"
  network_interface_ids = [
    azurerm_network_interface.nic-b3-vm1.id,
  ]

  admin_ssh_key {
    username   = "leaduvigneau"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "vm-b3-vm2" {
  name                = "node2"
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
  location            = azurerm_resource_group.rg-b3-vm1.location
  size                = "Standard_B1s"
  admin_username      = "leaduvigneau"
  network_interface_ids = [
    azurerm_network_interface.nic-b3-vm2.id,
  ]

  admin_ssh_key {
    username   = "leaduvigneau"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }
}
```



- les IPs privées doivent permettre aux deux machines de se `ping`

> Pour accéder à `node2`, il faut donc d'abord se connecter à `node1`, et effectuer une connexion SSH vers `node2`. Vous pouvez l'option `-j` de SSH pour faire ~~des dingueries~~ un rebond SSH (`-j` comme Jump). `ssh -j node1 node2` vous connectera à `node2` en passant par `node1`.

```bash
➜  terraform git:(master) ✗ ssh -J leaduvigneau@20.127.131.210 leaduvigneau@10.0.2.4
The authenticity of host '20.127.131.210 (20.127.131.210)' can't be established.
ECDSA key fingerprint is SHA256:vFlEsT6FCZKKs3E81pKgP+wsrhLQ9oaRpSKlLo7CROI.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '20.127.131.210' (ECDSA) to the list of known hosts.
The authenticity of host '10.0.2.4 (<no hostip for proxy command>)' can't be established.
ECDSA key fingerprint is SHA256:HvwH+N3QBNyf6H8T6sQynNukXARcj3uLDmCe7u7aZOs.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.2.4' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 5.4.0-1073-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Tue Mar 29 15:37:04 UTC 2022

  System load:  0.0               Processes:           108
  Usage of /:   4.8% of 28.90GB   Users logged in:     0
  Memory usage: 20%               IP address for eth0: 10.0.2.4
  Swap usage:   0%

0 updates can be applied immediately.



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

leaduvigneau@node1:~$ 
```



## 4. Bonus

🌞 **Intégrer la gestion de `cloud-init`**

- faire pop une VM qui utilise `cloud-init` au premier boot
- renseignez-vous sur les OS qui supportent `cloud-init` (la plupart des OS modernes, parfois dans une version spécifique)

