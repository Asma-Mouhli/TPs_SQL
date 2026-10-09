# TP1 — Correction et exécution

Le fichier à rendre pour les comptes est **01-roles-et-comptes.sql**. Il contient les trois rôles, les quatre comptes locaux, les privilèges de colonne, l'activation automatique, les vérifications, le cycle GRANT/REVOKE et les bonus. La matrice fournit le corrigé théorique et laisse « Obtenu » à compléter avec les résultats réels. Aucun test sur un serveur n'a été exécuté lors de la préparation de ce dossier.

## 1. Vérifier le logiciel

Dans ton client SQL :

```sql
SELECT VERSION();
```

Cette correction utilise **MySQL 8**. Ne l'exécute pas dans `psql` : PostgreSQL a une autre gestion des comptes. La compatibilité MariaDB annoncée dans le schéma concerne les tables ; MariaDB a une syntaxe différente pour les rôles par défaut et n'active qu'un rôle à la fois. Le script de comptes nécessite donc une adaptation sur MariaDB.

## 2. Charger la base

Ouvre un terminal dans le dossier extrait :

```bash
mysql -u root -p < Base/01-schema.sql
mysql -u root -p < Base/02-donnees.sql
mysql -u root -p -e "SELECT COUNT(*) FROM mediatheque.adherent;"
```

Le résultat attendu est **40**. Attention : le script de schéma fourni supprime puis recrée la base `mediatheque`. À utiliser uniquement sur la base d'exercice. `03-volume.sql` est destiné à la séance 2 et n'est pas nécessaire pour ce TP.

## 3. Exécuter deux fois et conserver les preuves

```bash
mysql -u root -p --table < 01-roles-et-comptes.sql > preuves-execution-1.txt 2>&1
mysql -u root -p --table < 01-roles-et-comptes.sql > preuves-execution-2.txt 2>&1
```

Vérifie l'absence d'erreurs dans les deux fichiers. Ils contiennent les sorties réelles de SHOW GRANTS et de COLUMN_PRIVILEGES demandées par le professeur. Si ton installation utilise l'authentification administrateur par socket, utilise son mode de connexion habituel (par exemple `sudo mysql`) à la place de `mysql -u root -p`.

## 4. Tester chaque compte

| Compte | Mot de passe du TP | Rôles par défaut |
|---|---|---|
| app_media | Media!2026App | role_catalogue, role_prets |
| biblio_marie | Marie!2026Bib | role_catalogue, role_prets, role_adherents |
| stagiaire | Stage!2026Med | role_catalogue |
| analyste | Stats!2026Med | role_catalogue |

Pour chaque compte, ouvre une vraie connexion, par exemple :

```bash
mysql -u app_media -p mediatheque
```

Puis :

```sql
SELECT CURRENT_USER(), CURRENT_ROLE();
```

Le rôle ne doit pas être `NONE`. Exécute les commandes de la matrice correspondant au compte. Recopie **OK** ou le numéro et SQLSTATE réellement affichés dans « Obtenu ». Une commande UPDATE acceptée reste un OK même si elle indique zéro ligne modifiée.

Pour les tests 3 et 4, encadre les deux commandes avec `START TRANSACTION;` et `ROLLBACK;` afin de ne pas modifier durablement la disponibilité de l'exemplaire 3. Après l'erreur attendue du test 4, saisis quand même `ROLLBACK;`.

### Test 12 : deux sessions

Le script principal retire déjà le droit sur les réservations à la fin du cycle. Il faut le réaccorder temporairement pour observer les deux états dans une connexion analyste.

1. Dans une session administrateur :

```sql
GRANT SELECT ON mediatheque.reservation TO 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';
```

2. Dans une nouvelle connexion `mysql -u analyste -p mediatheque` :

```sql
SELECT CURRENT_ROLE();
SELECT COUNT(*) FROM reservation;
```

Résultat attendu : OK, 8 réservations avec le jeu fourni.

3. Dans la session administrateur :

```sql
REVOKE SELECT ON mediatheque.reservation FROM 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';
```

4. Reconnecte l'analyste et répète le SELECT : refus attendu. Conserve les deux résultats. Aucun FLUSH PRIVILEGES n'est nécessaire.

## 5. Comprendre les choix

- Un **rôle** regroupe des droits liés à un métier ; un **compte** représente une identité qui se connecte.
- `GRANT UPDATE (disponible)` autorise seulement la mise à jour de cette colonne. La lecture de `id` dans le WHERE est couverte par role_catalogue.
- Les droits s'additionnent : donner role_adherents à app_media supprimerait la protection de ses coordonnées.
- Aucun DELETE n'est accordé : on conserve les emprunts et on désactive les adhérents avec `actif = 0`.
- SHOW GRANTS simple montre les rôles attribués et les privilèges directs ; la variante USING développe aussi les droits hérités.
- `USAGE ON *.*`, éventuellement affiché automatiquement par SHOW GRANTS, signifie absence de privilèges globaux. Le script n'accorde aucun privilège global.

## Sources techniques

- MySQL, privilèges : https://dev.mysql.com/doc/refman/8.0/en/privileges-provided.html
- MariaDB, différence avec les rôles MySQL : https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements/set-role
