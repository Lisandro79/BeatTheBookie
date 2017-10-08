SELECT match_table_id,league,match_date,teamA,scoreA,teamB,scoreB,avg_win_1,avg_tie,avg_win_2,max_win_1,max_tie,max_win_2,
top_bookie_win_1,top_bookie_tie,top_bookie_win_2,n_win_1,n_tie,n_win_2
FROM odds_stats_per_match_1x2_closing
WHERE trim(scoreA) NOT IN ('CAN.','','PEN.','ET','POSTP.','INT.','WO.','AWA.','ABN.') AND 
trim(scoreB) NOT LIKE '%CAN%' AND trim(scoreB) NOT LIKE '%PEN%' AND trim(scoreB) NOT LIKE '%ET%' AND 
trim(scoreB) NOT LIKE '%POSTP%' AND trim(scoreB) NOT LIKE '%INT%' AND trim(scoreB) NOT LIKE '%WO%' AND 
trim(scoreB) NOT LIKE '%AWA%' AND trim(scoreB) NOT LIKE '%ABN%' AND trim(scoreB) <> ''  
AND 
match_date >= '2005-01-01' AND match_date < '2015-07-01' 
INTO OUTFILE 'closing_odds.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY ''
LINES TERMINATED BY '\n';
