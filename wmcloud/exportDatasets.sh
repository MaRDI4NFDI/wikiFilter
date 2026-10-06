#!/bin/bash
# Step 5: exports from the wiki databases on math26
# * mathstat.csv for https://doi.org/10.5281/zenodo.17838884
# * wmf_texvc_inputs.json for https://doi.org/10.5281/zenodo.15162181
# * enwiki_texvc_inputs.json for https://doi.org/10.5281/zenodo.14209690
set -euo pipefail
OUT="${1:-/data/project/wdump/datasets}"
mkdir -p "$OUT"

sql() {
	sudo docker exec -i db bash -c 'mariadb -uroot -p"$(cat /run/secrets/db_root_password)" --batch --raw -N'
}

# One query per wiki, generated from the tables that exist
perWiki() {
	echo "SELECT CONCAT($1) FROM information_schema.tables WHERE table_name = '$2' ORDER BY table_schema;" | sql
}

# mathstat.csv for https://doi.org/10.5281/zenodo.17838884, from the procedure get_formulae_stats in stats.sql:
# https://archive.softwareheritage.org/swh:1:cnt:bbfb3e9ae859ef265f7900764a5f130128bc16d8;origin=https://github.com/MaRDI4NFDI/wikiFilter;anchor=swh:1:rev:44e3a950047c9f921320c75baf95099ed0f6427d;path=/wmcloud/stats.sql;lines=13-38
echo "dbkey,no_formulae,no_pages" > "$OUT/mathstat.csv"
perWiki "'SELECT ', QUOTE(table_schema), ', COUNT(*), COUNT(DISTINCT mathindex_revision_id) FROM \`', table_schema, '\`.mathindex;'" mathindex |
	sql | tr '\t' ',' >> "$OUT/mathstat.csv"

# From the table math_input and the procedure import_formulae in allFormulae.sql:
# https://archive.softwareheritage.org/swh:1:cnt:faec2206a154db5a2711791f4211097e36bf1413;origin=https://github.com/MaRDI4NFDI/wikiFilter;anchor=swh:1:rev:44e3a950047c9f921320c75baf95099ed0f6427d;path=/wmcloud/allFormulae.sql;lines=16-54
{
	echo "CREATE DATABASE IF NOT EXISTS datasets;"
	echo "CREATE OR REPLACE TABLE datasets.math_input (md5 BINARY(16) NOT NULL PRIMARY KEY, math_input BLOB);"
	perWiki "'INSERT IGNORE INTO datasets.math_input SELECT UNHEX(MD5(math_input)), math_input FROM \`', table_schema, '\`.mathlog;'" mathlog
} | sql
# wmf_texvc_inputs.json for https://doi.org/10.5281/zenodo.15162181, from allFormulae.sql:
# https://archive.softwareheritage.org/swh:1:cnt:faec2206a154db5a2711791f4211097e36bf1413;origin=https://github.com/MaRDI4NFDI/wikiFilter;anchor=swh:1:rev:44e3a950047c9f921320c75baf95099ed0f6427d;path=/wmcloud/allFormulae.sql;lines=66-68
echo "SELECT JSON_DETAILED(JSON_OBJECTAGG(LOWER(HEX(md5)), math_input)) FROM datasets.math_input;" |
	sql > "$OUT/wmf_texvc_inputs.json"
# enwiki_texvc_inputs.json for https://doi.org/10.5281/zenodo.14209690, from allFormulae.sql:
# https://archive.softwareheritage.org/swh:1:cnt:faec2206a154db5a2711791f4211097e36bf1413;origin=https://github.com/MaRDI4NFDI/wikiFilter;anchor=swh:1:rev:44e3a950047c9f921320c75baf95099ed0f6427d;path=/wmcloud/allFormulae.sql;lines=70-73
echo "SELECT JSON_DETAILED(JSON_OBJECTAGG(md5, math_input)) FROM (SELECT DISTINCT MD5(math_input) md5, math_input FROM enwiki.mathlog ORDER BY md5) AS m5mi;" |
	sql > "$OUT/enwiki_texvc_inputs.json"

echo "$(($(wc -l < "$OUT/mathstat.csv") - 1)) wikis in $OUT/mathstat.csv"
echo "$(echo 'SELECT COUNT(*) FROM datasets.math_input;' | sql) inputs in $OUT/wmf_texvc_inputs.json"
echo "$(echo 'SELECT COUNT(DISTINCT math_input) FROM enwiki.mathlog;' | sql) inputs in $OUT/enwiki_texvc_inputs.json"
