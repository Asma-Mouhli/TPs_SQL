# TP1 — Matrice de tests

**Correction théorique MySQL 8 — tests non exécutés ici.** Les numéros ci-dessous sont attendus et doivent être confirmés sur ton serveur. La colonne Obtenu reste réservée aux preuves réelles.

Douze tests. Dans la colonne **Obtenu**, écrivez `OK` (la commande passe et renvoie des lignes)
ou le numéro d'erreur complet, par exemple `ERROR 1142 (42000)`.

Un test se fait **connecté avec le compte concerné** :

```
mysql -u stagiaire -p mediatheque
```

Premier réflexe à chaque connexion : `SELECT CURRENT_ROLE();`. Si la réponse est `NONE`,
les rôles ne sont pas actifs et tous les tests qui suivent vont échouer pour la mauvaise raison.

## `app_media` — l'application web

| # | Commande | Attendu | Corrigé théorique | Obtenu |
|---|---|---|---|---|
| 1 | `SELECT id, nom, prenom FROM adherent LIMIT 5;` | OK | OK | À relever |
| 2 | `SELECT email FROM adherent LIMIT 1;` | refus | ERROR 1143 (42000) | À relever |
| 3 | `UPDATE exemplaire SET disponible = 0 WHERE id = 3;` | OK | OK | À relever |
| 4 | `UPDATE exemplaire SET etat = 'use' WHERE id = 3;` | refus | ERROR 1143 (42000) | À relever |
| 5 | `DELETE FROM emprunt WHERE id = 1;` | refus | ERROR 1142 (42000) | À relever |

Les tests 3 et 4 portent sur la **même table** : c'est la colonne qui fait la différence.

## `biblio_marie` — la bibliothécaire

| # | Commande | Attendu | Corrigé théorique | Obtenu |
|---|---|---|---|---|
| 6 | `SELECT nom, email, telephone FROM adherent LIMIT 3;` | OK | OK | À relever |
| 7 | `CREATE USER 'test'@'localhost' IDENTIFIED BY 'Test!2026';` | refus | ERROR 1227 (42000) | À relever |

## `stagiaire`

| # | Commande | Attendu | Corrigé théorique | Obtenu |
|---|---|---|---|---|
| 8 | `SELECT nom, prenom, ville FROM adherent LIMIT 5;` | OK | OK | À relever |
| 9 | `SELECT email FROM adherent LIMIT 1;` | refus | ERROR 1143 (42000) | À relever |
| 10 | `SELECT * FROM adherent LIMIT 1;` | refus | ERROR 1142 (42000) | À relever |

**Question :** les tests 9 et 10 échouent tous les deux, mais pas avec le même numéro d'erreur. Pourquoi ?

> Le test 9 demande explicitement email : le refus est attendu au niveau de cette colonne (1143). Le test 10 demande toutes les colonnes avec SELECT * alors que le compte ne possède pas SELECT sur toute la table : le refus attendu est au niveau table (1142). Les deux protègent les données interdites ; relève les codes réellement affichés par ta version du serveur.

## `analyste`

| # | Commande | Attendu | Corrigé théorique | Obtenu |
|---|---|---|---|---|
| 11 | `SELECT COUNT(*) FROM adherent;` | refus | ERROR 1142 (42000) | À relever |
| 12 | `SELECT COUNT(*) FROM reservation;` | après le `GRANT` : OK — après le `REVOKE` : refus | Après GRANT : OK ; après REVOKE : ERROR 1142 (42000) | À relever |

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

## Tests complémentaires utiles

Avec stagiaire : `SELECT telephone FROM adherent;`, `SELECT date_naissance FROM adherent;`, `SELECT * FROM emprunt;` doivent être refusés. Avec analyste : `SELECT COUNT(*) FROM emprunt;` et `SELECT titre FROM ouvrage LIMIT 3;` doivent passer, mais `UPDATE emprunt SET date_retour_reelle = CURDATE() WHERE id = 1;` doit être refusé. Avec app_media : `UPDATE ouvrage SET titre = 'Test' WHERE id = 1;` doit être refusé. Ces vérifications complètent les douze tests sans remplacer les connexions réelles.
