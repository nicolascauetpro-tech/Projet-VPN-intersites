# Infrastructure  Réseau  Multi-sites Sécurisée

## Présentation & Objectifs

Concevoir et déployer une infrastructure réseau  multi-sites  sécurisée reliant un siège social à Lyon et une agence  à Marseille.
L'enjeu  est de garantir l'intégrité et la confidentialité des échanges de données via un tunnel VPN, tout en isolant les flux critiques grâce à une segmentation rigoureuse.

### Technologies utilisées
<ol>
  <li>Pare-feu: OPNSense site de Lyon et pfSense site  de Marseille</li>
  <li>Routage: VyOS (Segmentation Lan &  inter-VLAN)</li>
  <li>VPN: IPsec IKEV2 (tunnel Site-à-Site)</li>
  <li>Emulation : GNS3</li>
  <li>Virtualisation : VMWARE Workstation</li>
</ol>

### Plan d'adressage IP

| Zone/VLAN   |      Réseau(CIDR)      |  Paserelle(VyOS) | Rôle |
|-------------|:----------------------:|:----------------:|-----:|
|VLAN  10 (ADMIN)|192.168.10.0/24|192.168.10.254| Gestion des  équipements |
|VLAN  20 (DATA)|192.168.20.0/24|192.168.20.254| Postes  employés et serveurs |
|VLAN  99 (NATIF)||| Pour les trames non taguées |
|Interco WAN |10.0.0.0/30|| Lien  WAN  entre pare-feux |
|LAN Agence |192.168.30.0/24|192.168.30.254| Utilisateurs distants (Marseille) |

### Matrice de flux de  sécurité

| Source  |      Destination      |  Protocoles | Utilité | Action |
|-------------|:-----------------:|:-----------:|:-------:|-------:|

## Topologie
