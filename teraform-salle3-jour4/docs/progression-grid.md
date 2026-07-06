# Grille de progression finale - Opération NordCloud

**Équipe RTT : Robin, Thomas, Tristan**  
**Projet : Salle 3 Jour 4 - Architecture 3 tiers NordCloud**  
**État final : 100 % validé**

Ce document clôture la progression du dernier TP. Les livrables techniques, le déploiement, les captures, la documentation de sécurité et la cartographie de conformité sont finalisés.

## Synthèse finale

| Salle | Statut final | Validation | Preuves |
| --- | --- | --- | --- |
| Salle 1 - Audit des coûts | Terminé | Code validé `12435`. Les principes FinOps ont été repris dans la note de coûts et dans les choix d'architecture. | [`codes-salles.md`](./codes-salles.md), [`cost-note.md`](./cost-note.md) |
| Salle 2 - Conformité | Terminé | Codes validés `212112` pour le parcours A et `231` pour le parcours B. Les recommandations RGPD, ISO 27017 et SecNumCloud ont été intégrées à la conception. | [`codes-salles.md`](./codes-salles.md), [`compliance-grid.md`](./compliance-grid.md), [`security-note.md`](./security-note.md) |
| Salle 3 - Dossier de mission | Terminé | Architecture 3 tiers documentée, codée et commentée. | [`../README.md`](../README.md), [`architecture-3tiers.html`](./architecture-3tiers.html) |
| Salle 4 - Reconstruction / Déploiement | Terminé | Déploiement réalisé avec succès sur AWS. Les captures confirment les instances, le VPC et l'application fonctionnelle. | [`../screenshots`](../screenshots) |
| Salle 5 - Audit final | Terminé | Livrables consolidés, conformité documentée et preuves d'exécution disponibles. | Ce document, README, docs et screenshots |

## Preuves de déploiement

| Preuve | Fichier | Ce que la capture valide |
| --- | --- | --- |
| Schéma d'architecture 3 tiers | [`architecture-3tiers-4k.png`](../screenshots/architecture-3tiers-4k.png) | Vue cible complète : web, API, base PostgreSQL, NAT, SG, IAM, KMS, EBS et workflows. |
| Application NordCloud | [`nordcloud-web-api-postgresql.png`](../screenshots/nordcloud-web-api-postgresql.png) | Nginx sert le frontend, l'API répond, PostgreSQL stocke et restitue les messages. |
| Instances EC2 | [`aws-ec2-instances-3tiers.png`](../screenshots/aws-ec2-instances-3tiers.png) | Les trois instances `web`, `app` et `db` sont présentes et démarrées. |
| VPC resource map | [`aws-vpc-resource-map.png`](../screenshots/aws-vpc-resource-map.png) | Le VPC, les trois subnets, les route tables, l'Internet Gateway et le NAT Gateway sont créés. |

## Codes de validation

| Salle | Code | Statut |
| --- | --- | --- |
| Salle 1 - Audit des coûts | `12435` | Terminé |
| Salle 2 - Parcours A | `212112` | Terminé |
| Salle 2 - Parcours B | `231` | Terminé |

Les codes sont centralisés dans [`codes-salles.md`](./codes-salles.md).

## Checklist technique finale

- [x] VPC dédié `172.20.0.0/16`
- [x] Subnet public de présentation `172.20.10.0/24`
- [x] Subnet privé application `172.20.20.0/24`
- [x] Subnet privé données `172.20.30.0/24`
- [x] Internet Gateway pour l'accès public contrôlé au tier web
- [x] NAT Gateway pour le bootstrap des tiers privés
- [x] Route tables séparées public / application / données
- [x] Security Groups en couches
- [x] Flux Internet -> Web limité aux ports 80/443
- [x] Flux SSH limité au `admin_cidr`
- [x] Flux Web -> API limité au port 8080
- [x] Flux API -> PostgreSQL limité au port 5432
- [x] Aucune IP publique sur les tiers application et données
- [x] Instances EC2 Amazon Linux 2023
- [x] Frontend Nginx fonctionnel
- [x] API Python Flask/Gunicorn fonctionnelle
- [x] PostgreSQL 15 fonctionnel
- [x] Volumes racine EC2 chiffrés
- [x] Volumes EBS sensibles app/db chiffrés
- [x] Clé KMS dédiée avec rotation activée
- [x] IAM minimal pour les instances
- [x] IMDSv2 obligatoire sur EC2
- [x] Tags communs de traçabilité
- [x] Outputs d'audit
- [x] Workflows OpenTofu `plan`, `apply` et `destroy`
- [x] README final avec équipe RTT et captures
- [x] Schéma HTML 4K finalisé
- [x] Documentation sécurité, conformité, coûts et progression

## Checklist conformité finale

- [x] RGPD - minimisation des données dans le code et les outputs
- [x] RGPD - cloisonnement du tier données
- [x] RGPD - chiffrement des volumes contenant des données sensibles
- [x] RGPD - limitation des accès administratifs
- [x] RGPD - traçabilité par tags et documentation
- [x] ISO 27017 - séparation des responsabilités cloud documentée
- [x] ISO 27017 - segmentation réseau claire
- [x] ISO 27017 - contrôle des flux entre couches
- [x] ISO 27017 - IAM à privilège minimal
- [x] ISO 27017 - durcissement EC2 avec IMDSv2
- [x] SecNumCloud - principes d'isolation repris
- [x] SecNumCloud - administration maîtrisée par CIDR
- [x] SecNumCloud - chiffrement et rotation KMS
- [x] SecNumCloud - réversibilité par infrastructure as code
- [x] Limite explicitée : cette v1 pédagogique AWS ne revendique pas une qualification SecNumCloud officielle

## Livrables finalisés

| Livrable | Statut |
| --- | --- |
| Code OpenTofu/Terraform commenté | Terminé |
| Modules `network`, `security`, `iam`, `compute`, `scheduler` | Terminé |
| User-data `web.sh`, `app.sh`, `db.sh` | Terminé |
| README principal du TP | Terminé |
| Schéma d'architecture HTML 4K | Terminé |
| Captures de déploiement | Terminé |
| Note de sécurité | Terminé |
| Grille de conformité | Terminé |
| Codes des Salles 1 et 2 | Terminé |
| Note de coûts | Terminé |
| Grille de progression finale | Terminé |
| Workflows GitHub Actions OpenTofu | Terminé |

## Conclusion d'audit

Le dernier TP est finalisé à 100 %.  
La Salle 4 est validée par le déploiement AWS et les captures dans `../screenshots`.  
La Salle 5 est validée par la consolidation des livrables, la documentation d'audit et l'application des recommandations RGPD, ISO 27017 et SecNumCloud.

La solution reste une v1 pédagogique : elle démontre les bonnes pratiques attendues pour l'exercice, tout en documentant clairement les limites qui resteraient à traiter pour une production certifiable.
