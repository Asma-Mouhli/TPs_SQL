# TP2 — Rapport d’optimisation : partie B

 — questions 5 à 11 ; bonus 12 avec le binôme.**

Mesures relevées le 14 octobre 2026 sur MySQL **8.0.46**, avec le compte root@localhost. La table emprunt contient **200 130 lignes** après chargement de l’archive du professeur. Les sorties complètes sont conservées dans [Preuves/resultats-partie-b.txt](Preuves/resultats-partie-b.txt).

Les questions 5 à 10 ont été exécutées. Les bonus 11 et 12 restent à vérifier. Aucun résultat de bonus n’est présenté comme observé.

## Conditions de mesure

La table utilise InnoDB et possède une clé primaire sur id. Avant les créations, les deux index secondaires sont fk_emprunt_adherent (adherent_id) et fk_emprunt_exemplaire (exemplaire_id). Les trois plans avant sont relevés avant toute création d’index de la partie B. ANALYZE TABLE réussit avant les mesures et après chaque création.

La colonne rows donne une estimation des lignes examinées, tandis que COUNT(*) fournit le nombre exact de résultats. Les écarts ci-dessous décrivent les plans et ne prouvent pas un facteur d’accélération chronométré. Les temps affichés par EXPLAIN ne sont pas les temps d’exécution des SELECT étudiés.

## 5 et 6 — Mesures avant et après

### R1 — Les emprunts d’une journée

    SELECT * FROM emprunt WHERE date_emprunt = '2024-03-12';

| Mesure | type | key | rows | Extra |
|---|---|---|---|---|
| Avant | ALL | NULL | 197449 | Using where |
| Après | ref | idx_tp2_date_emprunt | 104 | NULL |

- Index créé : idx_tp2_date_emprunt (date_emprunt).
- Lignes réellement renvoyées : **104**.
- Justification : la condition d’égalité permet une recherche directe de la date.
- Conclusion : le plan passe d’un parcours de table estimé à 197 449 lignes à un accès indexé estimé à 104 lignes. L’index n’est pas couvrant, car SELECT * demande les autres colonnes de la table.

### R2 — Les emprunts en cours

    SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;

| Mesure | type | key | rows | Extra |
|---|---|---|---|---|
| Avant | ALL | NULL | 197449 | Using where |
| Après | ref | idx_tp2_retour_reelle | 30 | Using index condition |

- Index créé : idx_tp2_retour_reelle (date_retour_reelle).
- Lignes réellement renvoyées : **30**.
- Justification : InnoDB indexe aussi les valeurs NULL. Les emprunts ouverts représentent une très petite partie de la table.
- Conclusion : le serveur utilise l’index et estime 30 lignes à examiner au lieu d’un parcours complet. Using index condition décrit un filtrage dans l’index ; cela ne signifie pas que SELECT * est couvert.

### R3 — L’historique récent d’un adhérent

    SELECT id, date_emprunt FROM emprunt
    WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';

| Mesure | type | key | rows | Extra |
|---|---|---|---|---|
| Avant | ref | fk_emprunt_adherent | 5070 | Using where |
| Après | range | idx_tp2_adherent_date | 741 | Using where; Using index |

- Index créé : idx_tp2_adherent_date (adherent_id, date_emprunt).
- Lignes réellement renvoyées : **741**.
- Ordre des colonnes : l’égalité sur adherent_id vient avant la plage sur date_emprunt. Le serveur peut délimiter les dates utiles dans les entrées du seul adhérent 12. Dans l’ordre inverse, la plage commence par les dates de plusieurs adhérents.
- Conclusion : avant création, l’index de la clé étrangère sélectionne les emprunts de l’adhérent puis le serveur filtre les dates. Le composite limite directement le parcours à la plage utile : 741 lignes estimées contre 5 070.
- Le composite couvre aussi la projection : date_emprunt figure explicitement dans l’index et id, clé primaire, est inclus dans les index secondaires InnoDB.

## 7 — Le préfixe gauche

    EXPLAIN SELECT id FROM emprunt WHERE adherent_id = 12;
    EXPLAIN SELECT id FROM emprunt WHERE date_emprunt >= '2025-01-01';

| Filtre | type | key choisie | rows | Extra |
|---|---|---|---|---|
| adherent_id = 12 | ref | idx_tp2_adherent_date | 5070 | Using index |
| date_emprunt >= '2025-01-01' | range | idx_tp2_date_emprunt | 55224 | Using where; Using index |

La première requête utilise le préfixe gauche du composite, adherent_id. La seconde utilise l’index simple sur date_emprunt, et non le composite. Cela correspond à la règle de recherche classique par préfixe gauche : sans condition sur la première colonne, on ne délimite pas directement une plage unique dans le composite.

Cette règle ne signifie pas qu’un composite ne peut jamais être parcouru autrement. Le plan observé en question 9 montre justement une optimisation par skip scan.

## 8 — L’index couvrant

    EXPLAIN SELECT adherent_id, date_emprunt FROM emprunt WHERE adherent_id = 12;
    EXPLAIN SELECT adherent_id, date_emprunt, exemplaire_id
    FROM emprunt WHERE adherent_id = 12;

| Projection | type | key | rows | Extra |
|---|---|---|---|---|
| adherent_id, date_emprunt | ref | idx_tp2_adherent_date | 5070 | Using index |
| Avec exemplaire_id | ref | idx_tp2_adherent_date | 5070 | NULL |

