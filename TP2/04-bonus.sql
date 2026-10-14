-- TP2 - Bonus 11 et bonus 12 (avec le binome).
-- Executer les instructions une par une : une erreur est attendue en Q11.
USE mediatheque;

-- Q11 : identifier la FK et les index qui peuvent la supporter.
SHOW CREATE TABLE emprunt;
SHOW INDEX FROM emprunt;
-- Si le composite est le seul support de la FK adherent_id : erreur 1553.
-- Si un autre index commence par adherent_id : la suppression peut reussir.
-- Relever ce qui se produit vraiment, sans supprimer la FK pour provoquer l'erreur.
DROP INDEX idx_tp2_adherent_date ON emprunt;

-- Continuer ici apres l'essai, y compris si MySQL a renvoye une erreur.
-- Restaurer l'index uniquement si la suppression a reussi.
SET @tp2_sql = IF(EXISTS(
    SELECT 1 FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'emprunt'
      AND index_name = 'idx_tp2_adherent_date'),
    'SELECT ''Composite toujours present'' AS verification',
    'CREATE INDEX idx_tp2_adherent_date ON emprunt(adherent_id, date_emprunt)');
PREPARE tp2_stmt FROM @tp2_sql;
EXECUTE tp2_stmt;
DEALLOCATE PREPARE tp2_stmt;
ANALYZE TABLE emprunt;

-- Q12 : a faire lorsque les vues de la partie A sont disponibles.
-- Le plan exact depend des definitions du fichier 01-vues.sql du binome.
SHOW CREATE VIEW v_emprunt_en_cours;
SHOW CREATE VIEW v_retard;
EXPLAIN SELECT * FROM v_retard;
-- Relever pour CHAQUE ligne table, type, possible_keys, key, rows et Extra.
-- Verifier notamment si la ligne emprunt utilise idx_tp2_retour_reelle.
-- Aucun index n'est cree directement sur une vue.
