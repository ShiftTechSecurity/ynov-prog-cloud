# Note d'optimisation des couts - NordCloud Salle 3

## Leviers appliques

| Levier Salle 1 | Application dans ce dossier |
| --- | --- |
| Rightsizing | Instance type `t3a.micro` par defaut pour limiter le cout du TP. |
| Extinction programmee | Option `enable_nonprod_schedule` pour stop/start automatique hors production. |
| Tags | Tags communs : Project, Course, Exercise, Environment, Owner, ManagedBy. |
| Cycle de vie stockage | Volumes `gp3` tailles explicitement et chiffres ; pas de stockage froid cree inutilement. |
| Aucune action inutile | Pas de Load Balancer ni base managée dans cette version de TP afin d'eviter les couts fixes. |

## Choix assumes

Un NAT Gateway est active par defaut pour permettre aux tiers prives d'installer PostgreSQL, Python et les dependances API pendant le bootstrap. Pour reduire les couts apres stabilisation, on peut le desactiver avec `enable_private_nat = false` si l'equipe utilise une AMI preparee ou une autre strategie d'installation.

L'extinction programmee est desactivee par defaut pour eviter les surprises pendant l'evaluation. Elle peut etre activee dans `terraform.auto.tfvars`.

## Risques de cout surveilles

| Risque | Action |
| --- | --- |
| Instances oubliees apres le TP | Utiliser `terraform destroy` ou activer `enable_nonprod_schedule`. |
| Volumes EBS orphelins | Les volumes sont geres par Terraform et attaches explicitement. |
| Ressources non attribuables | Les tags communs identifient l'environnement, le projet et le proprietaire. |
| Services managés couteux | Pas de Load Balancer ni base managée ; le NAT Gateway est le seul service managé coûteux retenu pour le bootstrap. |
| NAT Gateway | Actif par defaut pour le bootstrap ; a detruire apres le TP ou remplacer par une AMI preparee. |
