## 2026-10-14
<details>
<summary>started the MathML and SVG of all inputs from RESTBase (step 6)</summary>

* 20:43 UTC: a trial of `UpdateMath --mode mathml --SVG` against the production RESTBase (`$wgMathFullRestbaseURL`, `https://wikimedia.org/api/rest_`) on testwiki
  stopped at the first input that RESTBase rejected, as UpdateMath asked for its SVG anyway.
  Gerrit change 1354086 (commit c4dc26e) counts a rendering without MathML as failed and asks for the SVG only after a successful rendering.
* 20:47 UTC: the trial with c4dc26e took 63 s for 973 tags, about 80 ms per input; 770 inputs got MathML and SVG, 10 failed.
  MathML has 1,488 bytes on average, SVG 6,994 bytes.
* The requests carry the User-Agent `MediaWiki/1.47.0-wmf.21 (https://test.wiki.beta.math.wmflabs.org)`, with the URL of each wiki.
* 21:27 UTC: copies of `testwiki.mathlog` took 47 % of the space with `ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8` and 32 % with `KEY_BLOCK_SIZE=4`
  (`compress-261014.log`); uncompressed, all inputs would need about 49 GB, and `/srv` had 41 GB free.
* 21:31 UTC: the screen session `restbase261014` (`restbase-261014-run.log`) set `mathlog` of all wikis to `ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8`
  and runs `UpdateMath --mode mathml --SVG` on all wikis, 2 at a time, logging to `restbase-261014/`.
  Every 5 minutes it logs the free space in `disk.log`, and it stops UpdateMath below 5 GB.
* `docker image prune` removed the untagged images of `wikibase` and `apache-assets`, 2.86 GB; `/srv` then had 45 GB free.
</details>

## 2026-10-13
<details>
<summary>indexed all inputs again with Gerrit change 1354086 (step 5)</summary>

* 05:14 UTC: the screen session `full261013` ran `/tmp/full-261013.sh` with commit a66cde8 (`full-261013.log`).
  On all 663 wikis, `mathlog` and `mathindex` were renamed to `mathlog_261009` and `mathindex_261009`, which keep the renderings of the run from 2026-10-09,
  and recreated empty.
  `UpdateMath --mode source` took 1,388 s for cawiki with 4 wikis in parallel; it was stopped after 181 wikis.
* 06:44 UTC: `full261013b` (commit f18301a, binary hashes, one query per revision for the index and for the new inputs) took 862 s for cawiki alone.
  The commits took 0.8 s; the rest was the chunk query of UpdateMath, which joined `slots` on `slot_origin`, a column without an index.
* 07:01 UTC: `full261013c` (commit 1e6b7a0, `slots` joined on `slot_revision_id`) recreated `mathlog` and `mathindex` with `binary(16)` hashes:
  * cawiki alone took 24 s for 167,140 formulae.
  * 07:04–07:18 UTC: the other 662 wikis, 4 at a time; all 663 ended with `Updated`, the slowest was enwiki with 529 s.
  * Checks (`full-261013c/check/`): mathindex has all 10,518,101 tags of the current revisions, with the expected hash and a `mathlog` row each.
    `mathlog` has 5,748,142 inputs.
  * 56 tags in 22 wikis have an id attribute longer than the 50 bytes of `mathindex_anchor`, so their anchor is cut off; enwiki has 11, such as URLs used as ids.
  * 84 inputs of the check script come from JavaScript pages, which UpdateMath skips; without them, the five wikis checked again have none missing.
* `mathperformance` keeps the hex hashes: its 89 million rows (16 GB) were not converted, as `/srv` has 5 GB free.
  The `*_261009` tables take 14.8 GB.
</details>

<details>
<summary>rebuilt mathindex of 22 wikis for ids over 50 bytes, cleaned up math26</summary>

* 08:14–08:39 UTC: the screen session `anchors261013` deployed commit bd86998, where an id attribute longer than the 50 bytes of
  `mathindex_anchor` is not used as anchor.
  It emptied `mathindex` of the 22 wikis with such ids and ran `UpdateMath --mode source` there (`anchors-261013.log`).
  All 22 wikis now have every tag with its expected anchor and hash.
* Removed the scripts of the runs from 2026-10-09 to 2026-10-13 in `/tmp` of math26 and of `mediawiki-fpm`, and `~/update-261009.sh`.
* Quit the idle screen sessions `check`, `import`, `filter` and `hashes` from September and 2026-10-03.
* Not removed: the `*_261009` tables (14.8 GB), `mathperformance` (16 GB) and older files in `/tmp`; `/srv` has 5.8 GB free.
  Watchtower is still stopped.
</details>

<details>
<summary>dropped the old tables and the old rows of mathperformance, exported the inputs (step 5)</summary>

* 14:25 UTC: the screen session `drop261013` dropped the 1,326 tables `mathlog_261009` and `mathindex_261009` (`drop-261013.log`).
  `/srv` went from 5.8 GB to 24 GB free.
  None of the 95,895,327 rows of `mathperformance` had a 16-byte hash, so all are deleted, wiki by wiki.
  Each table is then optimized, and its hash column, like that of `mathobservation`, becomes `binary(16)`.
* 14:52 UTC: the screen session `export261013` runs [exportDatasets.sh](exportDatasets.sh) of commit 4d3930b,
  copied with `scp` to `/tmp/zenodo261013`, writing to `/data/project/wdump/datasets-261013` (`export-261013.log`).
  The export of 2026-10-09 stays in `/data/project/wdump/datasets`.
  It finished at 15:29 UTC with 4,176,901 inputs of all wikis and 676,371 of enwiki; 646 of 663 wikis have formulae.
* 15:30 UTC: the screen session `final261013` validated the export, deployed commit 0b1e59b, where the hash leaves out the id,
  and emptied `mathlog` and `mathindex` to rebuild them.
* 15:32 UTC: the kernel killed `mariadbd` for lack of memory (8.6 GB resident), while both sessions ran SQL on all wikis.
  `mathlog` and `mathindex` were empty in about 125 wikis, and 68,185,551 rows of `mathperformance` were left.
  15:37 UTC: `docker compose up -d database`; InnoDB recovered and was ready at 15:38:58.
* The dumps of 4 wikis were imported only in part, as the import stops at an unknown content model:
  commonswiki (1 of 9,155 pages, `wikibase-mediainfo`), wikidatawiki (142 of 209, `wikibase-item`),
  test2wiki (133 of 186) and sourceswiki (10 of 25, both `proofread-page`).
  A scan of all dumps (`models-261013.tsv`) found `proofread-page` outside Wikisource only in these two.
  srv-wmflabs-math26 commit fc8403d loads ProofreadPage for them; it is applied to the checkout on math26 by hand,
  which is at 4303ccf, so `LocalSettings.php` has to be reset before the next `git pull`. `mediawiki-fpm` was restarted.
* 15:41 UTC: the screen session `final2261013` runs one step after the other (`final2-261013.log`):
  importDump again for sourceswiki and test2wiki, the rebuild with 0b1e59b, the checks, the export to `datasets-261013`,
  its validation, and `TRUNCATE` of `mathperformance`, whose rows all have the old hashes.
* The screen session `zenodo261013` got the token through stdin; it is only in its environment.
  It waits for `final2261013`, stops if the run is not clean, writes the numbers into the descriptions,
  discards the drafts 23267246 and 23267715 of 2026-10-09 and creates new drafts of 17838885, 14209690 and 15162182
  (`zenodo-261013.log`, descriptions in `zenodo-261013/`).
</details>
<details>
<summary>exported the inputs again and uploaded the drafts to Zenodo (step 5)</summary>

* `final2261013` (`final2-261013.log`):
  * importDump added the missing pages of sourceswiki (10 to 26) and test2wiki (133 to 187).
  * 15:41–16:13 UTC: UpdateMath `--mode source` with commit 0b1e59b on all 663 wikis, all ended with `Updated`.
  * The checks found all 10,518,347 tags of the current revisions in `mathindex`, each with the expected hash and a row in `mathlog`.
  * 16:19–18:09 UTC: the export to `datasets-261013`; it took longer than at 14:52, as MariaDB has run with a buffer pool of 128 MB since the restart.

| File | Content | SHA-256 |
|---|---|---|
| `mathstat.csv` | 663 wikis, 646 with formulae, 10,518,347 formulae on 511,334 pages | `5a5b8b90ec03d49567811a27372ca5d3c126cf0f035e3836931d4382c9358511` |
| `wmf_texvc_inputs.json` | 4,176,968 inputs, the longest with 263,688 bytes | `b55321b61a8d618b7184971ff7dddc7487d715332f8672b99941144ee6dac430` |
| `enwiki_texvc_inputs.json` | 676,371 inputs | `9e78d8af6c8b8f57e6250a96c31529589cf3f399f955677b42acd4d08c5f2971` |

  * All keys of both JSON files are MD5 hashes.
  * 18:10–18:17 UTC: `TRUNCATE` of `mathperformance` on all wikis, whose hash column, like that of `mathobservation`, is now `binary(16)`.
    `/srv` has 41 GB free.
