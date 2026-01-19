# Infrastructure  Réseau  Multi-sites Sécurisée

## Présentation & Objectifs

Concevoir et déployer une infrastructure réseau  multi-sites  sécurisée reliant un siège social à Lyon et une agence  à Marseille.
L'enjeu  est de garantir l'intégrité et la confidentialité des échanges de données via un tunnel VPN, tout en isolant les flux critiques grâce à une segmentation rigoureuse.

### Technologies utilisées
<ul>
  <h2>Site A : LYON</h2>
  <li>Pare-feu: OPNSense/nftables sous Alpine Linux</li>
  <li>Switch: OpenVswitch sous Alpine linux</li>
  <li>Routage: FRR sous alpine linux (Segmentation Lan &  inter-VLAN)</li>
  <li>VPN: IPsec IKEV2 (tunnel Site-à-Site) sous OPNSense</li>
  <li>Emulation : GNS3</li>
  <li>Virtualisation : VMWARE Workstation</li>
  <h2>Site B : LYON</h2>
  <li>Pare-feu: pfSense/nftables sous Alpine Linux</li>
  <li>Switch: OpenVswitch sous Alpine linux</li>
  <li>Routage: pfSense (Segmentation Lan &  inter-VLAN)</li>
  <li>VPN: IPsec IKEV2 (tunnel Site-à-Site) sous pfSense</li>
  <li>Emulation : GNS3</li>
  <li>Virtualisation : VMWARE Workstation</li>
</ul>

### Plan d'adressage IP

### Site  A : Lyon  (10.1.0.0/16)

| Zone/VLAN   |      Réseau(CIDR)      |  Paserelle | Rôle | Site |
|-------------|:----------------------:|:----------------:|:----:|-----:|
|VLAN  20 (DATA)|10.1.0.0/21|10.1.7.254| Postes  employés et serveurs(2046 IPs) | Lyon|
|VLAN  10 (ADMIN)|10.1.8.0/26|10.1.8.62| Postes administrateurs (62 IPs) | Lyon|
|VLAN  99 (NATIF)||| Pour les trames non taguées sécurité lien trunks |Lyon|
|VLAN  999 (POUBELLE)||| Pour les ports non utilisés |Lyon|
|Interco alpine/OPNSense |10.1.8.64/30| - | Lien d'interconnexion entre L3 et pare-feu| Lyon|
|Interco WAN |DHCP GNS3|| Lien  WAN  entre OPNSense et Cloud GNS3 |Lyon|

### Site  B : Marseille  (10.2.0.0/16)

| Zone/VLAN   |      Réseau(CIDR)      |  Paserelle | Rôle | Site |
|-------------|:----------------------:|:----------------:|:----:|-----:|
|Lan Marseille|10.2.0.0/22|10.2.3.254| Postes employés |Marseille|
|Interco WAN|DHCP GNS3|-| Lien d'interconnexion entre pfsense et Cloud GNS3 |Marseille|
|VLAN  99 (NATIF)||| Pour les trames non taguées |Marseille|
|VLAN  999 (POUBELLE)||| Pour les ports non utilisés |Marseille|


### Matrice de flux de  sécurité
## 1. Matrice de Lyon : nftables (Alpine L3)

| Interface (SVI) | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **VLAN 10** | IN | `10.1.8.0/26` | `10.1.0.0/21` | Tous | Tous | **ALLOW** | Admin vers serveurs locaux |
| **VLAN 20** | IN | `10.1.0.0/21` | `10.1.8.0/26` | Tous | Tous | **DENY** | Isolation Admin (Sécurité interne) |
| **VLAN 10/20** | IN | `10.1.0.0/16` | `0.0.0.0/0` | Tous | Tous | **FORWARD** | Sortie vers OPNSense (Route par défaut) |
| **VLAN 999** | IN | Any | Any | Tous | Tous | **REJECT** | VLAN Poubelle (Ports non utilisés) |

## 2. Matrice de Lyon : Pare-feu (OPNSense)

| Interface | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **LAN (Transit)** | IN | `10.1.8.0/26` | `10.2.0.0/22` | Tous | Tous | **ALLOW** | Admin Lyon -> Agence Marseille (VPN) |
| **LAN (Transit)** | IN | `10.1.0.0/21` | `10.2.0.0/22` | TCP | 445 | **ALLOW** | SMB Lyon -> Agence Marseille |
| **LAN (Transit)** | IN | `10.1.0.0/16` | Any (WAN) | HTTP/S | 80, 443 | **ALLOW** | Navigation Web Lyon (NAT) |
| **IPsec (VPN)** | IN | `10.2.0.0/22` | `10.1.0.0/21` | TCP | 445 | **ALLOW** | Agence Marseille -> Serveurs Data Lyon |
| **IPsec (VPN)** | IN | `10.2.0.0/22` | `10.1.8.0/26` | Tous | Tous | **DENY** | Interdire Marseille vers Admin Lyon |

## 3. Matrice de Marseille : Pare-feu (pfSense)

| Interface | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **LAN** | IN | `10.2.0.0/22` | `10.1.0.0/21` | TCP | 445 | **ALLOW** | Accès SMB Agence -> Lyon |
| **LAN** | IN | `10.2.0.0/22` | Any (WAN) | Tous | Tous | **ALLOW** | Navigation Web Marseille |
| **IPsec (VPN)** | IN | `10.1.8.0/26` | `10.2.0.0/22` | Tous | Tous | **ALLOW** | Autoriser Admin distant (Lyon) |
| **IPsec (VPN)** | IN | `10.1.0.0/21` | `10.2.0.0/22` | TCP | 445 | **ALLOW** | Flux SMB Lyon -> Marseille |
