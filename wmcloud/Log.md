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
./zenodoUpload.sh 15058128 zenodo/math.json zenodo/math.html /data/project/wdump/math.tar inputHashes.csv
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
* prepared the Zenodo upload of step 3 with [zenodoUpload.sh](zenodoUpload.sh), [description](zenodo/math.html) and [MaRDI funding](zenodo/math.json)

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