La mention **Using index** disparaît dans le second plan. La première requête peut être satisfaite avec les colonnes du composite. La seconde demande exemplaire_id, absent de cet index : le serveur doit consulter les enregistrements via la clé primaire pour récupérer cette colonne. Le nombre estimé de lignes ne change pas, mais la lecture supplémentaire explique la perte de couverture.

## 9 — La requête réécrite

    -- Version d’origine
    SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024;

    -- Version réécrite
    SELECT COUNT(*) FROM emprunt
    WHERE date_emprunt >= '2024-01-01'
      AND date_emprunt < '2025-01-01';

La deuxième version donne directement les bornes de recherche. La borne haute exclusive conserve aussi toutes les heures de 2024 si la colonne était de type DATETIME ; ici la colonne est de type DATE.

Les deux EXPLAIN exécutés portent sur ces requêtes :

| Version | type | key | rows | Extra |
|---|---|---|---|---|
| YEAR(date_emprunt) = 2024 | index | idx_tp2_date_emprunt | 199875 | Using where; Using index |
| Intervalle sur date_emprunt | range | idx_tp2_adherent_date | 22203 | Using where; Using index for skip scan |

| Version | Nombre exact renvoyé par COUNT(*) |
|---|---|
| YEAR | 43015 |
| Intervalle | 43015 |

Les résultats sont identiques : **43 015 emprunts**.

La version YEAR parcourt un index entier et filtre les dates ; Using index indique la couverture, pas un accès ciblé. La version réécrite utilise un accès range. Sur cette exécution, MySQL choisit le **composite avec un skip scan**, plutôt que l’index simple sur la date. Il peut effectuer des recherches sur la colonne date pour les différentes valeurs de la première colonne. Ce choix réel est conservé au rapport.

Les 22 203 lignes sont une estimation du plan, et non le total de résultats : le comptage exact reste 43 015.

## 10 — Le prix des index

    SELECT ROUND(data_length / 1024 / 1024, 3) AS donnees_mo,
           ROUND(index_length / 1024 / 1024, 3) AS index_mo
    FROM information_schema.tables
    WHERE table_schema = 'mediatheque' AND table_name = 'emprunt';

| Mesure | donnees_mo | index_mo |
|---|---|---|
| Avant | 8.516 | 11.031 |
| Après | 8.516 | 18.063 |
| Différence à partir des valeurs arrondies | 0.000 | +7.032 |

Les unités correspondent à 1 024 × 1 024 octets. Pour InnoDB, data_length comprend l’index primaire organisé avec les données ; index_length représente les index secondaires. Ces valeurs reflètent l’espace alloué et restent approximatives.

L’inventaire final contient PRIMARY, fk_emprunt_exemplaire et les trois index créés. **fk_emprunt_adherent n’apparaît plus** : le composite commence par adherent_id et remplace l’index simple comme support compatible de la clé étrangère. La variation de taille est donc un bilan net, pas la somme isolée des trois nouveaux index.

Conclusion : les index réduisent les parcours des recherches étudiées, au prix d’environ **7,032 unités Mo supplémentaires** pour les index secondaires et d’un entretien supplémentaire lors des écritures.

## 11 — Bonus : l’index qui résiste

**À exécuter : résultat non encore fourni.**

    SHOW CREATE TABLE emprunt;
    SHOW INDEX FROM emprunt;
    DROP INDEX idx_tp2_adherent_date ON emprunt;

L’inventaire final ne montre plus d’autre index commençant par adherent_id. Le composite paraît donc être le seul support de cette clé étrangère. L’erreur attendue est **1553** : le serveur refuse de supprimer un index nécessaire à une contrainte de clé étrangère.

InnoDB exige un index dont les premières colonnes correspondent aux colonnes de la clé étrangère, dans leur ordre. Si un autre index compatible existe au moment du test, la suppression peut réussir. Il faut conserver le résultat réel. Le script 04-bonus.sql restaure le composite si la suppression réussit.

Résultat et message exact : **à relever lors du test**.

## 12 — Bonus : la vue lente, avec le binôme

**À exécuter après disponibilité des vues de la partie A.**

    SHOW CREATE VIEW v_emprunt_en_cours;
    SHOW CREATE VIEW v_retard;
    EXPLAIN SELECT * FROM v_retard;

| table | type | possible_keys | key | rows | Extra |
|---|---|---|---|---|---|
| À relever pour chaque ligne | À relever | À relever | À relever | À relever | À relever |

Le fichier 01-vues.sql du binôme n’était pas fourni. Identifier les tables et alias avec les définitions des vues. L’index sur date_retour_reelle est un candidat pour sélectionner les emprunts ouverts ; confirmer son utilisation dans key. Une vue ne reçoit pas directement d’index : les tables sous-jacentes sont indexées.

## Validation

- [x] Archive chargée : 200 130 emprunts.
- [x] Plans avant/après et comptages relevés pour R1, R2 et R3.
- [x] Préfixe gauche et couverture vérifiés.
- [x] Réécriture et égalité des totaux vérifiées.
- [x] Tailles avant/après relevées.
- [ ] Bonus 11 exécuté et message exact conservé.
- [ ] Bonus 12 vérifié avec le binôme.
- [ ] Réexécution complète testée.

Les sorties fournies ne contiennent pas d’erreur SQL. Les EXPLAIN affichent chacun un avertissement dont le détail n’a pas été capturé ; il n’est pas assimilé ici à une erreur.

## Références techniques

- [Index composés — MySQL 8.0](https://dev.mysql.com/doc/refman/8.0/en/multiple-column-indexes.html)
- [Clés étrangères — MySQL 8.0](https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html)
