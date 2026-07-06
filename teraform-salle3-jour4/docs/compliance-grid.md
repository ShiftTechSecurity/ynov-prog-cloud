# Grille de conformite - NordCloud Salle 3

Cette grille presente une conformite cible pour le TP. Elle ne remplace pas un audit juridique ou une qualification officielle.

## RGPD

| Principe | Mesure v1 | Preuve dans le projet |
| --- | --- | --- |
| Minimisation | Pas de donnee personnelle dans le code Terraform, les variables ou les outputs. | `variables.tf`, `outputs.tf`, `user_data/` |
| Confidentialite | Le tier donnees est prive et accessible uniquement depuis le tier application. | `modules/network`, `modules/security` |
| Securite du traitement | Chiffrement KMS des volumes racine et volumes sensibles app/db. | `aws_kms_key`, `root_block_device`, `aws_ebs_volume` |
| Limitation des acces | SSH limite au CIDR admin ; aucun acces public app/db. | `admin_cidr`, regles SG |
| Tracabilite | Tags communs pour identifier projet, owner, environnement et gestion Terraform. | `locals.tf` |
| Conservation | Retention non automatisee en v1 ; a definir pour snapshots, logs et sauvegardes. | Point d'amelioration v2 |

## ISO 27017

| Controle cloud attendu | Mesure v1 | Preuve dans le projet |
| --- | --- | --- |
| Responsabilite partagee | Le client gere IAM, SG, chiffrement, tagging et code IaC. | `docs/security-note.md` |
| Segmentation des environnements | VPC dedie et separation presentation/application/donnees. | `modules/network` |
| Controle des flux | Flux explicites Internet -> web, web -> app, app -> db. | `modules/security` |
| Controle des identites | Role EC2 minimal, pas de politique administrateur. | `modules/iam` |
| Durcissement cloud | IMDSv2 obligatoire sur les instances EC2. | `modules/compute/main.tf` |
| Exploitabilite | Outputs d'audit et documentation des flux. | `outputs.tf`, `README.md` |

## SecNumCloud

SecNumCloud est une qualification ANSSI d'un service cloud. Cette v1 applique des principes inspires de SecNumCloud, mais ne peut pas etre declaree qualifiee SecNumCloud car elle tourne sur AWS dans un cadre pedagogique.

| Attendu inspire SecNumCloud | Mesure v1 | Limite |
| --- | --- | --- |
| Cloud de confiance | Documentation de la cible et des mesures de securite. | Hebergeur qualifie non demontre dans cette v1. |
| Isolation | Subnets prives pour app/db et absence d'IP publique sur les donnees. | Isolation mono-region, mono-AZ pour simplifier le TP. |
| Administration maitrisee | SSH restreint a `admin_cidr`. | Un bastion ou VPN serait preferable en production. |
| Chiffrement | KMS avec rotation et volumes chiffres. | Gestion complete du cycle de vie des cles a formaliser. |
| Tracabilite | Tags et documentation d'audit. | Logs centralises a ajouter en v2. |
| Reversibilite | Infrastructure decrite en IaC, donc recreable. | Strategie d'export des donnees a documenter pour une production. |

## References

- CNIL - Les six grands principes du RGPD : https://www.cnil.fr/fr/comprendre-le-rgpd/les-six-grands-principes-du-rgpd
- ISO - ISO/IEC 27017, controles de securite pour les services cloud : https://www.iso.org/standard/43757.html
- ANSSI - Referentiels de qualification, dont SecNumCloud v3.2 : https://cyber.sites.beta.gouv.fr/offre-de-service/solutions-certifiees-et-qualifiees/comprendre-levaluation-de-securite/qualification-de-produit-et-services/referentiels-qualification/
