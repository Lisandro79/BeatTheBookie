## Beating the bookies with their own numbers. 

This repository contains the code to reproduce our betting strategy for football games, as described in the paper [*"Beating the bookies with their own numbers - and how the online sports betting market is rigged"*](https://arxiv.org/abs/1710.02824), by Lisandro Kaunitz (1,2), Shenjun Zhong (3) and Javier Kreiner (4). 

1. Research Center for Advanced Science and Technology, The University of Tokyo, Tokyo, Japan.

2. Progress Technologies Inc., Tokyo, Japan.

3. Monash Biomedical Imaging Center, Monash University, Melbourne, Australia.

4. Data Science department, CargoX, Sao Paulo, Brazil.


Citation:

```
@inproceedings{BeatTheBookies,
    Author = {Lisandro Kaunitz and Shenjun Zhong and Javier Kreiner},
    Title = {Beating the bookies with their own numbers - and how the online sports betting market is rigged},
    Journal = {arXiv:1710.02824v1},
    Year = {2017}
}
```

## Disclaimer

This repository contains a dataset, code and the link to an online dashboard that shows online suggestions from our betting strategy. If you are a sports betting aficionado and decide to test our suggestions with paper trading or real betting, please bear in mind that you are doing it under your own risk and responsibility. We do not claim any responsiblity for: A) the use that you might make of our code, B) the information contained in our online dashboard or C) any monetary losses you might incur during your betting experience.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Online Dashboard

