-- TP1 : securiser la mediatheque. Syntaxe MySQL 8, pas PostgreSQL/MariaDB.
-- Executer en administrateur APRES Base/01-schema.sql et Base/02-donnees.sql.
-- Les mots de passe ci-dessous servent uniquement au TP.
-- Rejouer ce script recree les comptes du TP et leurs droits.
DROP USER IF EXISTS 'app_media'@'localhost';
DROP USER IF EXISTS 'biblio_marie'@'localhost';
DROP USER IF EXISTS 'stagiaire'@'localhost';
DROP USER IF EXISTS 'analyste'@'localhost';
DROP USER IF EXISTS 'analyste'@'192.168.1.%';
DROP ROLE IF EXISTS 'role_catalogue', 'role_prets', 'role_adherents';

-- 1. Trois roles de metier : aucun droit DELETE, aucun GRANT ALL.
CREATE ROLE 'role_catalogue', 'role_prets', 'role_adherents';
GRANT SELECT ON mediatheque.ouvrage TO 'role_catalogue';
GRANT SELECT ON mediatheque.exemplaire TO 'role_catalogue';
GRANT SELECT ON mediatheque.categorie TO 'role_catalogue';
GRANT SELECT, INSERT, UPDATE ON mediatheque.emprunt TO 'role_prets';
GRANT SELECT, INSERT, UPDATE ON mediatheque.reservation TO 'role_prets';
GRANT SELECT, INSERT, UPDATE ON mediatheque.penalite TO 'role_prets';
GRANT UPDATE (disponible) ON mediatheque.exemplaire TO 'role_prets';
GRANT SELECT, INSERT, UPDATE ON mediatheque.adherent TO 'role_adherents';

-- 2. Comptes : les droits se cumulent entre roles et privileges directs.
CREATE USER 'app_media'@'localhost' IDENTIFIED BY 'Media!2026App';
CREATE USER 'biblio_marie'@'localhost' IDENTIFIED BY 'Marie!2026Bib';
CREATE USER 'stagiaire'@'localhost' IDENTIFIED BY 'Stage!2026Med';
CREATE USER 'analyste'@'localhost' IDENTIFIED BY 'Stats!2026Med';
GRANT 'role_catalogue', 'role_prets' TO 'app_media'@'localhost';
GRANT 'role_catalogue', 'role_prets', 'role_adherents' TO 'biblio_marie'@'localhost';
GRANT 'role_catalogue' TO 'stagiaire'@'localhost';
GRANT 'role_catalogue' TO 'analyste'@'localhost';
-- Ne pas donner role_adherents a l'application ou au stagiaire.
GRANT SELECT (id, nom, prenom, actif) ON mediatheque.adherent TO 'app_media'@'localhost';
GRANT SELECT (id, nom, prenom, ville, date_inscription, actif)
 ON mediatheque.adherent TO 'stagiaire'@'localhost';
-- L'analyste ne doit pas recevoir role_prets : ce role permet d'ecrire.
GRANT SELECT ON mediatheque.emprunt TO 'analyste'@'localhost';
-- Activation automatique a chaque nouvelle connexion.
SET DEFAULT ROLE ALL TO 'app_media'@'localhost', 'biblio_marie'@'localhost',
 'stagiaire'@'localhost', 'analyste'@'localhost';

-- 3. Sorties a conserver : droits directs et roles attribues.
SHOW GRANTS FOR 'app_media'@'localhost';
SHOW GRANTS FOR 'biblio_marie'@'localhost';
SHOW GRANTS FOR 'stagiaire'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';
-- USING permet aussi de relire les droits herites des roles.
SHOW GRANTS FOR 'app_media'@'localhost' USING 'role_catalogue', 'role_prets';
SHOW GRANTS FOR 'biblio_marie'@'localhost'
 USING 'role_catalogue', 'role_prets', 'role_adherents';
SHOW GRANTS FOR 'stagiaire'@'localhost' USING 'role_catalogue';
SHOW GRANTS FOR 'analyste'@'localhost' USING 'role_catalogue';
SELECT GRANTEE, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, PRIVILEGE_TYPE, IS_GRANTABLE
 FROM information_schema.COLUMN_PRIVILEGES
 WHERE TABLE_SCHEMA = 'mediatheque'
 ORDER BY GRANTEE, TABLE_NAME, COLUMN_NAME, PRIVILEGE_TYPE;

-- Cycle demande. Les quatre commandes restent consecutives dans le script.
-- Pour tester le SELECT intermediaire avec analyste, voir GUIDE.md, test 12.
GRANT SELECT ON mediatheque.reservation TO 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';
REVOKE SELECT ON mediatheque.reservation FROM 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';

-- 5. Bonus reseau : meme profil que l'analyste local, apres retrait.
CREATE USER 'analyste'@'192.168.1.%' IDENTIFIED BY 'Stats!2026Med';
GRANT 'role_catalogue' TO 'analyste'@'192.168.1.%';
GRANT SELECT ON mediatheque.emprunt TO 'analyste'@'192.168.1.%';
SET DEFAULT ROLE ALL TO 'analyste'@'192.168.1.%';
-- Si analyste@'%' existe aussi, le compte correspondant au motif le plus
-- specifique est choisi pour une connexion depuis 192.168.1.x.
-- Ses droits ne sont pas fusionnes avec ceux du compte @'%'.
-- Le serveur doit aussi accepter les connexions reseau pour ce bonus.

-- Fin du stage : deux alternatives, laissees en commentaire pour les tests.
-- ALTER USER 'stagiaire'@'localhost' ACCOUNT LOCK;
-- DROP USER 'stagiaire'@'localhost';
-- Je choisis le verrouillage pour suspendre l'acces en conservant le compte
-- et ses droits, si une reprise du stage est envisagee. Pour un depart
-- definitif sans reutilisation prevue, la suppression est adaptee.
