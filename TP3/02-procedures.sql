USE mediatheque;
DROP PROCEDURE IF EXISTS p_emprunter;
DROP PROCEDURE IF EXISTS p_rendre;
DROP PROCEDURE IF EXISTS p_bilan_adherent;
DELIMITER $$
CREATE PROCEDURE p_emprunter(IN p_code_barre VARCHAR(100), IN p_adherent_id INT, OUT p_emprunt_id INT)
SQL SECURITY DEFINER
BEGIN
  DECLARE v_actif INT DEFAULT NULL;
  DECLARE v_exemplaire_id INT DEFAULT NULL;
  DECLARE v_disponible INT;
  DECLARE v_etat VARCHAR(40);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_emprunt_id = NULL;
    RESIGNAL;
  END;
  SET p_emprunt_id = NULL;
  START TRANSACTION;
  -- Le verrou sur l'adherent serialise les emprunts pour ce meme adherent.
  BEGIN
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_actif = NULL;
    SELECT actif INTO v_actif FROM adherent WHERE id = p_adherent_id FOR UPDATE;
  END;
  IF v_actif IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Adherent inconnu.';
  END IF;
  IF v_actif <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Votre inscription est inactive.';
  END IF;
  BEGIN
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_exemplaire_id = NULL;
    SELECT id, disponible, etat INTO v_exemplaire_id, v_disponible, v_etat
    FROM exemplaire WHERE code_barre = p_code_barre FOR UPDATE;
  END;
  IF v_exemplaire_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Code-barres inconnu.';
  END IF;
  IF v_etat = 'hors_service' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cet exemplaire est hors service.';
  END IF;
  IF COALESCE(v_disponible, 0) <> 1 OR EXISTS (
    SELECT 1 FROM emprunt WHERE exemplaire_id = v_exemplaire_id AND date_retour_reelle IS NULL
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cet exemplaire est deja emprunte ou indisponible.';
  END IF;
  IF f_nb_emprunts_en_cours(p_adherent_id) >= 5 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vous avez atteint le maximum de 5 emprunts en cours.';
  END IF;
  IF f_penalites_dues(p_adherent_id) > 10.00 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vos penalites impayees depassent 10 euros.';
  END IF;
  INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue)
  VALUES (v_exemplaire_id, p_adherent_id, NULL, NULL);
  SET p_emprunt_id = LAST_INSERT_ID();
  COMMIT;
END$$
CREATE PROCEDURE p_rendre(IN p_code_barre VARCHAR(100))
SQL SECURITY DEFINER
BEGIN
  DECLARE v_exemplaire_id INT DEFAULT NULL;
  DECLARE v_emprunt_id INT DEFAULT NULL;
  DECLARE v_adherent_id INT;
  DECLARE v_jours INT DEFAULT 0;
  DECLARE v_montant DECIMAL(10,2) DEFAULT 0.00;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  BEGIN
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_exemplaire_id = NULL;
    SELECT id INTO v_exemplaire_id FROM exemplaire WHERE code_barre = p_code_barre FOR UPDATE;
  END;
  BEGIN
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_emprunt_id = NULL;
    SELECT id, adherent_id INTO v_emprunt_id, v_adherent_id FROM emprunt
    WHERE exemplaire_id = v_exemplaire_id AND date_retour_reelle IS NULL
    ORDER BY id LIMIT 1 FOR UPDATE;
  END;
  IF v_emprunt_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aucun emprunt en cours pour ce code-barres.';
  END IF;
  UPDATE emprunt SET date_retour_reelle = CURDATE() WHERE id = v_emprunt_id;
  SET v_jours = f_jours_de_retard(v_emprunt_id);
  SET v_montant = v_jours * 0.20;
  IF v_jours > 0 THEN
    INSERT INTO penalite (adherent_id, emprunt_id, montant, motif, payee)
    VALUES (v_adherent_id, v_emprunt_id, v_montant, CONCAT('Retard de ', v_jours, ' jour(s)'), 0);
  END IF;
  COMMIT;
  SELECT v_emprunt_id AS emprunt_id, v_jours AS jours_de_retard, v_montant AS montant_facture;
END$$
CREATE PROCEDURE p_bilan_adherent(IN p_adherent_id INT)
READS SQL DATA
BEGIN
  SELECT a.*, f_nb_emprunts_en_cours(a.id) AS emprunts_en_cours,
         f_penalites_dues(a.id) AS penalites_dues FROM adherent a WHERE a.id = p_adherent_id;
  SELECT e.*, ex.code_barre, f_jours_de_retard(e.id) AS jours_de_retard
  FROM emprunt e JOIN exemplaire ex ON ex.id = e.exemplaire_id
  WHERE e.adherent_id = p_adherent_id AND e.date_retour_reelle IS NULL ORDER BY e.date_retour_prevue;
  SELECT COUNT(*) AS total_emprunts_depuis_inscription FROM emprunt WHERE adherent_id = p_adherent_id;
END$$
DELIMITER ;
