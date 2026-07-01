# Ynov Prog Cloud

Repository des travaux pratiques Terraform/OpenTofu pour le cours de programmation cloud.

## TP Jour 1 - Bases Terraform AWS

Dossier : `terraform-tp-jour1`

Ce premier TP présente le fonctionnement de base de Terraform/OpenTofu avec AWS.

Il crée une infrastructure simple composée de :

- un VPC AWS
- un subnet dans `eu-west-1a`
- trois instances EC2
- une data source pour récupérer une AMI Amazon Linux 2023
- un backend S3 distant pour stocker le state Terraform

L'objectif est de comprendre la structure classique d'un projet Terraform :

- `providers.tf` pour la configuration du provider et du backend
- `variables.tf` pour les valeurs réutilisables
- `data.tf` pour les données récupérées depuis AWS
- `main.tf` pour les ressources d'infrastructure
- `outputs.tf` pour les valeurs affichées en sortie

Ce TP introduit aussi les pipelines GitHub Actions avec OpenTofu.
Le pipeline permet de formatter, linter, valider et planifier l'infrastructure depuis le dossier Terraform configuré.

Le state distant est stocké dans S3 afin de pouvoir exécuter OpenTofu localement ou depuis GitHub Actions sans perdre l'état de l'infrastructure.

Résultat attendu :

- un VPC créé dans AWS
- un subnet attaché au VPC
- trois instances EC2 déployées dans le subnet
- un state stocké dans le backend S3 configuré

Questions / réponses :

- Question : Que se passe-t-il si vous relancez `terraform apply` sans avoir modifié votre code ? Pourquoi Terraform ne recrée-t-il pas l'instance ?
  Réponse : Rien n'est recréé, car Terraform compare le code au state et voit que l'infrastructure est déjà conforme.

- Question : À quoi sert le fichier `.terraform.lock.hcl` créé par `terraform init` ? Doit-on le committer dans Git ? Pourquoi ?
  Réponse : Il verrouille les versions exactes des providers. En projet partagé, il se commit pour garder les mêmes versions partout.

- Question : Quelle est la différence entre un bloc `resource` et un bloc `data` en Terraform ? Donnez un exemple de chacun tiré de ce TP.
  Réponse : `resource` crée ou gère une ressource, comme `aws_instance`. `data` lit une information existante, comme `aws_ami`.

- Question : Pourquoi ne doit-on jamais committer le fichier `terraform.tfvars` dans Git ? Et le fichier `terraform.tfstate` ? Quelle est la différence entre les deux ?
  Réponse : `terraform.tfvars` peut contenir des valeurs sensibles. `terraform.tfstate` contient l'état réel, IDs et attributs. Les deux peuvent exposer des informations privées.

## TP Jour 2 - TP1 IAM et credentials restreints

Pas de dossier Terraform dédié.

Ce TP porte sur les credentials cloud, les utilisateurs limités et le principe du moindre privilège.

Il couvre :

- la création d'un utilisateur cloud limité
- la génération de credentials API restreints
- le test d'actions refusées
- l'importance de credentials limités dans une CI/CD

Questions / réponses :

- Question : Quel est le risque si vous utilisez un token avec `/*` sur tous les endpoints ?
  Réponse : Le token peut agir presque partout. S'il fuit, l'impact peut toucher tout le compte ou tout le projet.

- Question : Dans un pipeline CI/CD, comment injecteriez-vous ces credentials de façon sécurisée ?
  Réponse : Avec des secrets GitHub Actions ou OIDC, jamais dans le code, les commits, les fichiers tfvars ou les logs.

## TP Jour 2 - TP2 Security Groups

Dossier : `terraform-tp2-jour2`

Ce TP porte sur les Security Groups AWS et l'accès public à un serveur web.

Il crée une petite infrastructure web composée de :

- un VPC dédié
- un subnet public
- une internet gateway
- une route table publique
- une instance EC2
- un Security Group web
- un fichier `terraform.auto.tfvars` pour les variables du TP

Le Security Group autorise :

- HTTP sur le port `80` depuis Internet
- HTTPS sur le port `443` depuis Internet
- SSH sur le port `22` depuis l'IP publique configurée
- le trafic sortant vers Internet

L'instance EC2 utilise Amazon Linux 2023 et installe `nginx` via `user_data`.
Cela permet de vérifier la règle HTTP en ouvrant l'URL publique générée.

Le TP reste volontairement simple :

- pas de module
- pas de load balancer
- pas de NAT gateway
- pas d'injection complexe de variables dans le pipeline

Les valeurs `prenom` et `my_ip` sont fournies via `terraform.auto.tfvars`.
Le fichier est volontairement suivi par Git pour que GitHub Actions puisse exécuter la même configuration à distance.

Résultat attendu :

- une instance EC2 publique
- un Security Group web attaché à l'instance
- SSH restreint au CIDR configuré
- un output `web_url` ouvrable dans un navigateur

Questions / réponses :