* `zenodo261013` (`zenodo-261013.log`), from 18:17 UTC:
  * The drafts 23267246 and 23267715 of 2026-10-09 were discarded (HTTP 204).
  * The descriptions got the new numbers and a limitation on Commons and Wikidata; they are in [zenodo](zenodo).
  * Zenodo answered uploads of the JSON files with `502 Bad Gateway` at times; the script discarded the draft each time and tried again 10 minutes later.

| Record | File | Attempts | Draft |
|---|---|---|---|
| 17838885 | `mathstat.csv` | 1 | [23348689](https://zenodo.org/uploads/23348689) |
| 14209690 | `enwiki_texvc_inputs.json` | 3 | [23349217](https://zenodo.org/uploads/23349217) |
| 15162182 | `wmf_texvc_inputs.json` | 5 | [23350852](https://zenodo.org/uploads/23350852) |

  * The session ended at 20:37 UTC, and with it the token.
</details>

## 2026-10-11
<details>
<summary>tested Gerrit change 1354086 on math26</summary>

* 12:26 UTC: the screen session `test261011` ran `/tmp/test-261011.sh`, copied with `scp` together with `/tmp/ms-1354086.patch` (commit 1823531), logging to `/data/project/wdump/math/test-261011.log`:
  * Backup in `/data/project/wdump/math/test-261011/`: `ms-before.diff` has the HEAD (634bbff), the diff and the untracked files of MathSearch in the container;
    `<wiki>-before.sql.gz` dumps `mathlog` and `mathindex` of testwiki, hawiki and bewikisource.
  * MathSearch in the container at master df4eda1 plus the patch; php-fpm reloaded.
  * The checks failed, as `eval.php` reads its input line by line and `/usr/bin/time` is not installed.
    So the three wikis were emptied without UpdateMath, and the script was stopped.
    The `foreachwiki` of `DeleteOldRevisionsFromIndex` it had started kept running in the container until 12:31 UTC.
* 12:28 UTC: the screen session `retest261011` ran `/tmp/retest-261011.sh` with the checks as maintenance scripts (`retest-261011.log`).
  * Saving `T439313` on testwiki (the test page of the local wiki) indexed each revision with 16 rows, all with a `mathlog` row.
    A page view wrote nothing; the ids on the page matched the local wiki.
    `DeleteOldRevisionsFromIndex` deleted the 2 older revisions; deleting the page deleted the rest.
  * UpdateMath after emptying `mathlog` and `mathindex`, compared with the math tags of the current revisions in any content model:

| wiki | pages | tags | `mathindex` rows | missing | other hash | old revisions | without `mathlog` | `mathlog` rows | time |
|---|---|---|---|---|---|---|---|---|---|
| testwiki | 80 | 976 | 976 | 0 | 0 | 0 | 0 | 976 | 5 s |
| hawiki | 98 | 640 | 640 | 0 | 0 | 0 | 0 | 640 | 3 s |
| bewikisource | 251 | 7,023 | 7,023 | 0 | 0 | 0 | 0 | 5,332 | 25 s |

  * `mathlog` has a row per tag rather than per input: testwiki has 784 distinct hashes, hawiki 480, bewikisource 4,396.
    The full rerun has the same, e.g. 770,501 rows for 344,808 inputs in dewiki.
    `isInDatabase()` does not see the inserts that `writeToCache()` defers, and the key on `math_inputhash, math_mode` is not unique.
* `DeleteOldRevisionsFromIndex` joined `page` on `page_latest`, which has no index; it took minutes for cawiki.
  Joined via `revision` it takes 0.4 s; the change was amended (f2d1248).
* 12:33–12:35 UTC: the screen session `deleteold261011b` ran the amended script on all wikis (`test-261011/delete-old-3.log`):
  663 wikis, none failed, none had old revisions.
</details>
<details>
<summary>kept the search for math tags in the wikitext</summary>

[Gerrit change 1354086](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1354086) indexes every math tag of a page's own wikitext when the revision is saved,
so the statistics count formulae that a page does not render, such as those on `Page:` pages without ProofreadPage on math26.
Finding the tags in the wikitext only approximates the parser:
the parser leaves the content of every registered tag to its extension, which may parse it, as Cite does for `<ref>`.
Recording the formulae during the parse, as TemplateData and GeoData record their data, would be exact,
but would index only what renders.
Then the dumps would need templates and modules (`wikiFilter.py --template`), and all steps would have to run again.
The current dumps stay; the exact way, together with a single maintenance script in MathSearch for all steps, is [T440805](https://phabricator.wikimedia.org/T440805).
The limits of the filter are now in the [README](README.md#3-filter-the-dumps-for-math).
</details>

## 2026-10-09
<details>
<summary>prepared math26 for the export of all inputs (step 5)</summary>

Inputs longer than 65,535 bytes no longer fit into `mathlog.math_input`, which was a `TEXT` column.
They were cut off, once inside a multibyte character in ruwiki, which made the JSON export invalid.
[Gerrit change 1353889](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1353889) makes the column `MEDIUMTEXT`, as large as the text of a revision.

* 14:37 UTC: stopped watchtower, so it does not recreate `mediawiki-fpm` during the runs:
```bash
sudo docker stop beta-watchtower-1
```
* 14:40 UTC: MathSearch in the container at [patch set 2 of Gerrit change 1353889](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1353889/2), replacing the patches applied by hand, which are all merged:
```bash
sudo docker exec mediawiki-fpm bash -c "cd /var/www/html/w/extensions/MathSearch && git fetch --depth 1 https://gerrit.wikimedia.org/r/mediawiki/extensions/MathSearch refs/changes/89/1353889/2 && git reset --hard FETCH_HEAD"
```
* From 14:44 UTC: `update.php` on all wikis, started over ssh from a local machine.
  At 14:49:55 UTC a DELETE removed the 12 rows whose input had exactly 65,535 bytes:
  banwiki, plwiki, testwiki, siwiki, enwiki, idwiki, ruwiki (2), metawiki, dewiki, enwikisource and enwiktionary.
  It ran while `update.php` altered the same tables, which slowed both down.
  UpdateMath does not rewrite existing rows, so the cut inputs had to be deleted to be stored again.
* The local ssh session ended at enwiki, but foreachwiki kept running without output.
  It was stopped after the ALTER of enwiki had finished at 14:58:35 UTC.
  The `math26` entry of `~/.ssh/config` has `RequestTTY force`, so commands with piped input need `ssh -T`.
* 15:15 UTC: replaced the core fix of the WANObjectCache stats with the non-test files of [patch set 10 of Gerrit change 1351365](https://gerrit.wikimedia.org/r/c/mediawiki/core/+/1351365/10), as 1350817 is abandoned.
  `StatsFactory::newNull()` now uses `Wikimedia\Stats\NullStatsCache`.
* 15:15:55 UTC: `update.php` on all wikis in the screen session `update`, with `~/update-261009.sh` copied with `scp`, logging to `/data/project/wdump/math/update-261009.log`.
* 15:32 UTC: the screen session `datasets` waited for `update`, then ran `/tmp/datasets-261009.sh`, copied with `scp`, logging to `/data/project/wdump/math/datasets-261009.log`.
  It ran UpdateMath on the revisions with a hash in `mathindex` but not in `mathlog`.
  `update.php` had changed 518 wikis, none failed.
* The query found far more revisions than deleted rows, for example 2 in banwiki, 90 in plwiki and 9,175 of 47,355 in enwiki.
  At 15:52 UTC the session was stopped after banwiki, plwiki, testwiki and part of siwiki, which only stored the same formulae again.
* 15:54:40 UTC: the screen session `datasets` runs `/tmp/datasets-261009b.sh`, logging to `/data/project/wdump/math/datasets-261009b.log`.
  For each of the 11 wikis, `/tmp/longTags.php` lists the current revisions with a math tag of more than 65,000 bytes, for ruwiki the expected 2.
  UpdateMath runs on these revisions, then `/tmp/exportDatasets.sh` exports step 5.
  The three files were copied with `scp`; `exportDatasets.sh` is the version of the next commit, which stores the inputs in a `MEDIUMBLOB`.
</details>

<details>
<summary>exported the inputs (step 5)</summary>

`/tmp/datasets-261009b.sh` found one revision per wiki and two in ruwiki, and stored the 12 inputs again by 15:59:21 UTC.
Each run of UpdateMath ended with `1 failed`: the inputs are the rest of a page after an unclosed tag, so the TeX check fails.
All 12 are complete now:

| wiki | bytes |
|---|---|
| banwiki | 114,566 |
| plwiki | 94,866 |
| testwiki | 114,878 |
| siwiki | 105,240 |
| enwiki | 162,713 |
| idwiki | 102,409 |
| ruwiki | 263,688 (the longest of two) |
| metawiki | 71,958 |
| dewiki | 165,069 |
| enwikisource | 121,859 |
| enwiktionary | 86,241 |

The export ran from 16:01:32 to 16:15:11 UTC:

| file | size | content | MD5 |
|---|---|---|---|
| `mathstat.csv` | 11 KB | 663 wikis, 590 with at least one math tag | `69fc56164c94a62c7690732937ed486f` |
| `wmf_texvc_inputs.json` | 442 MB | 4,165,088 inputs | `71e898385ef71324ee04476068f966cf` |
| `enwiki_texvc_inputs.json` | 70 MB | 676,297 inputs | `918ee525fa126ec961eefd58e6ebe716` |

`/tmp/check-261009.sh`, copied with `scp`, checked them with `jq` in the screen session `check261009` (`/data/project/wdump/math/check-261009.log`):
both JSON files parse, all keys are MD5 hashes, the longest input has 263,688 bytes (enwiki: 162,713), and `281a70c20b16a38d7781189936e1ac9f` maps to `E = mc^2`.
</details>

<details>
<summary>uploaded drafts of the inputs to Zenodo (step 5)</summary>

The descriptions and metadata are in [zenodo](zenodo), one directory per dataset; they were copied to `/tmp/zenodo261009` with `scp`.
`/tmp/zenodo-261009.sh`, copied with `scp`, runs [zenodoUpload.sh](zenodoUpload.sh) for each record in the screen session `zenodo`.
The token is read from standard input into the environment of the session, so it is in no file:
```bash
ssh -T math26 'read -r ZENODO_TOKEN; export ZENODO_TOKEN; screen -dmS zenodo bash -c "bash /tmp/zenodo-261009.sh > /data/project/wdump/math/zenodo-261009b.log 2>&1"'
```
* 16:18 UTC: the first attempt failed for all three records with `502 Bad Gateway` or `504 Gateway Time-out` from Zenodo; zenodoUpload.sh discarded the drafts 23267001, 23267022 and 23267047.
* 16:27 UTC: the second attempt tries each record up to 8 times, 10 minutes apart (`/data/project/wdump/math/zenodo-261009b.log`).
  Zenodo answered 410 for the concept records 17838884 and 15162181, so it was stopped.
* 16:29 UTC: the third attempt uses the version records 17838885, 14209690 and 15162182 (`/data/project/wdump/math/zenodo-261009c.log`).
  * 17:15 UTC: draft [23267246](https://zenodo.org/uploads/23267246) of the statistics, after five attempts.
    Zenodo had answered the discard of attempt 2 with 504, so attempt 5 reused that draft.
  * By 17:35:48 UTC: draft [23267715](https://zenodo.org/uploads/23267715) of the enwiki inputs, at the second attempt.
  * All 8 uploads of `wmf_texvc_inputs.json` (442 MB) ended with `502 Bad Gateway`; at 21:33 UTC the session gave up.
* The drafts are not published.
</details>

<details>
<summary>found gaps between mathlog and mathindex</summary>

`mathstat.csv` counts the rows of `mathindex`; 73 of 663 wikis had none, although every filtered dump has a math tag.
Their formulae are in `mathlog`, but the hooks index only formulae that a page renders,
for example not the tag in `Module:Convert` of acewiki or those on the `Page:` pages of bewikisource.
In the other direction, 9,175 of 47,355 revisions of enwiki had a hash in `mathindex` without a row in `mathlog`:
`MathObject::cloneFromRenderer()` hashed without the attributes of the tag, unlike Math.
mathlog also had most inputs twice (1,389,090 rows for 676,297 inputs in enwiki), as the hooks and UpdateMath both insert.
So the draft of the statistics must not be published.
The inputs do not depend on this, as `exportDatasets.sh` hashes them again.

The fixes, all for [T439313](https://phabricator.wikimedia.org/T439313):
* [Gerrit change 1354086](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1354086): UpdateMath indexes every tag, with the hash of the renderer and unique anchors.
* [Gerrit change 1354089](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1354089), merged: UpdateMath skipped the newest revision when a chunk started there, by default when its id was a multiple of 100.
* [Gerrit change 1354091](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1354091): `mathlog.math_params` stores the attributes, for an export in the form of `reference.json`.
</details>

<details>
<summary>started a full rerun of UpdateMath (step 5)</summary>

* 21:44:59–21:47:19 UTC: the screen session `truncate` emptied `mathlog` and `mathindex` of all 663 wikis with `/tmp/truncate-261009.sh`, copied with `scp` (`/data/project/wdump/math/truncate-261009.log`).
  Two minutes later enwiki had 129 rows again, written by the hooks for page views.
* 21:49:33 UTC: the screen session `rerun` runs `/tmp/rerun-261009.sh` (`/data/project/wdump/math/rerun-261009.log`), copied with `scp` together with `/tmp/ms-combined-261009.patch`:
  * MathSearch in the container at master [634bbff](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1354089), plus patch set 1 of 1354086 and 1354091,
    combined in a local worktree, where both conflicted only in `cloneFromRenderer()` and the tests; the full suites passed on the combination.
  * `update.php` on all wikis for `math_params`.
  * `mathlog` and `mathindex` emptied again, as the page views had written rows with the old code.
  * UpdateMath on all 663 wikis, 4 at a time, logging to `/data/project/wdump/math/updatemath-261009/`, with the available memory every 10 minutes in `memory.log`.
</details>

## 2026-10-05
<details>
<summary>UpdateMath rerun finished</summary>

The rerun in the screen session `updatemath2` finished at 02:36:29 UTC.
All 381 wikis ended with `Updated N formulae`, none failed; enwiki processed all 48,690 revisions.
`memory.log` has no samples after 02:36 UTC, see the next entry.
</details>

<details>
<summary>imported all dumps a second time</summary>

The waiting loops of `reimport.sh` and of the memory logger in `rerun.sh` used `pgrep -f 'run MathSearch:UpdateMath'`.
That also matched the command line of the screen session `updatemath` of the first run, which was still open with an idle shell.
So the re-import waited until that session was closed shortly after 15:16 UTC:

```bash
screen -S updatemath -X quit
```

The re-import ran from 15:19:36 to 15:27:17 UTC.
All 659 imports ended with `Done!`, no wiki gained pages, but 3 wikis gained revisions (`reimport/changed.txt`):

| wiki | pages | revisions before → after |
|---|---|---|
| frwiki | 22,684 | 22,684 → 22,686 |
| hewiki | 7,410 | 7,410 → 7,411 |
| liquidthreads_labswikimedia | 8 | 8 → 15 |

The new revisions are copies of existing ones, with the same timestamp and content, and became `page_latest`.
importDump compares the `sha1` declared in the dump with the hash of the stored text, but the dump declares it for the text as stored on Wikipedia,
see [T440235](https://phabricator.wikimedia.org/T440235):

* frwiki, `Wikipédia:Caractères spéciaux/Caractères phonétiques` and `…/Caractères cyrilliques`: the text contains `\r\n`, which XML parsing turns into `\n`.
* hewiki, `ויקיפדיה:ניקוד/סקר ניקוד`: the stored text is not in NFC, the dump contains it in NFC.
* liquidthreads_labswikimedia, 7 `Thread:` pages: the dump has an empty `<sha1 />`, so importDump does not check for duplicates.

The texts on math26 are correct, so the dumps and the formulae are unaffected.
At 19:42 UTC `/tmp/dedupe.sql`, copied to math26 with `scp`, made the originals current again and deleted the copies:

```bash
ssh math26 'sudo docker exec -i db bash -c "mariadb -uroot -p\"\$(cat /run/secrets/db_root_password)\" -t" < /tmp/dedupe.sql'
```

```sql
-- Removes the revisions that the second import duplicated, see wmcloud/Log.md of 2026-10-05
START TRANSACTION;
UPDATE frwiki.page SET page_latest = (SELECT MIN(rev_id) FROM frwiki.revision WHERE rev_page = page_id) WHERE page_id IN (1046, 1088);
DELETE FROM frwiki.slots WHERE slot_revision_id IN (22685, 22686);
DELETE FROM frwiki.revision WHERE rev_id IN (22685, 22686);
COMMIT;

START TRANSACTION;
UPDATE hewiki.page SET page_latest = (SELECT MIN(rev_id) FROM hewiki.revision WHERE rev_page = page_id) WHERE page_id = 2402;
DELETE FROM hewiki.slots WHERE slot_revision_id = 7411;
DELETE FROM hewiki.revision WHERE rev_id = 7411;
COMMIT;

START TRANSACTION;
UPDATE liquidthreads_labswikimedia.page SET page_latest = (SELECT MIN(rev_id) FROM liquidthreads_labswikimedia.revision WHERE rev_page = page_id) WHERE page_id BETWEEN 2 AND 8;
DELETE FROM liquidthreads_labswikimedia.slots WHERE slot_revision_id BETWEEN 9 AND 15;
DELETE FROM liquidthreads_labswikimedia.ip_changes WHERE ipc_rev_id BETWEEN 9 AND 15;
DELETE FROM liquidthreads_labswikimedia.revision WHERE rev_id BETWEEN 9 AND 15;
COMMIT;

SELECT 'frwiki' w, (SELECT COUNT(*) FROM frwiki.page) pages, (SELECT COUNT(*) FROM frwiki.revision) revisions, (SELECT COUNT(*) FROM frwiki.page WHERE page_latest NOT IN (SELECT rev_id FROM frwiki.revision)) dangling
UNION ALL SELECT 'hewiki', (SELECT COUNT(*) FROM hewiki.page), (SELECT COUNT(*) FROM hewiki.revision), (SELECT COUNT(*) FROM hewiki.page WHERE page_latest NOT IN (SELECT rev_id FROM hewiki.revision))
UNION ALL SELECT 'lqt', (SELECT COUNT(*) FROM liquidthreads_labswikimedia.page), (SELECT COUNT(*) FROM liquidthreads_labswikimedia.revision), (SELECT COUNT(*) FROM liquidthreads_labswikimedia.page WHERE page_latest NOT IN (SELECT rev_id FROM liquidthreads_labswikimedia.revision));
```

Afterwards pages and revisions were equal again: frwiki 22,684, hewiki 7,410, liquidthreads_labswikimedia 8, and no `page_latest` without revision.

The import completeness should be checked by comparing page counts in the future, not by importing again.
</details>

<details>
<summary>compared two core fixes for the WANObjectCache stats</summary>

For [T440146](https://phabricator.wikimedia.org/T440146), the code of [patch set 1 of Gerrit change 1350817](https://gerrit.wikimedia.org/r/c/mediawiki/core/+/1350817/1) (main StatsFactory in CLI mode)
was compared with [patch set 1 of Gerrit change 1351365](https://gerrit.wikimedia.org/r/c/mediawiki/core/+/1351365/1) (NullStatsCache), both applied in the container with `git apply`.
UpdateMath on frwikiversity, revisions 2000–2200, chunk size 25, one variant after the other on the idle machine:

| variant | round 1 | round 2 | peak memory | memory at the end |
|---|---|---|---|---|
| no fix | 319.8 s | 318 s | 185 MB | 139 MB |
| 1350817 | 304.1 s | 306 s | 115 MB | 49 MB |
| 1351365 | 300.2 s | 317 s | 113 MB | 49 MB |

The round 2 times are taken from the modification times of the logs.
Both fix the memory growth equally; the time differences are within the spread between the rounds.
Afterwards the container has 1350817 applied again.
</details>

## 2026-10-04
<details>
<summary>the database crashed during UpdateMath, restarted it</summary>

At 11:29:27 UTC MariaDB aborted after 14 h of UpdateMath:
`innodb_fatal_semaphore_wait_threshold was exceeded for dict_sys.latch`.
Its log had been silent since 11:04 UTC.
The container has no restart policy, so all later wikis failed within seconds.

* Memory was nearly full, 14 of 15 GB, without swap.
  The UpdateMath processes of enwiki had 4.8 GB and of frwikiversity 4.3 GB.
* The OOM killer did not run.
* enwiki stopped at revision 43,000 of 48,690.
* 282 of 663 wikis finished; 381 failed.

The database was started again and recovered without errors:

```bash
cd /srv/srv-wmflabs-math26 && sudo docker compose up -d database
```
</details>

<details>
<summary>reran UpdateMath for the failed wikis with the memory fix</summary>

The hooks of MathSearch kept the id generator of every revision.
UpdateMath renders all revisions in one process, so its memory grew with the number of pages.
The fix, [patch set 1 of Gerrit change 1350612](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1350612/1), before it was merged,
was copied into the container with `scp` and applied with `git apply` on top of MathSearch [55886b8](https://archive.softwareheritage.org/swh:1:rev:55886b87eea3b53b80c405070cbc54f61767ef54;origin=https://github.com/wikimedia/mediawiki-extensions-MathSearch), the merged [patch set 3 of Gerrit change 1349809](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1349809/3).
php-fpm was reloaded with `sudo docker kill --signal=USR2 mediawiki-fpm`.

Started 13:29:43 UTC in the screen session `updatemath2`:

```bash
screen -dmS updatemath2 bash -c "sudo bash /tmp/rerun.sh 2>&1 | sudo tee /data/project/wdump/math/updatemath/rerun.out > /dev/null"
```

`/tmp/rerun.sh` was copied to math26 with `scp`.
It moves the logs of the failed wikis to `updatemath/failed-261004/`, reruns them four at a time,
and writes the free memory and the memory of each UpdateMath process to `updatemath/memory.log` every 5 minutes:

```bash
#!/bin/bash
# Rerun UpdateMath for the wikis that failed in the first run, and sample memory every 5 minutes
D=/data/project/wdump/math/updatemath
cd $D || exit 1
mkdir -p failed-261004
for f in $(grep -LE '^Updated [0-9]+ formulae' *.log); do mv "$f" failed-261004/; done
ls failed-261004 | sed 's/\.log$//' > failed-261004/list.txt
echo "$(wc -l < failed-261004/list.txt) wikis to rerun"
date -u
(
	sleep 30
	while pgrep -f 'run MathSearch:UpdateMath --wiki' > /dev/null; do
		t=$(date -u +%FT%H:%M)
		echo "$t available_mb=$(free -m | awk '/^Mem/{print $7}')" >> memory.log
		ps -eo etime=,rss=,args= | grep '^ *[0-9:-]* *[0-9]* php maintenance/run MathSearch:UpdateMath' |
			awk -v t="$t" '{print t, $NF, "rss_mb=" int($2/1024), "etime=" $1}' >> memory.log
		sleep 300
	done
) &
sudo docker exec mediawiki-fpm bash -c "cd /var/www/html/w && xargs -P 4 -I{} sh -c 'maintenance/run MathSearch:UpdateMath --wiki {} > $D/{}.log 2>&1 || echo failed {}' < $D/failed-261004/list.txt"
date -u
wait
```

* The first start failed before it changed anything, as `updatemath/` belongs to root.
* `list.txt` was created in `failed-261004/` before `ls` listed that directory,
  so it is in the list as a wiki of its own; its run failed harmlessly.
* At 22:01 UTC 339 of the 381 wikis were done, none failed.
</details>

<details>
<summary>found two more causes of the memory growth and applied their fixes</summary>

The id generator fix alone did not stop the growth:
after 30 min frwikiversity had 755 MB, after 60 min 1,372 MB.
Diagnostic scripts, copied to math26 with `scp` and run in the container, found two causes.

* MathObject defers its writes to `mathlog` until the end of each chunk of 1,000 revisions.
  UpdateMath on frwikiversity, revisions 2000–2200 (69,000 formulae):

  | chunk size | peak memory | memory at the end | time |
  |---|---|---|---|
  | 1000 | 486 MB | 145 MB | 16.9 min |
  | 25 | 223 MB | 136 MB | 11.8 min |

  [fa1d7b0](https://archive.softwareheritage.org/swh:1:rev:fa1d7b075d1ba5e1ee52cfbf6e50063cf3a1d539;origin=https://github.com/wikimedia/mediawiki-extensions-MathSearch), the merged [patch set 2 of Gerrit change 1350612](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1350612/2), lowers the default chunk size to 100.
  [Its difference to patch set 1](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1350612/1..2) was applied in the container at 16:41 UTC.
* In maintenance scripts, WANObjectCache keeps two stats samples for every `getWithSetCallback()` and never flushes them,
  about 0.8 KB for every check of a formula, see [T440146](https://phabricator.wikimedia.org/T440146).
  With the core fix, the code of [patch set 1 of Gerrit change 1350817](https://gerrit.wikimedia.org/r/c/mediawiki/core/+/1350817/1), applied with `git apply` in the container at 17:58 UTC,
  the run with chunk size 25 needed 115 MB at its peak and 49 MB at the end, in 8.6 min.

Wikis started after these fixes stay small:
ruwiki, started at 19:03 UTC, grew from 169 to 193 MB between 19:30 and 21:45 UTC.
enwiki started before them and had 2.1 GB after 8.5 h.
</details>

<details>
<summary>scheduled a second import of all wikis</summary>

All 659 imports ended with `Done!` and without errors,
but importDump might skip single pages without aborting.
So all dumps are imported again after UpdateMath, which skips existing revisions.
The page and revision counts before and after show which wikis need UpdateMath again.

Started 22:09:19 UTC in the screen session `reimport`, it waits until no UpdateMath runs:

```bash
screen -dmS reimport bash -c "sudo bash /tmp/reimport.sh > /data/project/wdump/math/reimport.out 2>&1"
```

`/tmp/reimport.sh` was copied to math26 with `scp`:

```bash
#!/bin/bash
# Waits for UpdateMath to finish, imports all dumps again and lists the wikis that gained pages or revisions
M=/data/project/wdump/math
D=$M/reimport
mkdir -p $D/log
cd $D || exit 1

counts() {
	echo "SELECT CONCAT('SELECT ', QUOTE(table_schema), ', (SELECT COUNT(*) FROM \`', table_schema, '\`.page), (SELECT COUNT(*) FROM \`', table_schema, '\`.revision);') FROM information_schema.tables WHERE table_name = 'page';" |
		sudo docker exec -i db bash -c 'mariadb -uroot -p"$(cat /run/secrets/db_root_password)" -N | mariadb -uroot -p"$(cat /run/secrets/db_root_password)" -N' | sort
}

while pgrep -f 'run MathSearch:UpdateMath' > /dev/null; do
	sleep 300
done
echo "UpdateMath finished $(date -u)"

counts > counts-before.tsv
echo "$(wc -l < counts-before.tsv) wikis counted, import started $(date -u)"

ls $M/*.xml.bz | grep -vE '/(commonswiki|wikidatawiki|sourceswiki|test2wiki)\.' |
	sudo docker exec -i mediawiki-fpm bash -c "xargs -P 4 -I{} sh -c 'w=\$(basename {} .xml.bz); bzcat {} | /var/www/html/w/maintenance/run importDump --wiki \$w --no-updates > $D/log/\$w.log 2>&1 || echo failed \$w'"
echo "import finished $(date -u)"

counts > counts-after.tsv
diff counts-before.tsv counts-after.tsv > changed.txt
echo "$(grep -c '^>' changed.txt) wikis changed, $(grep -L '^Done!' log/*.log | wc -l) imports without Done!"
```
</details>

## 2026-10-03
<details>
<summary>imported all wikis (step 4)</summary>

With srv-wmflabs-math26 at [4cf9033](https://archive.softwareheritage.org/swh:1:rev:4cf90330e3885d0ce5f964b716ed77085858a81f;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26) (import with `--no-updates`, MathSearch on all wikis),
after recreating the containers:

```bash
sudo git -C /srv/srv-wmflabs-math26 pull
cd /srv/srv-wmflabs-math26 && sudo docker compose up -d
```

The fix for "Container disabled!" ([T439345](https://phabricator.wikimedia.org/T439345)) is merged in core,
but not yet in the image, so it was cherry-picked into the container:

```bash
sudo docker exec mediawiki-fpm sh -c 'cd /var/www/html/w && git fetch --depth=2 origin be32a607334bbed7a854e6af3a11953571d1fecc && git cherry-pick -n FETCH_HEAD'
```

Started 10:27:34 UTC in the screen session `import`:

```bash
sudo docker exec mediawiki-fpm bash -c 'cd /var/www/html/scripts && ./createAllWikis.sh'
```

* A first try with `--depth=1` lacked the parent commit, so the cherry-pick conflicted everywhere; it was undone with `git reset --merge`.
* Four imports ran at a time; all wikis were done at about 11:15 UTC.
* 659 of 663 wikis were imported.
  sourceswiki and test2wiki stopped at the content model `proofread-page`, as ProofreadPage is only loaded for databases ending in wikisource.
  commonswiki and wikidatawiki stopped at Wikibase content models, see [T440096](https://phabricator.wikimedia.org/T440096).
* The core fix is [be32a60](https://archive.softwareheritage.org/swh:1:rev:be32a607334bbed7a854e6af3a11953571d1fecc;origin=https://github.com/wikimedia/mediawiki).
</details>

<details>
<summary>tested the formula ids and started UpdateMath on all wikis (step 5)</summary>

MathSearch [55886b8](https://archive.softwareheritage.org/swh:1:rev:55886b87eea3b53b80c405070cbc54f61767ef54;origin=https://github.com/wikimedia/mediawiki-extensions-MathSearch), [patch set 3 of Gerrit change 1349809](https://gerrit.wikimedia.org/r/c/mediawiki/extensions/MathSearch/+/1349809/3), before it was merged,
copied into the container as a patch with `scp` and applied with `git apply -3`.
The last version applied is the one uploaded as the patch set after this run.
The change gives every formula its id from the revision and its position in the source, also during UpdateMath.
php-fpm keeps old code in its opcache (`opcache.validate_timestamps=0`), so it was reloaded after each patch:

```bash
sudo docker kill --signal=USR2 mediawiki-fpm
```

For maintenance scripts InstantCommons is off, written into `LocalSettings.php` in place, as the file is mounted on its own,
and committed as [4303ccf](https://archive.softwareheritage.org/swh:1:rev:4303ccfba0e023cd13fb468426bbe75fa923be28;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26).

* UpdateMath on afwiki: 7830 formulae in 56 s, 1 failed; on cawiki 167022 formulae in about one hour, 42 failed.
  Failed formulae are in `mathlog` with `math_statuscode` 1 (TeX error) or 2 (rendering error).
* A check of every page of afwiki and cawiki found no formula id that points to another formula:

  | | afwiki | cawiki |
  |---|---|---|
  | pages with math | 903 | 9,324 |
  | math, chem and ce tags in the source | 7,828 | 167,019 |
  | formulae on the pages | 7,792 | 159,400 |
  | id points to the right formula | 7,772 | 159,072 |
  | id points to another formula | 0 | 0 |
  | formulae without id, from templates | 20 | 327 |
  | tags that the page does not show | 56 | 8,100 |

* Templates: the filtered dumps contain only templates that have math themselves.
  afwiki has 7 templates and 1 module next to 898 articles.
  Formulae without id come from such templates, for example `Sjabloon:SI basiseenhede` on SI-stelsel and `Sjabloon:Ioonkas` on Fosfaat.
* Formulae in parameters of missing templates are not shown, about 5% on cawiki (8,100 of 167,000),
  for example in `{{Caixa desplegable}}` on Acceleració.
  So are formulae in reference groups whose list is a missing template, such as `{{reflist|group=Nota}}` or `{{Verwysings|group=note}}` on afwiki.
  At first UpdateMath left these formulae out of `mathlog`, so they would have been missing from the dataset of all formulae.
  On afwiki, `mathlog` grew from 5,837 to 5,908 distinct formulae after the fix, so the 71 formulae the pages do not show are stored.

Started 21:07:03 UTC in the screen session `updatemath`, four wikis at a time, with one log per wiki:

```bash
sudo docker exec mediawiki-fpm bash -c 'cd /var/www/html/w && ls /data/project/wdump/math/*.xml.bz | xargs -n1 basename | sed s/.xml.bz// | xargs -P 4 -I{} sh -c "maintenance/run MathSearch:UpdateMath --wiki {} > /data/project/wdump/math/updatemath/{}.log 2>&1"'
```
</details>

## 2026-10-02
<details>
<summary>published the pages with math tags on Zenodo (step 3)</summary>

`math.tar` was packed on math26 on 2026-10-01 at 16:51 UTC (663 files under `math/`):

```bash
tar -cf /data/project/wdump/math.tar -C /data/project/wdump math
```

Uploaded with [zenodoUpload.sh](zenodoUpload.sh), copied to math26 with `scp` before it was pushed:

```bash
cd ~/wikiFilter/wmcloud
read -s ZENODO_TOKEN && export ZENODO_TOKEN
./zenodoUpload.sh 15058128 zenodo/15058128/metadata.json zenodo/15058128/description.html /data/project/wdump/math.tar inputHashes.csv
```

* The first runs failed with a 500: the draft came in the legacy format, and the update was sent in the new one.
  The failed drafts were discarded.
* The upload of 1.7 GB took 8 minutes; the MD5 sums on Zenodo match the files on math26.
* The version field `2026-09-01` was cleared on Zenodo, so it shows as v4.
* Published as [10.5281/zenodo.23098003](https://doi.org/10.5281/zenodo.23098003).
</details>

<details>
<summary>started the import of all wikis (step 4)</summary>

Started 08:09:24 UTC in the screen session `import`:

```bash
sudo docker exec mediawiki-fpm bash -c 'cd /var/www/html/scripts && ./createAllWikis.sh'
```

* The container was started before step 3 renamed `/data/project/wdump/math` to `math25-12`,
  so it still saw the old directory and imported the 656 dumps of December 2025.
  The logs are in `/data/project/wdump/math25-12/log`.
* `createAllWikis.sh` waited for one import every four wikis instead of keeping four running,
  so 474 wikis failed with "Too many connections" (151 allowed).
* 12 Wikisources stopped at the first page with the content model `proofread-page`,
  and Commons at `wikibase-mediainfo`.
* Finished 16:40:50 UTC; 124 wikis were imported completely, at about 0.45 pages per second each.
</details>

<details>
<summary>re-imported the failed wikis, then stopped (step 4)</summary>

With srv-wmflabs-math26 at [d9ecfde](https://archive.softwareheritage.org/swh:1:rev:d9ecfde1f8b075e9f6c26b15c98387e591cc715c;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26) (four imports at a time, ProofreadPage on the Wikisources):

```bash
sudo git -C /srv/srv-wmflabs-math26 pull
cd /srv/srv-wmflabs-math26 && sudo docker compose restart mediawiki-fpm
sudo docker exec mediawiki-fpm bash -c 'cd /var/www/html/scripts && ./createAllWikis.sh'
```

* The restart made the container see the new `/data/project/wdump/math` with the dumps of 2026-09-01.
* Four imports ran at a time, as intended.
* Stopped at 23:07:17 UTC, because the wikis of the first run would mix the dumps of December 2025 and September 2026.
  `log-2026-10-02` holds copies of the first 12 logs of this run.
</details>

<details>
<summary>measured the import speed</summary>

On dewiki, two minutes each:

```bash
cd /data/project/wdump/math
timeout 120 /var/www/html/w/maintenance/run importDump --wiki dewiki --report 100 < <(bzcat dewiki.xml.bz)
timeout 120 /var/www/html/w/maintenance/run importDump --wiki dewiki --report 100 --no-updates --skip-to 5000 < <(bzcat dewiki.xml.bz)
```

* With updates, every page is parsed and its formulae rendered: about 1 page per second.
* With `--no-updates`: about 38 pages per second.
  The new dumps have about 260,000 pages, so the import should take about two hours.
</details>

<details>
<summary>removed the containers and the volumes</summary>

At 23:44:02 UTC, to import all wikis again from the dumps of 2026-09-01 only:

```bash
cd /srv/srv-wmflabs-math26 && sudo docker compose down --volumes
```

* Removed the volumes `beta_mw-database`, `beta_mw-images` and `beta_mw-cache`.
* The next import uses srv-wmflabs-math26 at [4cf9033](https://archive.softwareheritage.org/swh:1:rev:4cf90330e3885d0ce5f964b716ed77085858a81f;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26): `importDump --no-updates` and MathSearch on all wikis.
</details>

* posted the status on [T439313](https://phabricator.wikimedia.org/T439313)

## 2026-10-01
* prepared the Zenodo upload of step 3 with [zenodoUpload.sh](zenodoUpload.sh), [description](zenodo/15058128/description.html) and [MaRDI funding](zenodo/15058128/metadata.json)

## 2026-09-27
* [deployed](https://archive.softwareheritage.org/swh:1:rev:977675d233be8a2d467b183a50b6feb5803338c9;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26) math26 with a single script in 16 minutes
* [generated](https://archive.softwareheritage.org/swh:1:rev:d42c18c0f6ad2370cfbd74d56ff61ce22f8230b2;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26) all passwords on math26 and pinned the images to major versions, kept current by Watchtower
* [added](https://archive.softwareheritage.org/swh:1:rev:450a4251528aedde00c28fd459196a023eecd98e;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26) a [second route](https://math-traefik-dashboard.wmcloud.org/dashboard/) to the Traefik dashboard that does not rely on Traefik's Let's Encrypt certificates

<details>
<summary>updated the dump links on math26 (step 1)</summary>

With [wikiFilter](https://archive.softwareheritage.org/swh:1:rev:a3e0c59e4df92d8334796ae4f2de43c6ee8c50bc;origin=https://github.com/MaRDI4NFDI/wikiFilter)
on [math26](https://archive.softwareheritage.org/swh:1:rev:450a4251528aedde00c28fd459196a023eecd98e;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26),
08:21:46–08:22:00 UTC:

```bash
cd ~/wikiFilter/wmcloud
bash updateLinks.sh
```

* `/data/project/wdump/links/latest` now has 1041 links; 10 are new:
  abstractwiki, bolwiki, isvwiki, kaiwiki, kajwiki, magwiki, minwikiquote, pplwiki, tokwiki, urwikisource.
* The other 1031 already existed; `ln -s` failed with "File exists", but they still point to the current dump.
* The script prints "Created symlink" even when `ln` fails.
* Skipped: 52 folders without `latest`, and 11 wikis without a dump file:
  10wikipedia, bawiktionary, chwikimedia, en_flaggedrevs_labswikimedia, ilwiktionary, strategyappwiki,
  tokiponawiki, tokiponawikibooks, tokiponawikiquote, tokiponawiktionary, viwikimedia.

</details>

<details>
<summary>recorded the dump hashes on math26 (step 2)</summary>

With [getInputHash.sh](getInputHash.sh),
started 11:38:41 UTC in the screen session `hashes`:

```bash
git clone https://github.com/MaRDI4NFDI/wikiFilter.git ~/wikiFilter
cd ~/wikiFilter/wmcloud
bash getInputHash.sh > inputHashes.csv
```
Finished 12:40:36 UTC (62 minutes): [inputHashes.csv](inputHashes.csv) lists 1041 dumps of 2026-09-01 with 432 GiB in total.
Copied into this repository from a local clone:

```bash
cd wikiFilter/wmcloud
scp math26:wikiFilter/wmcloud/inputHashes.csv inputHashes.csv
```
</details>

<details>
<summary>filtered the dumps for math on math26 (step 3)</summary>

With [filterMath.sh](filterMath.sh), the output of the December 2025 run moved aside,
started 14:17:04 UTC in the screen session `filter`:

```bash
mv /data/project/wdump/math /data/project/wdump/math25-12
mkdir /data/project/wdump/math
cd ~/wikiFilter/wmcloud
bash filterMath.sh 2> filter.log
```

It finished on 2026-09-29 at 17:13:40 UTC with 663 files (1.6 GiB) and no errors in [filter.log](filter.log),
copied from math26 with

```bash
scp math26:wikiFilter/wmcloud/filter.log filter.log
```
</details>

<details>
<summary>sample run of step 4 with afwiki, azwiki and bgwiki</summary>

On math26, while step 3 was still running, with three wikis
and [createWiki](https://archive.softwareheritage.org/swh:1:cnt:e6438c800d3d7c95dbbb0cca28fed08645d1421b;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26;anchor=swh:1:rev:79bae659e53839ae8077cceed6566517577f62ce;path=/container-scripts/mw/createWiki) after pulling srv-wmflabs-math26 to 79bae65:

```bash
sudo git -C /srv/srv-wmflabs-math26 pull
sudo docker exec mediawiki-fpm bash -c 'cd /var/www/html/scripts && for w in afwiki azwiki bgwiki; do ./createWiki /data/project/wdump/math/$w.xml.bz; done'
```

* The checkout on math26 was still at the deployed commit, so the first attempt ran an old `createWiki` that stopped before the import.
* `LocalSettings.php` did not select the wiki for maintenance scripts, and the imports stopped at the first module page.
  Fixed in [LocalSettings.php](https://archive.softwareheritage.org/swh:1:cnt:7917fcd87c026bd088976df447f90ba42853aefd;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26;anchor=swh:1:rev:cfca0fcf8956a4dfd54bdfbf415f50fd564dffe3;path=/LocalSettings.php) of cfca0fc and copied to math26 for testing.
* `installPreConfigured` failed with "Container disabled!" on a single database server.
  A fix for MediaWiki core is under review ([T439345](https://phabricator.wikimedia.org/T439345), [Gerrit change 1345374](https://gerrit.wikimedia.org/r/1345374))
  and was patched into the container for testing.
* Imported 906, 1021 and 1821 pages at about 1 page per second.
  These were the dumps of December 2025: the container still saw the renamed directory (see 2026-10-02).
* `createWiki` can be run again on an existing wiki; it skips what is already there.
</details>

## 2026-09-26
* published [refresh plan](https://phabricator.wikimedia.org/T439313)

<details>
<summary><a href="https://archive.softwareheritage.org/swh:1:cnt:7080357046651731d4f8d676771b6666ff1547f6;origin=https://github.com/MaRDI4NFDI/srv-wmflabs-math26;anchor=swh:1:rev:7e13f65106c29e26f67ab905124dbbf82e179e18;path=/math24.md">reviewed</a> math24</summary>

* all filtered dumps are on the project NFS share and stay
* only the wiki databases (60 GB) are lost, they are rebuilt from the dumps
* the volume quota is used up (310 GB), so math26 is built after math24 is gone
* the dumps mount needs hiera `mount_nfs: true` on math26
</details>

<details>
<summary>set up openstack cli and deleted math24 instance</summary>

1. In Horizon, select the project `math`, then create an application credential under
   Identity → Application Credentials and download its `clouds.yaml`.
2. Install the client and store the credential:
```bash
brew install openstackclient
mkdir -p ~/.config/openstack
mv ~/Downloads/clouds.yaml ~/.config/openstack/clouds.yaml
chmod 600 ~/.config/openstack/clouds.yaml
```
3. Rename the entry `openstack:` to `math:` in `clouds.yaml` and check it:
```bash
openstack --os-cloud math server list
```
   To make `math` the default, add `export OS_CLOUD=math` to `~/.zshrc`.
4. Stop the containers and delete the instance:
```bash
ssh math24 'cd ~/srv-math24 && sudo docker-compose down'
openstack --os-cloud math server delete --wait math24
```
The floating IP stays allocated for math26.
The volume `math24` (90 GB) is kept detached for now.
</details>

## 2025-12-11
<details>
<summary>copy files and create tar file</summary>
  
```bash
scp -r math24:/data/project/wdump/math .
tar -cf math.tar math/*
cd math
ls | wc -l
```
output 656 files
</details>

## 2025-12-05
<details>

<summary>Run updateLinks </summary>

run https://github.com/MaRDI4NFDI/wikiFilter/blob/master/wmcloud/updateLinks.sh for 1093 files with the following problems



```
No 'latest' folder found in /public/dumps/public/archive/
No symbolic link found for bawiktionary-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/bawiktionary//latest
No symbolic link found for chwikimedia-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/chwikimedia//latest
No 'latest' folder found in /public/dumps/public/closed_zh_twwiki/
No 'latest' folder found in /public/dumps/public/dkwiki/
No 'latest' folder found in /public/dumps/public/dkwikibooks/
No 'latest' folder found in /public/dumps/public/dkwiktionary/
No symbolic link found for en_flaggedrevs_labswikimedia-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/en_flaggedrevs_labswikimedia//latest
No 'latest' folder found in /public/dumps/public/ilwikimedia/
No symbolic link found for ilwiktionary-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/ilwiktionary//latest
No 'latest' folder found in /public/dumps/public/lbewiktionary/
No 'latest' folder found in /public/dumps/public/lgwiktionary/
No 'latest' folder found in /public/dumps/public/lijwiktionary/
No 'latest' folder found in /public/dumps/public/map_bmswiktionary/
No 'latest' folder found in /public/dumps/public/muswiktionary/
No 'latest' folder found in /public/dumps/public/mznwiktionary/
No 'latest' folder found in /public/dumps/public/napwiktionary/
No 'latest' folder found in /public/dumps/public/nds_nlwiktionary/
No 'latest' folder found in /public/dumps/public/newwiktionary/
No 'latest' folder found in /public/dumps/public/ngwiktionary/
No 'latest' folder found in /public/dumps/public/novwiktionary/
No 'latest' folder found in /public/dumps/public/nrmwiktionary/
No 'latest' folder found in /public/dumps/public/nvwiktionary/
No 'latest' folder found in /public/dumps/public/nywiktionary/
No 'latest' folder found in /public/dumps/public/oswiktionary/
No 'latest' folder found in /public/dumps/public/other/
No 'latest' folder found in /public/dumps/public/pagwiktionary/
No 'latest' folder found in /public/dumps/public/pamwiktionary/
No 'latest' folder found in /public/dumps/public/papwiktionary/
No 'latest' folder found in /public/dumps/public/pdcwiktionary/
No 'latest' folder found in /public/dumps/public/pihwiktionary/
No 'latest' folder found in /public/dumps/public/pmswiktionary/
No 'latest' folder found in /public/dumps/public/rmywiktionary/
No 'latest' folder found in /public/dumps/public/roa_tarawiktionary/
No 'latest' folder found in /public/dumps/public/ru_sibwiki/
No 'latest' folder found in /public/dumps/public/ru_sibwiktionary/
No 'latest' folder found in /public/dumps/public/scowiktionary/
No 'latest' folder found in /public/dumps/public/sep11wiki/
No 'latest' folder found in /public/dumps/public/sewiktionary/
No symbolic link found for strategyappwiki-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/strategyappwiki//latest
No 'latest' folder found in /public/dumps/public/testwiki¬/
No 'latest' folder found in /public/dumps/public/tetwiktionary/
No 'latest' folder found in /public/dumps/public/tlhwiki/
No 'latest' folder found in /public/dumps/public/tlhwiktionary/
No symbolic link found for tokiponawiki-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/tokiponawiki//latest
No symbolic link found for tokiponawikibooks-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/tokiponawikibooks//latest
No symbolic link found for tokiponawikiquote-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/tokiponawikiquote//latest
No symbolic link found for tokiponawiktionary-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/tokiponawiktionary//latest
No 'latest' folder found in /public/dumps/public/tumwiktionary/
No 'latest' folder found in /public/dumps/public/tywiktionary/
No 'latest' folder found in /public/dumps/public/udmwiktionary/
No 'latest' folder found in /public/dumps/public/vewiktionary/
No symbolic link found for viwikimedia-latest-pages-articles-multistream.xml.bz2 in /public/dumps/public/viwikimedia//latest
No 'latest' folder found in /public/dumps/public/vlswiktionary/
No 'latest' folder found in /public/dumps/public/warwiktionary/
No 'latest' folder found in /public/dumps/public/wuuwiktionary/
No 'latest' folder found in /public/dumps/public/xalwiktionary/
No 'latest' folder found in /public/dumps/public/zeawiktionary/
No 'latest' folder found in /public/dumps/public/zh_classicalwiktionary/
No 'latest' folder found in /public/dumps/public/zh_min-nanwiki/
No 'latest' folder found in /public/dumps/public/zh_min-nanwiktionary/
No 'latest' folder found in /public/dumps/public/zh_yuewiktionary/
```

</details>

<details>

<summary>update hashes</summary>

```
physikerwelt@math24:~/wikiFilter/wmcloud$ ./getInputHash.sh > inputHashes.csv 
```
</details>
<details>

<summary>generate new dump</summary>

```bash
screen 
physikerwelt@math24:~/wikiFilter$ mv /data/project/wdump/math /data/project/wdump/math25-03
physikerwelt@math24:~/wikiFilter$ mkdir /data/project/wdump/math
physikerwelt@math24:~/wikiFilter$ cd wmcloud/
physikerwelt@math24:~/wikiFilter/wmcloud$ ./filterMath.sh 
```
</details>

## 2025-04-06
* Create DB backup
```bash
screen
docker exec -it mardi-backup  bash
cd ${BACKUP_DIR}
mkdir wmf
cd wmf/
mysqldump -u"${DB_USER}" -p"${DB_PASS}" -h"${DB_HOST}" --single-transaction --quick --databases cywiki brwiki hiwikiquote udmwiki eswikiquote zh_classicalwiki tswiki bdrwiki mnwwiki mswikibooks ruwikiversity kiwiki hiwiktionary brwikisource csbwiki cswikisource pawikisource itwikivoyage elwiki plwikisource elwiktionary kshwiki srwikiquote papwiki map_bmswiki uawikimedia jawikiversity hewikibooks eswiktionary azwiki plwiktionary simplewiktionary ukwikiquote arwikiquote fywiki ruwikiquote bawikibooks arwiktionary roa_tarawiki arwikisource klwiki fawiktionary scowiki mlwiktionary nlwikisource iswiktionary elwikisource zeawiki tumwiki lgwiki dewiki chwiki shnwikinews ndswiki ganwiki dtpwiki be_x_oldwiki enwiktionary mswikisource tawikisource dinwiki frwikisource mnwiktionary lijwikisource viwikibooks afwikibooks myvwiki enwikiquote readerfeedback_labswikimedia ukwikisource rowikinews azwikimedia enwikibooks simplewiki shiwiki strategywiki slwikiquote avwiki amwiki sgwiktionary ptwikinews hiwikisource ptwikisource mswiktionary dawiktionary tddwiki cswikiversity sawikisource frwikibooks ocwiktionary euwikibooks napwikisource usabilitywiki bnwiktionary tkwiki suwiki eswikisource vowiki dewikiquote incubatorwiki awawiki fawikivoyage guwiki huwikinews itwikinews bnwikisource sqwikibooks xmfwiki plwiki nrwiki dsbwiki skwiki lbewiki commonswiki frwikiquote thwikiquote newiki mnwwiktionary sawiki kowikiquote viwikivoyage mrwiktionary nowiktionary fiwiki ukwiki hywikibooks btmwiki slwikibooks krcwiki hewikiquote frpwiki itwikibooks gorwiki wowiki tpiwiki bat_smgwiki dgawiki guwikiquote blkwiki cawikibooks pswiki testwiki cvwiki outreachwiki afwiki plwikimedia en_labswikimedia vecwikisource pmswiki simplewikibooks cawikiquote knwiktionary hrwikibooks sdwiktionary svwikiversity huwikiquote ttwikibooks olowiki bgwikibooks kawiktionary htwiki hywikisource lawikisource pwnwiki rskwiki dewikisource tawiki shnwikibooks kbdwiki cswikibooks smwiki etwikibooks astwiki anwiki tlwiki itwikisource nahwiki bowiki labswiki huwikibooks tewiktionary azwikisource mlwikibooks fiwikibooks jawiktionary ukwikinews cdowiki cewiki dawikiquote warwiki zh_min_nanwikisource banwiki tcywiki rowikibooks srwiki aswikisource nlwiki nlwikivoyage newikibooks bgwiki fawikibooks kowiki mswiki eswikinews tewiki azbwiki kowiktionary kgwiki pntwiki ocwiki alswiki amiwiki bnwikivoyage ptwiktionary kmwikibooks mediawikiwiki itwikiversity fiwiktionary de_labswikimedia nvwiki zhwikivoyage lldwiki gnwiki yiwiki tyvwiki siwiki trwiki ibawiki kswiki kvwiki orwiki hewikisource idwikibooks inhwiki bawiki nrmwiki mowiki pamwiki mlwiki ruewiki ruwikinews mrwiki etwikisource itwikiquote kwwiki viwikisource test2wiki tawikiquote shnwiki kawikiquote brwiktionary siwiktionary lijwiki gawiki pcdwiki pawikibooks gomwiktionary barwiki kawikisource mywiki mrjwiki vepwiki napwiki enwikisource ruwikisource etwiktionary huwiki frwikivoyage fowiki pawiki flaggedrevs_labswikimedia hsbwiki thwikisource minwiki plwikiquote kowikinews ukwiktionary plwikinews bnwikibooks kuwikibooks bewiki nds_nlwiki nnwiki eswikivoyage tlwiktionary dewikinews miwiki kgewiki cywikisource iawiki furwiki hewiktionary fatwiki mgwiki elwikinews nywiki srwikibooks ruwikivoyage vlswiki stwiki svwiktionary hiwiki nowiki urwikibooks tlwikibooks dagwiki bswiktionary tlywiki fawikiquote suwikisource jawikisource eowikiquote arwikinews ltwiktionary trwikiquote bnwiki twwiki kkwiki ndswiktionary fiwikinews tcywikisource dvwiki kowikibooks sdwiki igwiki zhwikiversity bhwiki euwiki nowikiquote swwiki betawikiversity iewiktionary hrwiki angwiki enwiki lawikibooks frwiktionary brwikimedia frrwiki dzwiki pagwiki sqwiki zh_min_nanwikibooks oswiki glwiktionary bjnwiki bewwiki kkwiktionary tetwiki idwiki tgwikibooks zhwiktionary trwikinews ltgwiki stqwiki eswiki shnwikivoyage jbowiki quwiki pnbwiki bgwikiquote suwikiquote uzwiktionary dtywiki tlwikiquote frwikinews eswikibooks lfnwiki dawikibooks rowiki mkwikisource jawikinews fawikisource ptwikiquote lbwiki urwiki viwikiquote srwikinews eswikiversity lrcwiki ugwiki ruwiki extwiki jawikivoyage nlwikibooks cebwiki simplewikiquote trwikivoyage jawikibooks zh_yuewiki tawikinews zghwiki euwikisource hywiktionary zhwikisource lowiki iowiki rmwiki siwikibooks aswikiquote roa_rupwiki nowikibooks sewiki cawikisource ocwikibooks bugwiki wawiktionary enwikivoyage zh_min_nanwiki brwikiquote kuwiki shwiki jawikiquote glkwiki ptwiki ilowiki ffwiki lnwiki idwikisource wuuwiki mkwikibooks abwiki cawiki hywwiki sqwiktionary kncwiki huwiktionary rwwiki aswiki gotwiki kaawiktionary afwiktionary gdwiktionary cswiktionary srwikisource mniwiki hiwikibooks bpywiki ruwiktionary arzwiki srwiktionary adywiki angwikibooks elwikiversity nsowiki azwikibooks ukwikibooks ladwiki rowikisource lmowiktionary zhwiki kaawiki snwiki dewikibooks plwikibooks tawikibooks zawiki hiwikivoyage arwikibooks ltwikibooks fawikinews mlwikisource ptwikibooks tnwiki arwiki thwikibooks ukwikivoyage gdwiki vecwiki trwiktionary cywiktionary ukwikimedia nlwiktionary frwiki mkwiktionary eowikisource thwiktionary novwiki slwikiversity arwikiversity glwikiquote kmwiktionary uzwikiquote gpewiki thwiki kuwiktionary mhrwiki scwiki huwikisource tewikibooks eowiki mrwikisource hifwiki eowikivoyage iswiki ttwiki kawiki fjwiki sowiki idwiktionary svwiki liwiki trwikisource yowiki fawiki svwikibooks sswiki ptwikivoyage etwiki hewikivoyage itwiktionary viwiki glwiki kawikibooks crhwiki glwikisource hrwikisource hewiki omwiki vecwiktionary mnwiki ruwikibooks cawiktionary ckbwiki tgwiki pflwiki fiu_vrowiki tewikisource bewikibooks hawwiki xalwiki mkwiki wikidatawiki arywiki viwiktionary gomwiki sylwiki hiwikiversity frwikiversity satwiki mtwiki knwiki azwiktionary skrwiki yuewiktionary wikimania2007wiki idwikivoyage trwikibooks eowikibooks pcmwiki pdcwiki elwikibooks ruwikimedia maiwiki cswiki iswikibooks cswikinews hywiki bjnwikiquote bewikisource dewikivoyage cuwiki kabwiki emlwiki glwikibooks svwikisource kowikiversity uzwiki rmywiki scnwiki szlwiki enwikinews jvwikisource tawiktionary cowiki eowiktionary gewikimedia ltwiki hakwiki azwikiquote mznwiki xhwiki skwikibooks slwikisource jvwiki kywiki tywiki cbk_zamwiki jamwiki smnwiki slwiki enwikiversity anpwiki dewikiversity hifwiktionary skrwiktionary newwiki dawiki specieswiki wawiki kmwiki nowikisource elwikiquote zuwiki metawiki mgwiktionary diqwiki sourceswiki bgwikisource lezwiki cswikivoyage bclwiki rowiktionary niawiki bgwiktionary lvwiki liquidthreads_labswikimedia lawiki mwlwiki madwiki dewiktionary ptwikiversity aewikimedia itwiki fiwikisource zhwikibooks idwikimedia jawiki iewiki zhwikinews bxrwiki hewikinews kcgwiki dawikisource hawiki avkwiki gvwiki gagwiki piwiki zhwikiquote cywikiquote knwikisource altwiki sahwiki aywiki bswiki lmowiki lvwikibooks bmwiki kowikisource guwikisource | gzip > wmf.gz
exit
exit
```
Backup took 22 minutes
backup size 7.4GB
5a3493d15c466ede14ac8d2e7f5b1622  wmf.gz

* Published [https://zenodo.org/records/15162182](https://doi.org/10.5281/zenodo.15162181)

## 2025-03-21

* Moved old symlinks to /data/project/wdump/links/2019
* Moved old math filter result to /data/project/wdump/math19 (a copy of that in on [zenodo](https://doi.org/10.5281/zenodo.15058128))
* Updated new links with the [script](https://github.com/MaRDI4NFDI/wikiFilter/blob/master/wmcloud/updateLinks.sh)

## 2025-03-30

* published [dataset](https://zenodo.org/records/15107679) with script results
