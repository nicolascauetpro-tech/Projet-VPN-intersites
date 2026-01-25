#!/bin/sh
# Nom du script : hardening-alpine.sh
# Rôle : Config réseau, Admin, SSH, nftables et installation OVS
# Auteur : Nicolas Cauet

# --- VARIABLES ---
ADMIN_USER="nicolas_admin"
ADMIN_GROUP="admins_reseau"

echo "--- DÉBUT DE LA CONFIGURATION BASE SYSTÈME ---"

# 1. VÉRIFICATION RÉSEAU
echo "--- [1/7] Test de connectivité ---"
if ping -c 2 8.8.8.8 > /dev/null; then
    echo "Internet IP : OK"
else
    echo "ERREUR : Pas de réseau. Vérifiez /etc/network/interfaces"
    exit 1
fi

if nslookup google.com > /dev/null 2>&1; then
    echo "Internet DNS : OK"
else
    echo "ERREUR : DNS non fonctionnel."
    exit 1
fi

# 2. INSTALLATION DES PAQUETS
echo "--- [2/7] Installation des outils  ---"
apk update
# On installe OVS mais on ne le configure pas encore
apk add doas openssh nftables openvswitch

# 3. GESTION DES ACCÈS
echo "--- [3/7] Création de l'utilisateur et du groupe ---"
grep -q "^$ADMIN_GROUP:" /etc/group || addgroup -S $ADMIN_GROUP

if ! grep -q "^$ADMIN_USER:" /etc/passwd; then
    adduser -D $ADMIN_USER
    echo "Utilisateur $ADMIN_USER créé."
fi
addgroup $ADMIN_USER $ADMIN_GROUP 2>/dev/null

# 4. CONFIGURATION DOAS (PRIVILÈGES)
echo "--- [4/7] Configuration de DOAS ---"
mkdir -p /etc/doas.d
echo "permit persist :$ADMIN_GROUP" > /etc/doas.d/doas.conf
chown root:root /etc/doas.d/doas.conf
chmod 600 /etc/doas.d/doas.conf

# 5. SÉCURISATION SSH
echo "--- [5/7] Configuration OpenSSH sécurisée ---"
[ ! -f /etc/ssh/sshd_config.orig ] && cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig

cat <<EOF > /etc/ssh/sshd_config
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key

# Sécurité : Pas de root, on privilégie l'utilisateur admin
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes

# Paramètres de protection
LoginGraceTime 30s
MaxAuthTries 3
EOF

rc-update add sshd default
rc-service sshd restart 2>/dev/null

# 6. PRÉPARATION FIREWALL & OVS (SERVICES)
echo "--- [6/7] Activation des services au démarrage ---"
rc-update add nftables default
rc-update add ovsdb-server default
rc-update add ovs-vswitchd default

# 7. RAPPORT FINAL
echo "--- [7/7] Terminé ---"
echo "Outils installés : doas, ssh, nftables, openvswitch"
echo "Utilisateur prêt : $ADMIN_USER"
echo "------------------------------------------------------"
echo "ACTION REQUISE : passwd $ADMIN_USER"
echo "ACTION REQUISE : Copier la clé SSH ssh-copy-id -i ~/.ssh/id_ed25519.pub nicolas_admin@ADRESSE_IP_ALPINE"
echo "ACTION REQUISE : Modifier option PasswordAuthentication en no dans le fichier sshd_config"
echo "------------------------------------------------------"
