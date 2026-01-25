#!/bin/sh
# Nom du script : base-system-final.sh
# Rôle : Hardening complet Alpine Linux
# Auteur : Nicolas Cauet

ADMIN_USER="nicolas_admin"
ADMIN_GROUP="admins_reseau"

echo "--- DEBUT DU HARDENING SYSTEME ---"

# 1. Verification reseau (Sans cacher les erreurs ici, on veut savoir si ca rate !)
echo "--- [1/7] Test reseau ---"
ping -c 2 8.8.8.8 || { echo "Erreur Ping"; exit 1; }
nslookup google.com || { echo "Erreur DNS"; exit 1; }

# 2. Installation des paquets
echo "--- [2/7] Installation outils et OVS ---"
apk update
apk add doas openssh nftables bind-tools openvswitch

# 3. Utilisateur et Groupe
echo "--- [3/7] Gestion des acces ---"
grep -q "^$ADMIN_GROUP:" /etc/group || addgroup -S $ADMIN_GROUP

if ! grep -q "^$ADMIN_USER:" /etc/passwd; then
    adduser -D $ADMIN_USER
    echo "Utilisateur $ADMIN_USER cree."
fi
# Ici on cache l'erreur car si l'user est deja dans le groupe, ce n'est pas grave
addgroup $ADMIN_USER $ADMIN_GROUP 2>/dev/null

# 4. Droits DOAS
echo "--- [4/7] Configuration DOAS ---"
mkdir -p /etc/doas.d
echo "permit persist :$ADMIN_GROUP" > /etc/doas.d/doas.conf
chown root:root /etc/doas.d/doas.conf
chmod 600 /etc/doas.d/doas.conf

# 5. SSH Hardening (Interdiction ROOT)
echo "--- [5/7] Configuration SSH (Root interdit) ---"
[ ! -f /etc/ssh/sshd_config.orig ] && cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig

cat <<EOF > /etc/ssh/sshd_config
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
LoginGraceTime 30s
MaxAuthTries 3
EOF

rc-update add sshd default
rc-service sshd restart

# 6. Activation OVS et Firewall
echo "--- [6/7] Activation des services ---"
rc-update add nftables default
rc-update add ovsdb-server default
rc-update add ovs-vswitchd default

# 7. Securite additionnelle
echo "--- [7/7] Verrouillage final ---"
# On pourrait verrouiller root ici, mais attention a bien avoir configure le mot de passe de ton admin avant !
echo "RAPPEL : Changez le mot de passe de $ADMIN_USER avec 'passwd $ADMIN_USER'"

echo "--- CONFIGURATION TERMINEE ---"
