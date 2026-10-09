# TP1 — Administration et sécurité de la médiathèque

**Étudiante : Asma Mouhli — B2 Informatique**  
**Environnement vérifié : MySQL 8.0.46 — Docker**

## Objectif

Configurer les comptes et les rôles de la base `mediatheque`, limiter les accès selon les fonctions et vérifier les autorisations de chaque compte.

## Contenu du dossier

| Fichier | Contenu |
|---|---|
| `01-roles-et-comptes.sql` | Création des rôles et comptes, attribution des privilèges, vérifications et cycle GRANT/REVOKE. |
| `matrice-de-tests.md` | Douze tests, résultats réellement observés et réponses aux questions. |
| `PROCEDURE-DE-TESTS.md` | Chargement de la base, exécution du script et vérification des comptes. |
| `Base/01-schema.sql` | Schéma de la base fourni avec le cours. |
| `Base/02-donnees.sql` | Jeu de données fourni avec le cours. |
| `Base/03-volume.sql` | Script de volume pour la séance 2, non nécessaire au TP1. |

## Configuration réalisée dans le script

- Trois rôles : catalogue, prêts et adhérents.
- Quatre comptes locaux : application, bibliothécaire, stagiaire et analyste.
- Privilèges limités à certaines colonnes pour l’application et le stagiaire.
- Activation des rôles par défaut à la connexion.
- Inspection avec `SHOW GRANTS` et `information_schema.COLUMN_PRIVILEGES`.
- Attribution puis retrait de la lecture des réservations pour l’analyste.
- Bonus : compte analyste limité au réseau `192.168.1.%` et alternatives de fin de stage.

Les comptes et mots de passe sont destinés à une base d’exercice. Le script de schéma supprime puis recrée cette base.

## État des vérifications

Les douze tests de la matrice sont conformes aux attentes. Les rôles par défaut sont actifs dès la connexion. Le script a été exécuté deux fois sans erreur ; des avertissements sont présents dans les sorties, sans détail relevé. Les preuves de ces deux exécutions, incluant SHOW GRANTS et COLUMN_PRIVILEGES, sont dans `Preuves/`. Les résultats des tests par compte sont transcrits dans la matrice à partir des sorties observées. Le compte réseau est configuré mais sa connexion distante n’a pas été testée.

## Ordre d’exécution

1. `Base/01-schema.sql`
2. `Base/02-donnees.sql`
3. `01-roles-et-comptes.sql`
4. Tests décrits dans `PROCEDURE-DE-TESTS.md`.

Les commentaires et en-têtes des scripts de base sont conservés.
