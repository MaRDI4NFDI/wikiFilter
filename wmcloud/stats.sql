CREATE TABLE mathstat
(
    dbkey       VARCHAR(255) NOT NULL
        PRIMARY KEY,
    no_formulae INT          NULL,
    no_pages    INT          NULL
)
    COMMENT 'contains statistics on use of math on tables';



DROP PROCEDURE IF EXISTS get_formulae_stats;
CREATE PROCEDURE get_formulae_stats()
BEGIN
    DECLARE db VARCHAR(255);
    DECLARE done INT DEFAULT FALSE;
    DECLARE wmfDBs CURSOR FOR SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name LIKE '%wik%'
        AND schema_name NOT IN ('my_wiki', 'wiki_swmath', 'wikidata_importer');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN wmfDBs;
    lo:
    REPEAT
        FETCH wmfDBs INTO db;
        IF DONE THEN
            LEAVE lo;
        END IF;
        SET @sql = CONCAT('INSERT INTO my_wiki.mathstat SELECT "', db
            , '" , count(*) as no_formulae, count(distinct mathindex_revision_id ) no_pages from ', db
            , '.mathindex;');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    UNTIL done END REPEAT;
END;
CALL get_formulae_stats();
