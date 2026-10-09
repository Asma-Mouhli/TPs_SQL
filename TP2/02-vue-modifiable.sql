-- TP2 - Partie A : vue modifiable et tests
-- A executer avec un compte administrateur apres 01-vues.sql.

USE mediatheque;

CREATE OR REPLACE VIEW v_adherent_lyon AS
SELECT
    id,
    nom,
    prenom,
    email,
    telephone,
    date_naissance,
    ville,
    date_inscription,
    actif
FROM adherent
WHERE ville = 'Lyon'
WITH CHECK OPTION;

-- Nettoyage de la ligne de test afin que le script soit rejouable.
DELETE FROM adherent
WHERE email IN (
    'test.lyon.tp2@example.fr',
    'test.bron.tp2@example.fr'
);

-- Essai 1 : insertion autorisee par la vue, puis verification dans la table.
INSERT INTO v_adherent_lyon
    (nom, prenom, email, telephone, date_naissance,
     ville, date_inscription, actif)
VALUES
    ('TestLyon', 'Alice', 'test.lyon.tp2@example.fr', NULL, NULL,
     'Lyon', CURDATE(), 1);

SELECT id, nom, prenom, email, ville, date_inscription, actif
FROM adherent
WHERE email = 'test.lyon.tp2@example.fr';

-- Les deux essais suivants produisent volontairement une erreur.
-- Il est plus simple de les executer un par un dans MySQL Workbench.

-- Essai 2 : doit echouer avec l'erreur 1369.
-- WITH CHECK OPTION refuse cette ligne car Bron est different de Lyon.
INSERT INTO v_adherent_lyon
    (nom, prenom, email, telephone, date_naissance,
     ville, date_inscription, actif)
VALUES
    ('TestBron', 'Bob', 'test.bron.tp2@example.fr', NULL, NULL,
     'Bron', CURDATE(), 1);

-- Essai 3 : doit echouer avec l'erreur 1288.
-- v_catalogue ne peut pas etre modifiee car elle utilise COUNT, SUM et GROUP BY.
UPDATE v_catalogue
SET titre = titre;

-- On affiche ensuite YES ou NO pour chacune des cinq vues.
-- v_catalogue doit afficher NO a cause de COUNT, SUM et GROUP BY.
-- Les autres vues doivent afficher YES.
SELECT
    table_name,
    is_updatable
FROM information_schema.views
WHERE table_schema = 'mediatheque'
  AND table_name IN (
      'v_catalogue',
      'v_adherent_public',
      'v_emprunt_en_cours',
      'v_retard',
      'v_adherent_lyon'
  )
ORDER BY table_name;

