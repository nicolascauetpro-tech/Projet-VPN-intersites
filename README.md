# Infrastructure  Réseau  Multi-sites Sécurisée

## Présentation & Objectifs

Concevoir et déployer une infrastructure réseau  multi-sites  sécurisée reliant un siège social à Lyon et une agence  à Marseille.
L'enjeu  est de garantir l'intégrité et la confidentialité des échanges de données via un tunnel VPN, tout en isolant les flux critiques grâce à une segmentation rigoureuse.

### Technologies utilisées
<ol>
  <li>Pare-feu: OPNSense site de Lyon et pfSense site  de Marseille</li>
  <li>Switch: OpenVswitch site de Lyon et pfSense site  de Marseille</li>
  <li>Routage: FRR sous alpine linux (Segmentation Lan &  inter-VLAN)</li>
  <li>VPN: IPsec IKEV2 (tunnel Site-à-Site)</li>
  <li>Emulation : GNS3</li>
  <li>Virtualisation : VMWARE Workstation</li>
</ol>

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

| Source  |      Destination      |  Protocoles | Port | Utilité | Action |
|-------------|:-----------------:|:-----------:|:----:|:-------:|-------:|
|VLAN  10 (ADMIN)|Équipements Réseaux| SSH,HHTPS,HTTP | 22,443,80 | Administration complète(GUI,SLI) | Allow |
|VLAN  10 (ADMIN)|Partout| ICMP | ANY | Diagnostic (ping,tracroute) | Allow |
|VLAN  20 (DATA)|Lan  Marseille| TCP | 445 | Partage de  fichiers (SMB) | Allow |
|LAN Marseille|VLAN 20 (DATA)| TCP | 445 | Partage de  fichiers (SMB) | Allow |
|LAN Marseille |VLAN 10| Tous | Tous | Accès interdit | Deny |
|VLAN  99 (NATIF)|Tout  le  réseau| Tous | Tous | Isolation totale | Deny  &  Log |


## Topologie