- Question : Quel est le rôle principal du Security Group dans ce TP ?
  Réponse : Il filtre les connexions autorisées vers l'instance EC2.

- Question : Pourquoi HTTP et HTTPS sont-ils ouverts à Internet ?
  Réponse : Parce que le serveur web doit être accessible depuis un navigateur.

- Question : Pourquoi SSH est-il limité à une IP précise ?
  Réponse : Pour éviter d'exposer l'accès d'administration à tout Internet.

## TP Jour 2 - TP3 Architecture 3-tiers

Dossier : `terraform-tp3-jour2`

Ce TP étend le travail sur les Security Groups avec une architecture 3-tiers.

Il crée trois tiers applicatifs avec `for_each` :

- `web`
- `api`
- `db`

L'infrastructure contient :

- un VPC
- un subnet public
- un subnet privé
- une internet gateway
- une route table publique
- trois instances EC2 créées depuis la map `tiers`
- trois Security Groups créés depuis la même map `tiers`
- un backend S3 distant dédié au TP3

Le modèle de Security Groups suit un flux applicatif classique :

- `sg-web` accepte HTTP `80` et HTTPS `443` depuis Internet
- `sg-web` accepte SSH `22` depuis l'IP publique configurée
- `sg-api` accepte le port `8080` uniquement depuis `sg-web`
- `sg-db` accepte PostgreSQL `5432` uniquement depuis `sg-api`

Le modèle réseau sépare les ressources publiques et privées :

- `web` est déployé dans le subnet public avec une IP publique
- `api` est déployé dans le subnet public avec une IP publique
- `db` est déployé dans le subnet privé sans IP publique

Le concept Terraform principal du TP est `for_each`.
La map `tiers` définit le rôle, le type de subnet et le comportement d'IP publique de chaque tier.
Modifier cette map permet de faire évoluer l'architecture de façon lisible.

Résultat attendu :

- trois instances EC2 nommées par tier
- trois Security Groups distincts
- un chaînage réseau web vers api, puis api vers db
- aucune IP publique pour l'instance database
- un output `architecture` qui résume les noms, rôles, IP privées, IP publiques et Security Groups

Questions / réponses :

- Question : Pourquoi la DB n'a-t-elle pas d'IP publique ? Quel risque cela évite-t-il ?
  Réponse : Elle n'a pas besoin d'être accessible depuis Internet. Cela évite les scans, attaques directes et expositions inutiles.

- Question : `remote_group_id` vs `remote_ip_prefix` : quelle est la différence ? Dans quel cas préfère-t-on l'un ou l'autre ?
  Réponse : Un groupe source cible les ressources d'un Security Group. Un CIDR cible une plage IP. On utilise SG-to-SG pour les tiers internes, CIDR pour Internet ou une IP d'administration.

- Question : Si vous supprimez le tier `api` de `var.tiers` et faites `terraform apply`, que se passe-t-il avec les tiers `web` et `db` ? (`for_each` vs `count`)
  Réponse : Terraform détruit `api` et ses dépendances. `web` et `db` gardent leur identité, car `for_each` utilise des clés stables et non des index.

## TP Jour 3 - TP1 Terragrunt dev/prod

Dossiers :

- `terraform-tp1-jour3`
- `terragrunt-tp1-jour3`

Comme un pipeline OpenTofu avait déjà été mis en place lors du jour 1, ce TP pousse la logique CI/CD plus loin avec Terragrunt.
L'objectif est de réutiliser le code Terraform du TP3 du jour 2, puis de le variabiliser pour permettre le déploiement de deux environnements distincts : `dev` et `prod`.

Le dossier `terraform-tp1-jour3` contient le code Terraform réutilisable.
Il décrit l'infrastructure 3-tiers sans porter directement la configuration propre à un environnement.
Les valeurs qui changent entre `dev` et `prod` sont fournies par Terragrunt.

Le dossier `terragrunt-tp1-jour3` contient deux configurations :

- `dev/terragrunt.hcl`
- `prod/terragrunt.hcl`

Chaque environnement pointe vers le même code Terraform avec `source`, mais fournit ses propres inputs :

- `environment`
- `aws_region`
- `vpc_cidr`
- `public_subnet_cidr`
- `private_subnet_cidr`

Cela permet de conserver une seule base Terraform tout en générant des ressources séparées par environnement.
La variable `environment` est intégrée dans les noms et tags des ressources AWS afin d'éviter les collisions entre `dev` et `prod`.

Exemples de séparation :

- `dev` utilise le réseau `172.18.0.0/16`
- `prod` utilise le réseau `172.19.0.0/16`
- le state `dev` est stocké dans une clé S3 dédiée
- le state `prod` est stocké dans une clé S3 dédiée

Le backend S3 est déclaré côté Terraform avec un bloc vide :

```hcl
backend "s3" {}
```

La configuration réelle du backend est fournie par Terragrunt avec `remote_state`.
Cela permet à chaque environnement d'utiliser le même module Terraform avec un state différent.

Six workflows GitHub Actions Terragrunt ont été créés afin de séparer clairement les actions par environnement :

