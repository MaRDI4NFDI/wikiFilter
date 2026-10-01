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

On math26, while step 3 was still running, with the finished filter output of three wikis
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
* Imported 906, 1021 and 1821 pages, all pages of the three dumps, at about 1 page per second.
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
