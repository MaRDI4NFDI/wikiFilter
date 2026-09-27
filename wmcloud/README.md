# wmcloud

Scripts to extract all math formulae from the Wikimedia dumps on the WMCloud project
[Math](https://wikitech.wikimedia.org/wiki/Nova_Resource:Math).
They run on the instance math26, which is set up by
[srv-wmflabs-math26](https://github.com/MaRDI4NFDI/srv-wmflabs-math26).
Past runs are in the [log](Log.md).

## Datasets

| Zenodo | Content | Step |
|--------|---------|------|
| [10.5281/zenodo.15058128](https://doi.org/10.5281/zenodo.15058128) | Wikipedia articles with math tags (`math.tar`, `inputHashes.csv`) | 2, 3 |
| [10.5281/zenodo.15162181](https://doi.org/10.5281/zenodo.15162181) | all math inputs (`wmf_texvc_inputs.json`) | 5 |
| [10.5281/zenodo.17838884](https://doi.org/10.5281/zenodo.17838884) | statistics on math use (`mathstat.csv`) | 5 |
| [10.5281/zenodo.15612155](https://doi.org/10.5281/zenodo.15612155) | MathML rendering of all inputs (`mathlog.csv`) | 6 |

## Setup

On math26, clone this repository into the home directory and run the long steps in `screen`:

```bash
git clone https://github.com/MaRDI4NFDI/wikiFilter.git ~/wikiFilter
cd ~/wikiFilter/wmcloud
```

The dumps are read from the WMCS mount `/public/dumps/public`.
All results go to the project NFS share `/data/project/wdump`, which survives a rebuild of the instance.

## Steps

### 1. Link the latest dumps

```bash
bash updateLinks.sh
```

[updateLinks.sh](updateLinks.sh) links the latest `pages-articles-multistream` dump of every wiki to `/data/project/wdump/links/latest`.
Takes seconds.
Existing links are kept; they point to the `latest` symlink of each wiki and follow new dumps.

### 2. Record the dump hashes

```bash
bash getInputHash.sh > inputHashes.csv
```

[getInputHash.sh](getInputHash.sh) writes the size, creation date and SHA-256 of every linked dump to [inputHashes.csv](inputHashes.csv).
Reads all dumps once (about 430 GiB), which took about 1.5 hours in September 2026.
Commit the new `inputHashes.csv`.

### 3. Filter the dumps for math

```bash
bash filterMath.sh
```

[filterMath.sh](filterMath.sh) runs [wikiFilter.py](../wikiFilter.py) on every linked dump and keeps the pages with math tags.
Writes one `<wiki>.xml.bz` per wiki to `/data/project/wdump/math`, overwriting the previous run.
Takes many hours.
The files, packed as `math.tar`, and `inputHashes.csv` make up the first dataset.

### 4. Import the filtered dumps

Inside the MediaWiki container on math26, create one wiki per filtered dump:

```bash
sudo docker exec -it mediawiki-fpm bash -c 'cd /var/www/html/scripts && ./createAllWikis.sh'
```

The scripts are in [srv-wmflabs-math26](https://github.com/MaRDI4NFDI/srv-wmflabs-math26/tree/master/container-scripts/mw).
The logs go to `/data/project/wdump/math/log`.

### 5. Export the inputs and statistics

In the database container, [allFormulae.sql](allFormulae.sql) collects the inputs of all wikis
and exports them as JSON, and [stats.sql](stats.sql) counts formulae and pages per wiki.
Both write to tables in the database `my_wiki`.

### 6. Render all inputs

MathSearch's [maintenance/MathPerformance.php](https://github.com/wikimedia/mediawiki-extensions-MathSearch/blob/master/maintenance/MathPerformance.php) renders all inputs and exports the results as `mathlog.csv`.

Steps 4 to 6 have not been run on math26 yet; the next runs will add the exact commands to the [log](Log.md).
