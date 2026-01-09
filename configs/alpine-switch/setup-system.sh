#!/bin/sh

#================================================================================
# Nom du script : setup-system.sh
# Rôle : Automatiser la  sécurisation  et  l'installation d'OVS/FRR
# Auteur : Nicolas Cauet
# Projet : VPN  Intersites

echo "--- Début de la configuration  système ---"

# 1. Vérifications de la présence des dépôts Main et Community

cat /etc/apk/repositories

# 2. Vérifications du fonctionnement internet sur  eth0
ip a
ping 8.8.8.8
dig google.com

# 3.  Mise  à jour des paquets

apk update

# 4.Création d'un utilisateur pour l'administration

adduser -D admin_reseau

# 4. Ajout de l'utilisateur créer pour l'administration dans le groupe wheel

addgroup admin_reseau wheel

# 5. Création du fichier doas.conf pour permettre l'exécution des commandes par l'utilisateur administrateur.

mkdir -p /etc/doas.d/doas.conf

## Propriétaire du fichier 

chown root:root  /etc/doas.d/doas.conf

## Réstriction des accès au fichier

chmod 600 /etc/doas.d/doas.conf

## Ajout de la ligne suivante

echo "permit :wheel" > /etc/doas.d/doas.conf


