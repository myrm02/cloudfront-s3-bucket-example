#Pré-requis

- Avoir Terraform installé
- Avoir AWS CLI installé
- Avoir AWS ToolKit installé sur VS Code ou autres IDE
- Avoir un compte AWS

#Pour déployer le projet via Terraform

- Rendez-vous sur le dossier /infra avec la commande "cd infra"
- Actionner les commandes suivantes : terraform init -> terraform plan -> terraform apply

Si la deuxième commande est réussi, vous pouvez regarder dans votre console AWS>S3 la bucket créer et dans la console AWS>CloudFront les distributions crées. Sur la console AWS>S3, lorsque vous vous rendez dans l'onglet "Propriétés" et scroller jusqu'à la section "Hébergements sites web statiques", vous verrez le lien pour accéder au site.
Après cela, vous pouvez supprimer les ressources si vous le souhaité avec la commande "terraform destroy" toujours dans le dossier /infra.
