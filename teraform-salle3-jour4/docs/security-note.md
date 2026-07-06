# Note de securite - NordCloud Salle 3

Cette note explique les choix techniques de la v1. Elle doit permettre a l'equipe de justifier l'architecture pendant l'audit final.

## Security Groups

Les flux sont limites par couche :

| Flux | Autorisation |
| --- | --- |
| Internet -> web | TCP 80/443 |
| admin CIDR -> web | TCP 22 |
| web -> app | TCP 8080, source SG web |
| app -> db | TCP 5432, source SG app |
| Internet -> app/db | refuse |
| web -> db direct | refuse |

Le tier donnees n'a pas d'adresse IP publique et se trouve dans un subnet prive.

La logique appliquee est le moindre privilege reseau : chaque couche ne recoit que le flux necessaire a son role.

Les trois tiers ont aussi une sortie HTTP/HTTPS et DNS controlee pour le bootstrap systeme. Les tiers prives passent par un NAT Gateway : ils peuvent installer leurs paquets sans etre exposes en entree depuis Internet.

## IAM

Les instances EC2 recoivent un instance profile dedie. La politique IAM custom autorise seulement `cloudwatch:PutMetricData` dans le namespace `NordCloud/Salle3`.

L'option d'extinction programmee non-prod cree un role distinct pour EventBridge Scheduler. Ce role autorise uniquement `ec2:StartInstances` et `ec2:StopInstances` sur les instances gerees par ce dossier.

## Chiffrement

Une cle KMS dediee est creee avec rotation automatique. Elle chiffre :

- les volumes racine EC2 ;
- les volumes EBS de donnees attaches aux tiers `app` et `db`.

## Secrets applicatifs

Le mot de passe PostgreSQL de l'utilisateur `nordcloud_app` est fourni via la variable sensible `db_app_password`. Il est encode en base64 dans le user-data pour eviter de casser les fichiers systemd ou les commandes SQL avec des caracteres speciaux.

- En local : `TF_VAR_db_app_password`.
- Dans GitHub Actions : secret `DB_APP_PASSWORD`.

Comme ce secret est injecte dans le user-data, le state Terraform doit rester protege dans le backend distant. Il ne faut pas commiter de fichier `terraform.tfstate`.

## Durcissement EC2

IMDSv2 est obligatoire sur les instances (`http_tokens = required`). Les ressources sont taguees pour faciliter l'audit, la responsabilite et le suivi FinOps.

## Points hors v1

Ces points sont recommandes pour une v2 ou une production :

- bastion ou VPN a la place du SSH direct ;
- journalisation centralisee CloudWatch Logs ;
- sauvegardes et snapshots chiffres avec retention explicite ;
- VPC endpoints ou mecanisme de patching controle pour les subnets prives ;
- supervision applicative et alertes d'incident.
