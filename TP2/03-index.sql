-- TP2 - Partie B - Questions 5 a 10

-- MySQL 8.0 / InnoDB, compte administrateur.
-- Prerequis : Base/01-schema.sql, Base/02-donnees.sql et Base/03-volume.sql.
-- Ce script ne charge PAS l'archive : la charger une seule fois auparavant.
-- Les resultats des SELECT et EXPLAIN sont a reporter dans rapport-index.md.

USE mediatheque;
SELECT VERSION() AS version_mysql, CURRENT_USER() AS compte;
SHOW CREATE TABLE emprunt;
SELECT COUNT(*) AS nombre_total_emprunts FROM emprunt;

-- Reexecution : retirer uniquement les trois index de ce TP s'ils existent.
-- Si le composite est devenu le seul index supportant la FK adherent_id,
-- retablir d'abord un index simple. Ne jamais desactiver les cles etrangeres.
SET @tp2_composite_present = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'emprunt'
      AND index_name = 'idx_tp2_adherent_date' AND seq_in_index = 1
);
SET @tp2_autre_support = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'emprunt'
      AND seq_in_index = 1 AND column_name = 'adherent_id'
      AND sub_part IS NULL AND index_name <> 'idx_tp2_adherent_date'
);
SET @tp2_sql = IF(@tp2_composite_present > 0 AND @tp2_autre_support = 0,
    'CREATE INDEX idx_tp2_support_adherent ON emprunt(adherent_id)',
    'SELECT ''Index de support conserve'' AS preparation');
PREPARE tp2_stmt FROM @tp2_sql;
EXECUTE tp2_stmt;
DEALLOCATE PREPARE tp2_stmt;

SET @tp2_sql = IF(@tp2_composite_present > 0,
    'DROP INDEX idx_tp2_adherent_date ON emprunt',
    'SELECT ''Pas de composite TP2 a retirer'' AS preparation');
PREPARE tp2_stmt FROM @tp2_sql;
EXECUTE tp2_stmt;
DEALLOCATE PREPARE tp2_stmt;

SET @tp2_sql = IF(EXISTS(
    SELECT 1 FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'emprunt'
      AND index_name = 'idx_tp2_date_emprunt'),
    'DROP INDEX idx_tp2_date_emprunt ON emprunt',
    'SELECT ''Pas d index TP2 sur date_emprunt a retirer'' AS preparation');
PREPARE tp2_stmt FROM @tp2_sql;
EXECUTE tp2_stmt;
DEALLOCATE PREPARE tp2_stmt;

SET @tp2_sql = IF(EXISTS(
    SELECT 1 FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'emprunt'
      AND index_name = 'idx_tp2_retour_reelle'),
    'DROP INDEX idx_tp2_retour_reelle ON emprunt',
    'SELECT ''Pas d index TP2 sur date_retour_reelle a retirer'' AS preparation');
PREPARE tp2_stmt FROM @tp2_sql;
EXECUTE tp2_stmt;
DEALLOCATE PREPARE tp2_stmt;

-- Inventaire initial : les FK peuvent deja disposer d'index.
-- Si des index personnels equivalents existent, les signaler dans le rapport.
ANALYZE TABLE emprunt;
SELECT index_name, non_unique, seq_in_index, column_name, sub_part
FROM information_schema.statistics
WHERE table_schema = DATABASE() AND table_name = 'emprunt'
ORDER BY index_name, seq_in_index;

-- Q5 / Q10 : tous les plans AVANT sont mesures avant les trois creations.
SELECT 'Q10 - AVANT' AS etape;
SELECT ROUND(data_length / 1024 / 1024, 3) AS donnees_mo,
       ROUND(index_length / 1024 / 1024, 3) AS index_mo
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'emprunt';

SELECT 'R1 - AVANT' AS etape;
EXPLAIN SELECT * FROM emprunt WHERE date_emprunt = '2024-03-12';
SELECT COUNT(*) AS lignes_reelles_r1
FROM emprunt WHERE date_emprunt = '2024-03-12';

