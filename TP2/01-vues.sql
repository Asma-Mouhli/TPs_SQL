-- TP2 - Partie A : vues du quotidien et droits du stagiaire
-- A executer avec un compte administrateur apres les scripts du TP1.

USE mediatheque;

-- Un LEFT JOIN conserve les ouvrages qui ne possedent aucun exemplaire.
-- COUNT(e.id) vaut alors 0 et COALESCE ramene le SUM NULL a 0.
CREATE OR REPLACE VIEW v_catalogue AS
SELECT
    o.titre,
    o.auteur,
    o.annee_publication,
    c.libelle AS categorie,
    COUNT(e.id) AS nb_exemplaires,
    COALESCE(SUM(e.disponible = 1), 0) AS nb_disponibles
FROM ouvrage AS o
JOIN categorie AS c
    ON c.id = o.categorie_id
LEFT JOIN exemplaire AS e
    ON e.ouvrage_id = o.id
GROUP BY
    o.id,
    o.titre,
    o.auteur,
    o.annee_publication,
    c.libelle;

-- Les donnees personnelles email, telephone et date_naissance sont masquees.
CREATE OR REPLACE VIEW v_adherent_public AS
SELECT
    id,
    nom,
    prenom,
    ville,
    date_inscription,
    actif
FROM adherent;

CREATE OR REPLACE VIEW v_emprunt_en_cours AS
SELECT
    em.id,
    em.date_emprunt,
    em.date_retour_prevue,
    em.date_retour_reelle,
    DATEDIFF(CURDATE(), em.date_retour_prevue) AS jours_retard,
    CONCAT(a.prenom, ' ', a.nom) AS adherent,
    o.titre AS ouvrage,
    ex.code_barre
FROM emprunt AS em
JOIN adherent AS a
    ON a.id = em.adherent_id
JOIN exemplaire AS ex
    ON ex.id = em.exemplaire_id
JOIN ouvrage AS o
    ON o.id = ex.ouvrage_id
WHERE em.date_retour_reelle IS NULL;

-- Cette vue reutilise v_emprunt_en_cours sans recopier ses jointures.
CREATE OR REPLACE VIEW v_retard AS
SELECT
    id,
    date_emprunt,
    date_retour_prevue,
    date_retour_reelle,
    jours_retard,
    adherent,
    ouvrage,
    code_barre
FROM v_emprunt_en_cours
WHERE date_retour_prevue < CURDATE();

-- Au TP1, ce role donnait notamment un acces direct a exemplaire.
REVOKE 'role_catalogue' FROM 'stagiaire'@'localhost';
REVOKE SELECT (id, nom, prenom, ville, date_inscription, actif)
    ON mediatheque.adherent FROM 'stagiaire'@'localhost';

GRANT SELECT ON mediatheque.v_adherent_public TO 'stagiaire'@'localhost';
GRANT SELECT ON mediatheque.v_catalogue TO 'stagiaire'@'localhost';
GRANT SELECT ON mediatheque.v_emprunt_en_cours TO 'stagiaire'@'localhost';

-- Les vues sont SQL SECURITY DEFINER par defaut : le serveur controle les
-- tables avec les droits du createur de la vue et ceux du stagiaire sur la vue.

-- Verification des droits a effectuer dans une connexion stagiaire :
-- SELECT * FROM mediatheque.v_adherent_public; -- doit fonctionner
-- SELECT * FROM mediatheque.adherent;          -- doit etre refuse

SHOW GRANTS FOR 'stagiaire'@'localhost';

