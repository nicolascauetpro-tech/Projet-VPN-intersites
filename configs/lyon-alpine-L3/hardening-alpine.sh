#!/bin/sh
# Nom du script : hardening-alpine.sh
# Rôle : Sécurisation système, SSH et installation Pare-feu
# Auteur : Nicolas Cauet

# --- VARIABLES ---
ADMIN_USER="nicolas_admin"
ADMIN_GROUP="admins_reseau"

echo "--- Début du Hardening Système ---"

# 1. Mise à jour et installation des outils de sécurité
echo "--- [1/5] Installation des paquets de sécurité ---"
apk update
apk add openssh nftables doas bind-tools
# Note : on installe nftables mais on ne le configure pas encore

# 2. Activation du Forwarding (Essentiel pour ton futur VPN)
echo "--- [2/5] Hardening Kernel (sysctl) ---"
# Autorise le passage des paquets pour le routage VPN
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/vpn-forwarding.conf
# Désactive les redirections ICMP (sécurité contre l'empoisonnement de route)
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.d/vpn-forwarding.conf
sysctl -p /etc/sysctl.d/vpn-forwarding.conf

# 3. Sécurisation SSH
echo "--- [3/5] Configuration SSH durcie ---"
# Sauvegarde de la config d'origine
[ ! -f /etc/ssh/sshd_config.orig ] && cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig

# On nettoie le fichier et on applique les règles strictes
cat <<EOF > /etc/ssh/sshd_config
# Port de base (tu pourras le changer plus tard)
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key

# --- SÉCURITÉ ---
# Interdiction de se connecter en ROOT
PermitRootLogin no
# On force l'utilisation des clés SSH (plus sûr que les mots de passe)
PubkeyAuthentication yes
PasswordAuthentication yes 
# Note : on laisse PasswordAuthentication à 'yes' tant que tu n'as pas injecté ta clé !
# Une fois ta clé testée, il faudra passer à 'no'.

# Limitation du temps de connexion sans authentification
LoginGraceTime 30s
# Nombre d'essais max
MaxAuthTries 3

# Log complet des connexions
SyslogFacility AUTH
LogLevel INFO

Subsystem sftp /usr/lib/ssh/sftp-server
EOF

# Activation et démarrage
rc-update add sshd default
rc-service sshd restart

# 4. Nettoyage des services inutiles
echo "--- [4/5] Nettoyage des services ---"
# On s'assure que des services non sécurisés ne tournent pas
rc-update del telnetd default 2>/dev/null

# 5. Préparation nftables (Sans règles pour le moment)
echo "--- [5/5] Activation nftables (vide) ---"
rc-update add nftables default
echo "Nftables est installé et prêt, mais aucune règle n'est appliquée."

echo "--- Hardening terminé ---"
echo "IMPORTANT : Teste la connexion SSH de $ADMIN_USER avant de te déconnecter !"
