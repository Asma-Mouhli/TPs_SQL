# Travaux pratiques — SQL avancé

Ce dépôt regroupe les travaux pratiques de SQL avancé réalisés en Bachelor 2 Informatique à Ynov Lyon, autour d'une base MySQL de gestion de médiathèque.

Les trois TP abordent la sécurité des accès, les vues et l'optimisation des requêtes, puis la programmation stockée pour gérer les emprunts et les retours.

## TP1 — Comptes, rôles et privilèges

Ce TP porte sur la gestion des accès à la base et l'application du principe du moindre privilège : chaque utilisateur reçoit les droits nécessaires à ses missions.

Les manipulations concernent notamment :

- la création de comptes MySQL et la distinction entre un utilisateur et son hôte ;
- l'attribution et le retrait de privilèges avec `GRANT` et `REVOKE` ;
- la création et l'attribution de rôles ;
- la vérification des droits avec `SHOW GRANTS`, `CURRENT_USER()` et `CURRENT_ROLE()` ;
- les essais d'opérations autorisées et interdites avec les comptes concernés.

Les scripts, la procédure de tests et les preuves associées sont regroupés dans le dossier [TP1](./TP1/).

## TP2 — Vues et optimisation par les index

Ce TP porte sur la présentation des données au moyen de vues et l'amélioration des performances des requêtes.

Les travaux concernent notamment :

- la création et l'utilisation de vues ;
- les conditions permettant de modifier les données à travers une vue ;
- les restrictions d'écriture avec `WITH CHECK OPTION` ;
- l'analyse des plans d'exécution avec `EXPLAIN` ;
- le choix d'index adaptés aux filtres et aux recherches ;
- la comparaison des plans avant et après la création des index.

L'analyse s'appuie notamment sur les colonnes `type`, `possible_keys`, `key`, `rows` et `Extra` du résultat d'`EXPLAIN`. Les estimations du moteur doivent être distinguées du nombre de lignes réellement renvoyées.

Les fichiers de ce TP sont regroupés dans le dossier [TP2](./TP2/).

## TP3 — Fonctions, procédures et triggers

Ce TP a pour objectif d'encadrer les emprunts et les retours de documents à l'aide de fonctions stockées, de procédures et de triggers.

### Partie personnelle : consignes 1, 2 et 3

Les fichiers préparés dans [TP3](./TP3/) sont :

| Fichier | Contenu |
|---|---|
| [01-fonctions.sql](./TP3/01-fonctions.sql) | Fonctions de calcul et requête de synthèse |
| [02-procedures.sql](./TP3/02-procedures.sql) | Procédures d'emprunt, de retour et de bilan |

Les trois fonctions sont :

| Fonction | Rôle |
|---|---|
| `f_nb_emprunts_en_cours` | Compter les documents non rendus d'un adhérent |
| `f_penalites_dues` | Calculer les pénalités impayées et renvoyer `0.00` en leur absence |
| `f_jours_de_retard` | Calculer le retard d'un emprunt en cours ou déjà rendu |

Les trois procédures sont :

| Procédure | Rôle |
|---|---|
| `p_emprunter` | Vérifier les conditions du prêt et renvoyer l'identifiant créé dans un paramètre `OUT` |
| `p_rendre` | Enregistrer un retour et créer une pénalité de 0,20 € par jour de retard si nécessaire |
| `p_bilan_adherent` | Renvoyer trois jeux de résultats : fiche de l'adhérent, emprunts en cours et nombre total d'emprunts |

La procédure d'emprunt contrôle l'existence et l'activité de l'adhérent, l'état et la disponibilité de l'exemplaire, le quota de cinq prêts et le plafond de 10 € de pénalités impayées. Les procédures de prêt et de retour utilisent une transaction et un handler d'erreur avec `ROLLBACK` et `RESIGNAL`.

### Travail du binôme et intégration

Les triggers et le scénario de tests sont pris en charge par le binôme. Les triggers doivent notamment calculer les dates manquantes, maintenir la disponibilité des exemplaires et journaliser les opérations.

**Les triggers doivent être installés avant les tests d'emprunt et de retour.** Les procédures leur délèguent volontairement la mise à jour de `exemplaire.disponible`.

## Environnement et exécution

- MySQL 8 et base `mediatheque` issue des fichiers de schéma et de données du cours.
- Client MySQL pour exécuter les scripts contenant `DELIMITER`.
- Compte disposant des privilèges nécessaires à la création des objets SQL.

Depuis le client MySQL ouvert à la racine du dépôt, les fonctions et procédures du TP3 se chargent dans cet ordre :

```sql
SOURCE TP3/01-fonctions.sql;
SOURCE TP3/02-procedures.sql;
```