- `terragrunt-dev-plan.yaml`
- `terragrunt-dev-apply.yaml`
- `terragrunt-dev-destroy.yaml`
- `terragrunt-prod-plan.yaml`
- `terragrunt-prod-apply.yaml`
- `terragrunt-prod-destroy.yaml`

Les pipelines exécutent :

- le formatage OpenTofu du code Terraform
- le formatage Terragrunt des fichiers HCL
- TFLint
- Checkov
- Trivy
- `tofu validate` avec initialisation sans backend
- `terragrunt validate`
- `terragrunt plan`, `apply` ou `destroy` selon le workflow

Résultat attendu :

- un même code Terraform réutilisé pour plusieurs environnements
- des ressources AWS nommées avec l'environnement
- des CIDR différents entre `dev` et `prod`
- des states S3 séparés
- des pipelines CI/CD Terragrunt dédiés par environnement

Question de réflexion :

- Question : Pourquoi le job `apply` ne doit-il jamais se déclencher directement sur une Pull Request, mais uniquement après un merge sur `main` ?
  Réponse : Une Pull Request est une phase de revue et de validation. Elle peut provenir d'une branche non validée et contenir du code encore en discussion. Déclencher un `apply` à ce moment pourrait modifier l'infrastructure avant validation humaine et avant intégration officielle. Le `merge` sur `main` marque la décision de déployer une version acceptée du code.

## TP Jour 3 - TP2 KMS et volumes EBS chiffrés

Dossiers :

- `terraform-tp2-jour3`
- `terragrunt-tp2-jour3`

Le sujet initial du TP porte sur KMS et le chiffrement d'un volume.
Dans ce repository, l'exercice a été adapté sur AWS afin de rester cohérent avec les TPs précédents.
Le code reprend l'architecture 3-tiers déjà utilisée, puis ajoute le chiffrement avec AWS KMS et des volumes EBS chiffrés.

L'objectif est de créer, pour chaque environnement Terragrunt :

- une clé KMS AWS dédiée
- un alias KMS lisible
- un volume EBS chiffré de `20 Go` pour chaque instance EC2
- un attachement de chaque volume EBS à l'instance correspondante

Comme les environnements `dev` et `prod` ont chacun leur propre configuration Terragrunt et leur propre state S3, chaque environnement crée sa propre clé KMS et ses propres volumes chiffrés.
Il n'y a donc pas de partage de clé entre `dev` et `prod`.

Le dossier `terraform-tp2-jour3` contient le code Terraform réutilisable.
Les ressources ajoutées pour ce TP sont :

- `aws_kms_key.ebs`
- `aws_kms_alias.ebs`
- `aws_ebs_volume.encrypted_data`
- `aws_volume_attachment.encrypted_data`

La clé KMS active la rotation automatique avec :

```hcl
enable_key_rotation = true
```

Les volumes EBS sont créés avec :

```hcl
size       = 20
type       = "gp3"
encrypted  = true
kms_key_id = aws_kms_key.ebs.arn
```

Le dossier `terragrunt-tp2-jour3` contient deux environnements :

- `dev/terragrunt.hcl`
- `prod/terragrunt.hcl`

Chaque environnement pointe vers le même code Terraform :

```hcl
source = "../../terraform-tp2-jour3"
```

Les states sont séparés :

- `prog-cloud/terraform-tp2-jour3/dev/terraform.tfstate`
- `prog-cloud/terraform-tp2-jour3/prod/terraform.tfstate`

Les CIDR restent séparés entre les environnements :

- `dev` utilise le réseau `172.18.0.0/16`
- `prod` utilise le réseau `172.19.0.0/16`

Résultat attendu :

- une architecture 3-tiers AWS par environnement
- une clé KMS différente pour `dev` et `prod`
- un alias KMS nommé avec l'environnement
- trois volumes EBS chiffrés par environnement
- chaque volume EBS attaché à son instance EC2
- des outputs affichant la clé KMS et les volumes chiffrés

Vérification :

- dans AWS KMS, vérifier la présence de la clé et de son alias
- dans EC2 > Volumes, vérifier que les volumes EBS sont chiffrés
- vérifier que la clé KMS utilisée correspond à celle créée par Terraform
- vérifier les outputs `kms_key_id`, `kms_key_arn` et `encrypted_ebs_volumes`

## Pipelines OpenTofu

Les workflows GitHub Actions dans `.github/workflows` exécutent OpenTofu sur le dossier TP configuré avec `CONFIG_DIRECTORY`.

Workflows disponibles :

- `opentofu-plan.yaml`
- `opentofu-apply.yaml`
- `opentofu-destroy.yaml`

Les workflows utilisent les credentials AWS stockés dans les secrets GitHub Actions :

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Ordre d'exécution attendu :

1. lancer `OpenTofu Plan`
2. relire les ressources prévues
3. lancer `OpenTofu Apply`
4. vérifier les ressources dans AWS
5. lancer `OpenTofu Destroy` à la fin du TP
