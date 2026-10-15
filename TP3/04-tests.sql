USE mediatheque;

SET @code = (SELECT code_barre FROM exemplaire
             WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
SET @adherent = (SELECT id FROM adherent
                 WHERE actif = 1 AND f_nb_emprunts_en_cours(id) = 0
                   AND f_penalites_dues(id) = 0 ORDER BY id LIMIT 1);

CALL p_emprunter(@code, @adherent, @id);
SET @id_t1 = @id;
SELECT @id_t1 AS emprunt_cree;
SELECT code_barre, disponible FROM exemplaire WHERE code_barre = @code;
SELECT operation, cle, auteur, details FROM journal_action
WHERE table_cible = 'emprunt' AND cle = CAST(@id_t1 AS CHAR) ORDER BY id;

SET @autre_adherent = (SELECT id FROM adherent
                       WHERE actif = 1 AND id <> @adherent ORDER BY id LIMIT 1);

SET @code_libre = (SELECT code_barre FROM exemplaire
                   WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
SET @inactif = (SELECT id FROM adherent WHERE actif = 0 ORDER BY id LIMIT 1);

SET @code_libre = (SELECT code_barre FROM exemplaire
                   WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code_libre, @adherent, @id);
SET @code_libre = (SELECT code_barre FROM exemplaire
                   WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code_libre, @adherent, @id);
SET @code_libre = (SELECT code_barre FROM exemplaire
                   WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code_libre, @adherent, @id);
SET @code_libre = (SELECT code_barre FROM exemplaire
                   WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code_libre, @adherent, @id);
SELECT f_nb_emprunts_en_cours(@adherent) AS emprunts_en_cours;

SET @code_libre = (SELECT code_barre FROM exemplaire
                   WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);

SET @mauvais_payeur = (SELECT id FROM adherent
                       WHERE actif = 1 AND f_nb_emprunts_en_cours(id) < 5
                         AND f_penalites_dues(id) > 10 ORDER BY id LIMIT 1);
SELECT @mauvais_payeur AS adherent_id, f_penalites_dues(@mauvais_payeur) AS penalites_dues;

SET @exemplaire_libre = (SELECT id FROM exemplaire
                         WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue)
VALUES (@exemplaire_libre, 2, NULL, NULL);
SET @id_direct = LAST_INSERT_ID();

SELECT id, date_emprunt, date_retour_prevue,
       DATEDIFF(date_retour_prevue, date_emprunt) AS duree_jours
FROM emprunt WHERE id = @id_direct;
SELECT code_barre, disponible FROM exemplaire WHERE id = @exemplaire_libre;
SELECT operation, cle, auteur, details FROM journal_action
WHERE table_cible = 'emprunt' AND cle = CAST(@id_direct AS CHAR) ORDER BY id;

SET @id_retard = (SELECT id FROM emprunt
                  WHERE date_retour_reelle IS NULL AND date_retour_prevue < CURDATE()
                  ORDER BY date_retour_prevue, id LIMIT 1);
SET @code_retard = (SELECT ex.code_barre FROM exemplaire ex
                    JOIN emprunt em ON em.exemplaire_id = ex.id WHERE em.id = @id_retard);
SET @jours_retard = f_jours_de_retard(@id_retard);
SELECT @jours_retard AS jours_attendus, @jours_retard * 0.20 AS montant_attendu;

CALL p_rendre(@code_retard);
SELECT id, date_retour_reelle FROM emprunt WHERE id = @id_retard;
SELECT code_barre, disponible FROM exemplaire WHERE code_barre = @code_retard;
SELECT adherent_id, montant, motif FROM penalite WHERE emprunt_id = @id_retard;
SELECT operation, cle, auteur, details FROM journal_action
WHERE table_cible = 'emprunt' AND cle = CAST(@id_retard AS CHAR) ORDER BY id;

/* Appels devant echouer (messages attendus, a confirmer sur MySQL).
T2 : CALL p_emprunter(@code, @autre_adherent, @id);
ERROR 1644 (45000): Cet exemplaire est deja emprunte ou indisponible.

T3 : CALL p_emprunter(@code_libre, @inactif, @id);
ERROR 1644 (45000): Votre inscription est inactive.

T4 : CALL p_emprunter('MED-99999', 1, @id);
ERROR 1644 (45000): Code-barres inconnu.

T5 : CALL p_emprunter(@code_libre, @adherent, @id);
ERROR 1644 (45000): Vous avez atteint le maximum de 5 emprunts en cours.

T6 : CALL p_emprunter(@code_libre, @mauvais_payeur, @id);
ERROR 1644 (45000): Vos penalites impayees depassent 10 euros.

T9 : CALL p_rendre(@code_retard);
ERROR 1644 (45000): Aucun emprunt en cours pour ce code-barres.
*/
