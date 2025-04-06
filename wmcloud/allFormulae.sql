-- This file uses MaRIA DB specific JSON commands

-- Find unrelated database names
SELECT
TABLE_SCHEMA AS ALL_DATABASE_NAME,
 MAX(create_time) AS creationTime,
 MAX(update_time) updatingTime
FROM INFORMATION_SCHEMA.TABLES
GROUP BY ALL_DATABASE_NAME
ORDER BY creationTime DESC;
-- List all wiki databases
SELECT schema_name  FROM information_schema.schemata
WHERE schema_name LIKE '%wik%'
  AND schema_name NOT IN ('my_wiki', 'wiki_swmath', 'wikidata_importer');
-- Create simple table for all input
create table my_wiki.math_input
(
    md5        binary(16) not null comment 'md5 sum of the input'
        primary key,
    math_input blob          null
)
    comment 'Holds all formulae from all wikimedia projects';
-- Test input from single wiki
insert ignore into my_wiki.math_input
SELECT unhex(md5(math_input)), math_input from dewiki.mathlog LIMIT 10;

-- Get input from all wikis
DROP PROCEDURE IF EXISTS import_formulae;
CREATE PROCEDURE import_formulae()
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
        -- Add limit 10 to test (runtime with limit 10 ~ 10s)
        SET @sql = CONCAT('INSERT IGNORE INTO my_wiki.math_input SELECT unhex(md5(math_input)), math_input FROM ', db, '.mathlog;');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    UNTIL done END REPEAT;
END;
-- 6 minutes
CALL import_formulae();

-- Test JSON export on sample
CREATE or replace view fsample as
SELECT lower(hex(md5)) md5, math_input
from my_wiki.math_input
limit 10;
select *
from fsample;
SELECT JSON_DETAILED(JSON_OBJECTAGG(md5, math_input)) AS formulae
from fsample;

-- Real export for 10.5281/zenodo.15162182 --> wmf_texvc_inputs.json
SELECT JSON_DETAILED(JSON_OBJECTAGG(md5, math_input))
from (SELECT lower(hex(md5)) md5, math_input from my_wiki.math_input) as m5mi;

-- Update for https://doi.org/10.5281/zenodo.14209690
SELECT JSON_DETAILED(JSON_OBJECTAGG(md5, math_input)) FROM (
    SELECT md5(math_input) md5, math_input from enwiki.mathlog order by md5
) as m5mi;
