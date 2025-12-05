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
