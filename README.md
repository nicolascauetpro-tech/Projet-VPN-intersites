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
<h2>1. Matrice de Lyon : Cœur de Réseau (Alpine L3)</h2>
<table>
    <thead>
        <tr>
            <th>Interface (SVI)</th>
            <th>Sens</th>
            <th>Source</th>
            <th>Destination</th>
            <th>Protocole</th>
            <th>Port</th>
            <th>Action</th>
            <th>Utilité</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><b>VLAN 10</b></td>
            <td>IN</td>
            <td><code>10.1.8.0/26</code></td>
            <td><code>10.1.0.0/21</code></td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Admin vers serveurs locaux</td>
        </tr>
        <tr>
            <td><b>VLAN 20</b></td>
            <td>IN</td>
            <td><code>10.1.0.0/21</code></td>
            <td><code>10.1.8.0/26</code></td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #d73a49; font-weight: bold;">DENY</span></td>
            <td>Isolation Admin (Sécurité interne)</td>
        </tr>
        <tr>
            <td><b>VLAN 10/20</b></td>
            <td>IN</td>
            <td><code>10.1.0.0/16</code></td>
            <td><code>0.0.0.0/0</code></td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #005cc5; font-weight: bold;">FORWARD</span></td>
            <td>Sortie vers OPNSense (Route par défaut)</td>
        </tr>
        <tr>
            <td><b>VLAN 999</b></td>
            <td>IN</td>
            <td>Any</td>
            <td>Any</td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #d73a49; font-weight: bold;">REJECT</span></td>
            <td>VLAN Poubelle (Ports non utilisés)</td>
        </tr>
    </tbody>
</table>

<h2>2. Matrice de Lyon : Pare-feu (OPNSense)</h2>
<table>
    <thead>
        <tr>
            <th>Interface</th>
            <th>Sens</th>
            <th>Source</th>
            <th>Destination</th>
            <th>Protocole</th>
            <th>Port</th>
            <th>Action</th>
            <th>Utilité</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><b>LAN (Transit)</b></td>
            <td>IN</td>
            <td><code>10.1.8.0/26</code></td>
            <td><code>10.2.0.0/22</code></td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Admin Lyon -> Agence Marseille (VPN)</td>
        </tr>
        <tr>
            <td><b>LAN (Transit)</b></td>
            <td>IN</td>
            <td><code>10.1.0.0/21</code></td>
            <td><code>10.2.0.0/22</code></td>
            <td>TCP</td>
            <td>445</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>SMB Lyon -> Agence Marseille</td>
        </tr>
        <tr>
            <td><b>LAN (Transit)</b></td>
            <td>IN</td>
            <td><code>10.1.0.0/16</code></td>
            <td>Any (WAN)</td>
            <td>HTTP/S</td>
            <td>80, 443</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Navigation Web Lyon (NAT)</td>
        </tr>
        <tr>
            <td><b>IPsec (VPN)</b></td>
            <td>IN</td>
            <td><code>10.2.0.0/22</code></td>
            <td><code>10.1.0.0/21</code></td>
            <td>TCP</td>
            <td>445</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Agence Marseille -> Serveurs Data Lyon</td>
        </tr>
        <tr>
            <td><b>IPsec (VPN)</b></td>
            <td>IN</td>
            <td><code>10.2.0.0/22</code></td>
            <td><code>10.1.8.0/26</code></td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #d73a49; font-weight: bold;">DENY</span></td>
            <td>Interdire Marseille vers Admin Lyon</td>
        </tr>
    </tbody>
</table>

<h2>3. Matrice de Marseille : Pare-feu (pfSense)</h2>
<table>
    <thead>
        <tr>
            <th>Interface</th>
            <th>Sens</th>
            <th>Source</th>
            <th>Destination</th>
            <th>Protocole</th>
            <th>Port</th>
            <th>Action</th>
            <th>Utilité</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><b>LAN</b></td>
            <td>IN</td>
            <td><code>10.2.0.0/22</code></td>
            <td><code>10.1.0.0/21</code></td>
            <td>TCP</td>
            <td>445</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Accès SMB Agence -> Lyon</td>
        </tr>
        <tr>
            <td><b>LAN</b></td>
            <td>IN</td>
            <td><code>10.2.0.0/22</code></td>
            <td>Any (WAN)</td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Navigation Web Marseille</td>
        </tr>
        <tr>
            <td><b>IPsec (VPN)</b></td>
            <td>IN</td>
            <td><code>10.1.8.0/26</code></td>
            <td><code>10.2.0.0/22</code></td>
            <td>Tous</td>
            <td>Tous</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Autoriser Admin distant (Lyon)</td>
        </tr>
        <tr>
            <td><b>IPsec (VPN)</b></td>
            <td>IN</td>
            <td><code>10.1.0.0/21</code></td>
            <td><code>10.2.0.0/22</code></td>
            <td>TCP</td>
            <td>445</td>
            <td><span style="color: #28a745; font-weight: bold;">ALLOW</span></td>
            <td>Flux SMB Lyon -> Marseille</td>
        </tr>
    </tbody>
</table>
