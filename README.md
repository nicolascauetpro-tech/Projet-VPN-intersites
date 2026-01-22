# Infrastructure  Réseau  Multi-sites Sécurisée(EN COURS)

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
  <h2>Site B : MARSEILLE</h2>
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

## 2. Matrices de Flux (Règles de filtrage)

### A. Lyon - Switch L3 / Routeur (Alpine nftables)

| Interface | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **VLAN 10** | IN | `10.1.8.0/26` | `10.1.0.0/21` | Tous | Tous | **ALLOW** | Admin Lyon -> Serveurs locaux |
| **VLAN 20** | IN | `10.1.0.0/21` | `10.1.8.0/26` | Tous | Tous | **DENY** | Blocage accès Data -> Admin |
| **Toutes** | IN | `10.1.0.0/16` | `0.0.0.0/0` | Tous | Tous | **ALLOW** | Autorise la sortie vers OPNSense |
| **VLAN 999** | IN | Any | Any | Tous | Tous | **REJECT** | Sécurité ports non utilisés |

### B. Lyon - Pare-feu (OPNSense)

| Interface | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **LAN** | IN | `10.1.0.0/16` | `10.2.0.0/22` | Tous | Tous | **ALLOW** | Autorise l'entrée dans le VPN |
| **LAN** | IN | `10.1.0.0/16` | `Any` | TCP | 80, 443 | **ALLOW** | Navigation Web (Breakout local) |
| **IPsec** | IN | `10.2.0.0/22` | `10.1.0.0/21` | TCP | 445 | **ALLOW** | Marseille -> SMB Lyon |
| **IPsec** | IN | `10.2.0.0/22` | `10.1.8.0/26` | Tous | Tous | **DENY** | Marseille -> Interdit vers Admin |

### C. Marseille - Switch L2 (Alpine nftables)

| Interface | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Bridge** | IN | `10.2.0.0/22` | `10.2.0.0/22` | Tous | Tous | **DENY** | Isolation Intra-VLAN (Poste à poste) |
| **eth1-5** | IN | `10.2.0.0/22` | `Any` | ARP/IP | Tous | **ALLOW** | Autorise la montée vers pfSense |

### D. Marseille - Pare-feu (pfSense)

| Interface | Sens | Source | Destination | Protocole | Port | Action | Utilité |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **LAN** | IN | `10.2.0.0/22` | `10.1.0.0/16` | Tous | Tous | **ALLOW** | Autorise l'entrée dans le VPN |
| **LAN** | IN | `10.2.0.0/22` | `Any` | Tous | Tous | **ALLOW** | Navigation Web Marseille |
| **IPsec** | IN | `10.1.8.0/26` | `10.2.0.0/22` | Tous | Tous | **ALLOW** | Admin Lyon -> Gestion Marseille |
| **IPsec** | IN | `10.1.0.0/21` | `10.2.0.0/22` | TCP | 445 | **ALLOW** | Lyon -> SMB Marseille |
