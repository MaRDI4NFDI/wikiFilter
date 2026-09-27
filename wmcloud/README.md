# wmcloud

Scripts to extract all math formulae from the Wikimedia dumps on the WMCloud project
[Math](https://wikitech.wikimedia.org/wiki/Nova_Resource:Math).
The server configuration is in [srv-wmflabs-math26](https://github.com/MaRDI4NFDI/srv-wmflabs-math26).

What was run when is recorded in the [log](Log.md).

## Pipeline

| Step | File |
|------|------|
| Link the latest dump of every wiki to `/data/project/wdump/links/latest` | [updateLinks.sh](updateLinks.sh) |
| Record size and SHA-256 of the linked dumps | [getInputHash.sh](getInputHash.sh) → [inputHashes.csv](inputHashes.csv) |
| Keep only pages with math tags | [filterMath.sh](filterMath.sh) |
| Import each filtered dump into its own wiki | [createAllWikis.sh](https://github.com/MaRDI4NFDI/srv-wmflabs-math26/tree/master/container-scripts/mw) in srv-wmflabs-math26 |
| Export all formulae as JSON | [allFormulae.sql](allFormulae.sql) |
| Count formulae and pages per wiki | [stats.sql](stats.sql) |
