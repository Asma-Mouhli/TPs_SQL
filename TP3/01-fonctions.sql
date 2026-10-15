USE mediatheque;
DROP FUNCTION IF EXISTS f_nb_emprunts_en_cours;
DROP FUNCTION IF EXISTS f_penalites_dues;
DROP FUNCTION IF EXISTS f_jours_de_retard;
DELIMITER $$
CREATE FUNCTION f_nb_emprunts_en_cours(p_adherent_id INT)
RETURNS INT READS SQL DATA
BEGIN
  DECLARE v_nombre INT;
  SELECT COUNT(*) INTO v_nombre FROM emprunt
  WHERE adherent_id = p_adherent_id AND date_retour_reelle IS NULL;
  RETURN v_nombre;
END$$
CREATE FUNCTION f_penalites_dues(p_adherent_id INT)
RETURNS DECIMAL(10,2) READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(10,2);
  SELECT COALESCE(SUM(montant), 0.00) INTO v_total
  FROM penalite WHERE adherent_id = p_adherent_id AND payee = 0;
  RETURN v_total;
END$$
CREATE FUNCTION f_jours_de_retard(p_emprunt_id INT)
RETURNS INT READS SQL DATA
BEGIN
  DECLARE v_jours INT DEFAULT 0;
  SELECT GREATEST(0, DATEDIFF(COALESCE(date_retour_reelle, CURDATE()), date_retour_prevue))
  INTO v_jours FROM emprunt WHERE id = p_emprunt_id;
  RETURN COALESCE(v_jours, 0);
END$$
DELIMITER ;
-- Une ligne par adherent : les trois fonctions sont utilisees.
SELECT a.id, f_nb_emprunts_en_cours(a.id) AS emprunts_en_cours,
       f_penalites_dues(a.id) AS penalites_dues,
       MAX(f_jours_de_retard(e.id)) AS retard_maximal_jours
FROM adherent a JOIN emprunt e ON e.adherent_id = a.id
WHERE e.date_retour_reelle IS NULL
GROUP BY a.id HAVING f_nb_emprunts_en_cours(a.id) > 0;
