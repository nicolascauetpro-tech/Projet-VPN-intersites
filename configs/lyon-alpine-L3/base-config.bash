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

# 4. Création du groupe  administration avec des droits administrations

addgroup -S admins_reseau

# 4.Création de l'utilisateur pour l'administration sans mot  de passe

adduser -D nicolas_admin

# 4. Ajout de l'utilisateur créé pour l'administration dans le groupe ===== admins_reseau =====

addgroup nicolas_admin  admins_reseau

# 5. 

# 5. Création du dossier doas.d et du fichier doas.conf pour permettre l'exécution des commandes par l'utilisateur administrateur.

mkdir -p /etc/doas.d

## Propriétaire du fichier 

chown root:root  /etc/doas.d/doas.conf

## Réstriction des accès au fichier

chmod 600 /etc/doas.d/doas.conf

## Ajout de la ligne suivante

echo "permit :admins_reseau" > /etc/doas.d/doas.conf


