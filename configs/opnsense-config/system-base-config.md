# Meilleur pratique de sécurité et hardening

## Mettre à jour le système.

Les mises à jour automatiques sont désactivées.
Un contrôle manuel est rigoureux et des mises à jour devront être effectuées.
Une alerte sera configurée via une notification par email afin de prévenir une éventuelle mise à jour.

Les mises à jour suivent la procédure suivante :

### Procédure

1. Une sauvegarde automatique de la configuration est effectuée avant chaque mise à jour, avec une rétention de  7 jours.
2. Mise à jour MANUELLE via l'interface Web pendant une fenêtre de maintenance planifiée.
3. La journalisation des mises à jour est activée et conservée à des fins de traçabilité.
4. Les mises à jour NE DOIVENT pas être effectuées en journée ou en période de production.
5. Après chaque mise à jour une vérification par un contrôle fonctionnel des services critiques doit être effectué.
