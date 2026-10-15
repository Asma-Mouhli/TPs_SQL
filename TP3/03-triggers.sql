USE mediatheque;

CREATE TABLE IF NOT EXISTS journal_action (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_cible VARCHAR(40)     NOT NULL,
  operation   VARCHAR(10)     NOT NULL,
  cle         VARCHAR(40)     NOT NULL,
  auteur      VARCHAR(100)    NOT NULL,
  horodatage  DATETIME        NOT NULL,
  details     VARCHAR(255)        NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS tr_emprunt_before_insert;
DROP TRIGGER IF EXISTS tr_emprunt_after_insert;
DROP TRIGGER IF EXISTS tr_emprunt_after_update;

DELIMITER $$

CREATE TRIGGER tr_emprunt_before_insert
BEFORE INSERT ON emprunt
FOR EACH ROW
BEGIN
  IF NEW.date_emprunt IS NULL THEN
    SET NEW.date_emprunt = CURDATE();
  END IF;

  IF NEW.date_retour_prevue IS NULL THEN
    SET NEW.date_retour_prevue = DATE_ADD(NEW.date_emprunt, INTERVAL 14 DAY);
  END IF;

  IF NEW.date_retour_prevue < NEW.date_emprunt THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La date de retour prevue ne peut pas preceder la date d''emprunt.';
  END IF;
END$$

CREATE TRIGGER tr_emprunt_after_insert
AFTER INSERT ON emprunt
FOR EACH ROW
BEGIN
  UPDATE exemplaire SET disponible = 0 WHERE id = NEW.exemplaire_id;

  INSERT INTO journal_action (table_cible, operation, cle, auteur, horodatage, details)
  VALUES ('emprunt', 'INSERT', NEW.id, USER(), NOW(),
          CONCAT('Emprunt de l''exemplaire ', NEW.exemplaire_id));
END$$

CREATE TRIGGER tr_emprunt_after_update
AFTER UPDATE ON emprunt
FOR EACH ROW
BEGIN
  IF OLD.date_retour_reelle IS NULL AND NEW.date_retour_reelle IS NOT NULL THEN
    UPDATE exemplaire SET disponible = 1 WHERE id = NEW.exemplaire_id;
  END IF;

  INSERT INTO journal_action (table_cible, operation, cle, auteur, horodatage, details)
  VALUES ('emprunt', 'UPDATE', NEW.id, USER(), NOW(),
          CONCAT('Modification de l''emprunt de l''exemplaire ', NEW.exemplaire_id,
                 ', retour : ', COALESCE(CAST(NEW.date_retour_reelle AS CHAR), 'non rendu')));
END$$

DELIMITER ;
