# TP1 — Matrice de tests

**Environnement observé : MySQL 8.0.46, conteneur Docker `mysql-tp`.**

Les douze tests ont été exécutés avec les comptes concernés. Les sorties transmises confirment les résultats ci-dessous. Les rôles par défaut étaient actifs à chaque connexion. Les modifications du test 3 ont été annulées par `ROLLBACK`.

## `app_media` — l'application web

| # | Commande | Attendu | Code / résultat attendu | Obtenu |
|---|---|---|---|---|
| 1 | `SELECT id, nom, prenom FROM adherent LIMIT 5;` | OK | OK | OK — 5 lignes |
| 2 | `SELECT email FROM adherent LIMIT 1;` | refus | ERROR 1143 (42000) | ERROR 1143 (42000): SELECT command denied to user 'app_media'@'localhost' for column 'email' in table 'adherent' |
| 3 | `UPDATE exemplaire SET disponible = 0 WHERE id = 3;` | OK | OK | OK — 1 ligne modifiée, puis ROLLBACK |
| 4 | `UPDATE exemplaire SET etat = 'use' WHERE id = 3;` | refus | ERROR 1143 (42000) | ERROR 1143 (42000): UPDATE command denied to user 'app_media'@'localhost' for column 'etat' in table 'exemplaire' |
| 5 | `DELETE FROM emprunt WHERE id = 1;` | refus | ERROR 1142 (42000) | ERROR 1142 (42000): DELETE command denied to user 'app_media'@'localhost' for table 'emprunt' |

Les tests 3 et 4 portent sur la **même table** : c'est la colonne qui fait la différence.

## `biblio_marie` — la bibliothécaire

| # | Commande | Attendu | Code / résultat attendu | Obtenu |
|---|---|---|---|---|
| 6 | `SELECT nom, email, telephone FROM adherent LIMIT 3;` | OK | OK | OK — 3 lignes |
| 7 | `CREATE USER 'test'@'localhost' IDENTIFIED BY 'Test!2026';` | refus | ERROR 1227 (42000) | ERROR 1227 (42000): Access denied; you need (at least one of) the CREATE USER privilege(s) for this operation |

## `stagiaire`

| # | Commande | Attendu | Code / résultat attendu | Obtenu |
|---|---|---|---|---|
| 8 | `SELECT nom, prenom, ville FROM adherent LIMIT 5;` | OK | OK | OK — 5 lignes |
| 9 | `SELECT email FROM adherent LIMIT 1;` | refus | ERROR 1143 (42000) | ERROR 1143 (42000): SELECT command denied to user 'stagiaire'@'localhost' for column 'email' in table 'adherent' |
| 10 | `SELECT * FROM adherent LIMIT 1;` | refus | ERROR 1142 (42000) | ERROR 1142 (42000): SELECT command denied to user 'stagiaire'@'localhost' for table 'adherent' |

**Question :** les tests 9 et 10 échouent tous les deux, mais pas avec le même numéro d'erreur. Pourquoi ?

> Le test 9 demande explicitement email : le refus est observé au niveau de cette colonne (1143). Le test 10 demande toutes les colonnes avec SELECT * alors que le compte ne possède pas SELECT sur toute la table : le refus observé est au niveau table (1142). Les deux protègent les données interdites ; ces deux codes ont été observés sur MySQL 8.0.46.

## `analyste`

| # | Commande | Attendu | Code / résultat attendu | Obtenu |
|---|---|---|---|---|
| 11 | `SELECT COUNT(*) FROM adherent;` | refus | ERROR 1142 (42000) | ERROR 1142 (42000): SELECT command denied to user 'analyste'@'localhost' for table 'adherent' |
| 12 | `SELECT COUNT(*) FROM reservation;` | après le `GRANT` : OK — après le `REVOKE` : refus | Après GRANT : OK ; après REVOKE : ERROR 1142 (42000) | Après GRANT : OK — COUNT(*) = 8. Après REVOKE : ERROR 1142 (42000): SELECT command denied to user 'analyste'@'localhost' for table 'reservation' |

## Conclusion

Une phrase : **parmi les quatre comptes, lequel peut encore faire quelque chose qu'il ne fera jamais — et comment le lui retireriez-vous ?**

>
> L’analyste reçoit avec role_catalogue la lecture des exemplaires et des catégories. Si ses statistiques ne nécessitent que les ouvrages et les emprunts, ces lectures sont superflues : je lui retirerais role_catalogue et lui accorderais directement SELECT sur ouvrage, en conservant SELECT sur emprunt. Cette réduction dépend de ses besoins réels ; elle n'est pas appliquée dans le script car le TP demande l'accès au catalogue.

```sql
-- Proposition uniquement si le besoin est confirmé, à ne pas appliquer
-- pour les tests du profil demandé par le TP :
REVOKE 'role_catalogue' FROM 'analyste'@'localhost';
GRANT SELECT ON mediatheque.ouvrage TO 'analyste'@'localhost';
-- Appliquer aussi au compte réseau si la même décision le concerne.
```

## Vérifications complémentaires réalisées

- `analyste` : `SELECT COUNT(*) FROM emprunt;` autorisé, résultat : **130**.
- Base initiale : `SELECT COUNT(*) FROM mediatheque.adherent;` donne **40**.
- Rôles actifs : application = catalogue + prêts ; bibliothécaire = catalogue + prêts + adhérents ; stagiaire et analyste = catalogue.
- Script exécuté deux fois : aucune erreur dans les deux sorties. Certaines commandes indiquent un avertissement dont le détail n'a pas été relevé.
- `SHOW GRANTS` et les **11 lignes** de `COLUMN_PRIVILEGES` figurent dans les preuves d'exécution jointes.
- Le droit temporaire de lecture des réservations a été retiré ; le refus final est confirmé.

Le compte réseau est défini dans le script ; aucune connexion depuis le réseau `192.168.1.%` n'a été testée.