SELECT 'R2 - AVANT' AS etape;
EXPLAIN SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;
SELECT COUNT(*) AS lignes_reelles_r2
FROM emprunt WHERE date_retour_reelle IS NULL;

SELECT 'R3 - AVANT' AS etape;
EXPLAIN SELECT id, date_emprunt FROM emprunt
WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';
SELECT COUNT(*) AS lignes_reelles_r3 FROM emprunt
WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';

-- Q6 / R1 : acceder aux emprunts de la date demandee par egalite.
CREATE INDEX idx_tp2_date_emprunt ON emprunt(date_emprunt);
ANALYZE TABLE emprunt;
SELECT 'R1 - APRES' AS etape;
EXPLAIN SELECT * FROM emprunt WHERE date_emprunt = '2024-03-12';

-- Q6 / R2 : les valeurs NULL sont indexees par InnoDB.
-- L'index est interessant si les emprunts ouverts sont peu nombreux.
-- Un scan reste possible si l'optimiseur estime l'index trop couteux.
CREATE INDEX idx_tp2_retour_reelle ON emprunt(date_retour_reelle);
ANALYZE TABLE emprunt;
SELECT 'R2 - APRES' AS etape;
EXPLAIN SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;

-- Q6 / R3 : egalite sur adherent_id, puis plage sur date_emprunt.
-- Cet ordre delimite les dates utiles au sein d'un seul adherent.
-- Inverser les colonnes commence par les dates de tous les adherents.
CREATE INDEX idx_tp2_adherent_date ON emprunt(adherent_id, date_emprunt);
ANALYZE TABLE emprunt;
SELECT 'R3 - APRES' AS etape;
EXPLAIN SELECT id, date_emprunt FROM emprunt
WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';

-- Q7 : adherent_id est le prefixe gauche du composite.
-- date_emprunt seule peut utiliser l'index simple cree pour R1.
-- Ne pas confondre cet index simple avec le composite.
SELECT 'Q7 - PREFIXE GAUCHE' AS etape;
EXPLAIN SELECT id FROM emprunt WHERE adherent_id = 12;
EXPLAIN SELECT id FROM emprunt WHERE date_emprunt >= '2025-01-01';

-- Q8 : avec le composite, la premiere requete est couvrante.
-- exemplaire_id n'est pas dans cet index : la seconde doit lire les lignes.
-- Relever les vrais plans : un index simple concurrent peut etre choisi.
SELECT 'Q8 - COUVERTURE' AS etape;
EXPLAIN SELECT adherent_id, date_emprunt FROM emprunt WHERE adherent_id = 12;
EXPLAIN SELECT adherent_id, date_emprunt, exemplaire_id
FROM emprunt WHERE adherent_id = 12;

-- Q9 : une fonction sur la colonne gene la recherche par plage.
-- YEAR peut parcourir un index couvrant entier : ce n'est pas un acces range.
SELECT 'Q9 - YEAR ET INTERVALLE' AS etape;
EXPLAIN SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024;
EXPLAIN SELECT COUNT(*) FROM emprunt
WHERE date_emprunt >= '2024-01-01' AND date_emprunt < '2025-01-01';
-- Borne haute exclusive : fonctionne pour DATE et pour DATETIME.
SELECT
    (SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024) AS total_year,
    (SELECT COUNT(*) FROM emprunt WHERE date_emprunt >= '2024-01-01'
        AND date_emprunt < '2025-01-01') AS total_intervalle;

-- Q10 : index_length inclut tous les index secondaires presents.
-- InnoDB compte l'index primaire clustered dans data_length.
ANALYZE TABLE emprunt;
SELECT 'Q10 - APRES' AS etape;
SELECT ROUND(data_length / 1024 / 1024, 3) AS donnees_mo,
       ROUND(index_length / 1024 / 1024, 3) AS index_mo
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'emprunt';
SHOW INDEX FROM emprunt;
-- Bonus : executer separement 04-bonus.sql, instruction par instruction.