Our strategy was based on finding mispriced odds online. We provide the dashboard we used with the suggestions of our strategy. You can find a general non-mathematical short explanation of the strategy ([here](http://wp.me/p7wVWn-9Z))

The dashboard shows the games and odds that our strategy suggests as mispriced. We would definitely bet on these games if the bookies did not block our accounts. Other than that, we truly believe that the effort of deploying such a strategy is completely worthless, considering the time spent on the betting and the monetary reward.


This is how the dashboard looks like. It displays the upcoming games, odds, bookmaker and the remaining time to the onset of the game.


![Alt text](/figures/dashboard.png?raw=true "Dashboard with list of games")

You can follow the upcoming games online at:

```
http://42.2.153.218:9090//
```

## How to run the code

We provide matlab/octave code to reproduce all the figures and analysis in the paper. 

1. Clone this repository

```
git clone https://github.com/Lisandro79/BeatTheBookie.git

```
2. Download the dataset either from

Google Drive ([link](https://drive.google.com/drive/folders/0B3zgn2ueCERNWnJRSnpIQTBDWEU?usp=sharing))

or

Dropbox

* [closing odds](https://www.dropbox.com/s/g9vpjjlxjeruc3u/closing_odds.zip?dl=0)

* [odds_series](https://www.dropbox.com/s/gqp3m6o5zsd8v63/odds_series.zip?dl=0)

* [odds_series_b](https://www.dropbox.com/s/t26rwzvlwtt6xnb/odds_series_b.zip?dl=0)

* [paper trading, real betting](https://www.dropbox.com/s/z4qi44s1dn4kuuv/paper_trading_real_betting_series.zip?dl=0)

* [closing odds sql db](https://www.dropbox.com/s/adj7xivk40vuvl7/closing_odds_sql_db.zip?dl=0)

* [odds series sql db](https://www.dropbox.com/s/sftxhxq03jd12j6/odds_series_sql_db.zip?dl=0)

* [odds series b_sql db](https://www.dropbox.com/s/x6aookfjw25ne6q/odds_series_b_sql_db.zip?dl=0)


Note: The sql database files are ~1.8GB of data. Due to space restrictions, the SQL databases are only available for download via Google Drive or Dropbox.


3. Install mysql and import the database dumps:

```
mysql -u root -p < [file with first dump]
```

4. Install Matlab or

5. Install Octave and the required Packages:

```
sudo apt-add-repository ppa:octave/stable
sudo apt-get update
sudo apt-get install octave
sudo apt-get install octave-control octave-image octave-io octave-optim octave-signal octave-statistics octave-nan
```

The scripts were tested with Matlab, but they should work fine in Octave too with little adjustment.

# Historical analysis of closing odds.

These analysis reproduce figures 1 and 2 from our paper. Place file "closing_odds.cvs" into "/data". Folder structure should look like this:

```
data/
figures/
sql/
src/
```
The first time the scripts are run, set "runStrategy" to 1, so that the script can generate the results of the strategy (after that "runStrategy" can be set to "0" to save some time). Then run:

```
cd src/
Figure1.m
Figure2A.m
```

The rest of the code is self explanatory. 


## Historical analysis of odds series.

This analysis corresponds to Figure 2B and Figure 3 from the paper. Unzip files "odds_series" and "paper_trading_real_betting_series" in /data/. The folder scrutcure should look like this:

```
/data/odds_series/
/data/odds_series_b/

```
These two folders should contain several thousand files (one for each game).

Then run these scripts:

```
cd src/
Figure2B.m
Figure3.m
```

## Dataset Description

For those interested in perfoming their own analysis with the dataset we provide two sql databases. Both are provided in the form of sql dumps exported from mysql databases:

(1) **"closing_odds.csv"** and **"closing_odds_sql_db"**. Historical closing odds and match information for 880,494 football matches from 2000-01-01 to 2015-09-06 for 912 leagues around the world.  The csv file is a matrix of games (rows) x features (teams, scores, league, etc). See the matlab scripts for a description of the features

(2) **"odds_series"** and **"odds_series_sql_db"**. Continuous odds series (series of odds with odds movements) and match information for 31,074 football matches from September 2015 until March 2016 for 553 leagues around the world. 

(3) **"odds_series_b"** and **"odds_series_b_sql_db"**. Continuous odds series (series of odds with odds movements) and match information for 82,786 football matches from March 2016 until November 2016 for 658 leagues around the world.

**Database structure:**

* Table "matches": contains information about the football matches

| Field for table "matches"  | Column Description | 
| ------------- | ------------- |
| ID  | auto increment id of table  |
| league  | the league of the match (e.g. Spanish League)  |
| team1   | local team  |
| team2   | away team  |
| result  | result of match   |
| result_det  | detailed result of match (goals in first half, goals in second half, etc)  |
| date |  datetime of the match |

* Table "odds_history": for each match-bookmaker-outcome combination there is an entry in this table

| Field for table "odds_history"  | Column Description | 
| ------------- | ------------- |
| odds_history_id | id in odds_history table |
| ID | id of match referring to matches table |
| bookmaker | name of the bookie |
| bettype | type of bet (e.g. 1x2) |
| result | outcome for which the odd is offered |
| disabled_date | date the odds on offer were disabled (could be null, i.e. they were still active until beginning of match), not available in historical odds database |

* Table "odds_history_series": for each entry in table odds_history this table contains the odds series, i.e. one entry each time the odds are updated

| Field for table "odds_history_series"  | Column Description | 
| ------------- | ------------- |
| odds_history_series_id  | auto increment id |
| odds_history_id | entry in odds_history table to which these odds are related |
| odds_datetime | time at which these odds were offered |
| odds | odds value |
| opening_closing | specifies if the entry corresponds to closing odds. Value of 1 means closing odds, any other value means not a closing odds |
| active | specifies if closing odds were active at closing time, only valid in historical odds database |

* Within  *"closing_odds_sql_db"* we also provide a table containing the odds statistics calculated per match:

| Field for table "odds_stats_per_match_1x2_closing" | Column Description | 
| ------------- | ------------- |
| id  | auto increment id |  
| match_table_id | id of matches table that corresponds to this row | 
| match_date | date of the match | 
| league | league of the match |  
| teamA | home team | 
| scoreA | score of home team |  
| teamB | away team | 
| scoreB | score of away team |  
| avg_win_1 | average odds offered for home win | 
| avg_tie | average odds offered for a tie |  
| avg_win_2 | average odds offered for away win | 
| max_win_1 | max odds offered for home win |  
| max_tie | max odds offered for a tie | 
| max_win_2 | max odds offered for away win |  
| top_bookie_win_1 | name of bookie offering the top odds for home win | 
| top_bookie_tie | name of bookie offering the top odds for a tie |  
| top_bookie_win_2 | name of bookie offering the top odds for away win | 
| median_win_1 | median odds offered for home win |  
| median_tie | median odds offered for a tie | 
| median_win_2 | median odds offered for away win |  
| n_win_1 | number of active closing odds for home win | 
| n_tie | number of active closing odds for a tie |  
| n_win_2 | number of active closing odds for away win | 
| result | result of the match |  
| t_win_1 | time difference in seconds between the time the max odds were offered and the beginning of the match for home win  | 
| t_tie | time difference in seconds between the time the max odds were offered and the beginning of the match for a tie |  
| t_win_2 | time difference in seconds between the time the max odds were offered and the beginning of the match for away win  | 

Example queries:

* obtain closing odds for match with id 170088 (Belgium: Jupiler League, RAA Louvieroise vs Club Rugge, 2004-02-11) and result home win:

```
use closing_odds;
select * from
matches m
inner join
odds_history oh
on m.ID = oh.ID
inner join
odds_history_series ohs
on oh.odds_history_id = ohs.odds_history_id
where
m.ID = 170088 and opening_closing = 1 and oh.result = 1;
```

* obtain odds series for match with id 879672, result home win and bookmaker 'youwin':

```
use odds_series;
select * from
matches m
inner join
odds_history oh
on m.ID = oh.ID
inner join
odds_history_series ohs
on oh.odds_history_id = ohs.odds_history_id
where
m.ID = 879672 and oh.result = 1 and bookmaker = 'youwin';
```


## Generate csv files from the sql databases

For those interested in working with the dataset we provide php and sql scripts to generate the csv files used in the paper.

To generate the historical closing odds csv file (closing_odds.csv) from the database: 

```
/src/generate_closing_odds_csv.php 
```

To generate the txt files with the odds time series:

```
/src/generate_odds_series_csv.php 
```

