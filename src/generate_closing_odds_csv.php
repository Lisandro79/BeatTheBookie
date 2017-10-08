<?php

ini_set('memory_limit', '1000M');

date_default_timezone_set('UTC');

// sql statement to create table where odds statistics will be stored
  // CREATE TABLE `odds_stats_per_match_1x2_closing` (
  // `id` bigint(20) NOT NULL AUTO_INCREMENT,
  // `match_table_id` bigint(20) DEFAULT NULL,
  // `match_date` date DEFAULT NULL,
  // `league` varchar(50) DEFAULT NULL,
  // `teamA` varchar(20) DEFAULT NULL,
  // `scoreA` varchar(10) DEFAULT NULL,
  // `teamB` varchar(20) DEFAULT NULL,
  // `scoreB` varchar(10) DEFAULT NULL,
  // `avg_win_1` decimal(10,4) DEFAULT NULL,
  // `avg_tie` decimal(10,4) DEFAULT NULL,
  // `avg_win_2` decimal(10,4) DEFAULT NULL,
  // `max_win_1` decimal(10,4) DEFAULT NULL,
  // `max_tie` decimal(10,4) DEFAULT NULL,
  // `max_win_2` decimal(10,4) DEFAULT NULL,
  // `top_bookie_win_1` varchar(50) DEFAULT NULL,
  // `top_bookie_tie` varchar(50) DEFAULT NULL,
  // `top_bookie_win_2` varchar(50) DEFAULT NULL,
  // `median_win_1` decimal(10,4) DEFAULT NULL,
  // `median_tie` decimal(10,4) DEFAULT NULL,
  // `median_win_2` decimal(10,4) DEFAULT NULL,
  // `n_win_1` int(11) DEFAULT NULL,
  // `n_tie` int(11) DEFAULT NULL,
  // `n_win_2` int(11) DEFAULT NULL,
  // `result` varchar(2) DEFAULT NULL,
  // `t_win_1` int(11) DEFAULT NULL,
  // `t_tie` int(11) DEFAULT NULL,
  // `t_win_2` int(11) DEFAULT NULL,
  // PRIMARY KEY (`id`),
  // KEY `id_odds_stats_per_match_1x2_closing_id` (`match_table_id`),
  // KEY `id_odds_stats_per_match_1x2_closing_match_date` (`match_date`)
  // ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

// custom sort function to sort odds
function custom_sort($a,$b) {
	if (is_null($a->odds) && !is_null($b->odds)) return 1;
	if (is_null($b->odds) && !is_null($a->odds)) return 0;
	return $a->odds > $b->odds;
}

// mysql db connection configuration
$db = new PDO("mysql:host=localhost;dbname=closing_odds;charset=utf8", 'root', 'toor');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// select last processed match
$query_max = "SELECT MAX(match_table_id) as max_id FROM odds_stats_per_match_1x2_closing;";
$results = $db->query($query_max);
$max = $results->fetch(PDO::FETCH_OBJ);
if ($max->max_id) {
	$add_max = "AND id > ".$max->max_id." ";
}
else {
	$add_max = "";
} 

// select matches we haven't yet processed
$query = "SELECT *
FROM 
matches m
WHERE result not like '%CAN%' AND result not like '%WO%'
AND result not like '%AWA%' AND result not like '%ABN%' AND result not like '%INT%' 
AND result not like '%POSTP%' AND result <> '' AND NOT (result_det = '&nbsp;' and (result like '%ET%' or result like '%PEN%'))
$add_max
ORDER BY m.id ASC;";

print($query);

// iterate through them
$results = $db->query($query);
$count = 0;
while ($row = $results->fetch(PDO::FETCH_OBJ)) {
	$count++;
	if ($count % 100 == 0){
		print($count."|");
	}
	// for each match select the closing odds (opening_closing = 1) that were still active (active = 1) at closing time
	$query_odds = "SELECT *
					FROM
					odds_history oh
					INNER JOIN
					odds_history_series ohs
					ON oh.odds_history_id = ohs.odds_history_id
					WHERE oh.ID = '".$row->ID."' AND (ohs.opening_closing = 1) AND ohs.active = 1 AND ohs.odds <> '';";
	$results_odds = $db->query($query_odds);
	
	$win_1_odds = array();
	$tie_odds = array();
	$win_2_odds = array();
	
	$win_1 = array('max' => 0, 'top_bookie' => '', 'mean' => 0);
	$win_2 = array('max' => 0, 'top_bookie' => '', 'mean' => 0); 
	$tie = array('max' => 0, 'top_bookie' => '', 'mean' => 0); 
	
	while ($row_odds = $results_odds->fetch(PDO::FETCH_OBJ)) {
	// in this loop we find the average and maximum odds for each possible outcome for this match
		switch($row_odds->result) {
			case '1':
					$win_1_odds[] = $row_odds;
					if ($win_1['max']<$row_odds->odds && $row_odds->active == 1) {
						$win_1['max'] = $row_odds->odds;
						$win_1['top_bookie'] = $row_odds->bookmaker;
						$win_1['top_date'] = $row_odds->odds_datetime;
					}
					$win_1['mean'] += $row_odds->odds;
				break;
			case '2':
					$win_2_odds[] = $row_odds;
					if ($win_2['max']<$row_odds->odds && $row_odds->active == 1) {
						$win_2['max'] = $row_odds->odds;
						$win_2['top_bookie'] = $row_odds->bookmaker;
						$win_2['top_date'] = $row_odds->odds_datetime;
					}
					$win_2['mean'] += $row_odds->odds;
				break;
			case 'X':
					$tie_odds[] = $row_odds;
					if ($tie['max']<$row_odds->odds && $row_odds->active == 1) {
						$tie['max'] = $row_odds->odds;
						$tie['top_bookie'] = $row_odds->bookmaker;
						$tie['top_date'] = $row_odds->odds_datetime;
					}
					$tie['mean'] += $row_odds->odds;
				break;
		}
	}
	 
	// and we calculate the median of the odds for each outcome as well
	if (sizeof($win_1_odds)>0) {
		usort($win_1_odds,"custom_sort");
		$win_1['mean'] /= sizeof($win_1_odds);
		if (sizeof($win_1_odds) % 2 == 1) {
			$win_1['median'] = $win_1_odds[floor(sizeof($win_1_odds)/2)]->odds;
		}
		else {
			$win_1['median'] = ($win_1_odds[sizeof($win_1_odds)/2-1]->odds + $win_1_odds[sizeof($win_1_odds)/2]->odds)/2;
		}
		$diff_win_1 = strtotime($row->date) - strtotime($win_1['top_date']);
	}
    else {
        $win_1['mean'] = 0;
        $win_1['median'] = 0;
        $diff_win_1 = 0;
    }
	
	if (sizeof($win_2_odds)>0) {
		usort($win_2_odds,"custom_sort");
		$win_2['mean'] /= sizeof($win_2_odds);
		if (sizeof($win_2_odds) % 2 == 1) {
			$win_2['median'] = $win_2_odds[floor(sizeof($win_2_odds)/2)]->odds;
		}
		else {
			$win_2['median'] = ($win_2_odds[sizeof($win_2_odds)/2-1]->odds + $win_2_odds[sizeof($win_2_odds)/2]->odds)/2;
		}
		$diff_win_2 = strtotime($row->date) - strtotime($win_2['top_date']);
	}
    else {
        $win_2['mean'] = 0;
        $win_2['median'] = 0;
        $diff_win_2 = 0;
    }
	
	if (sizeof($tie_odds)>0) {
		usort($tie_odds,"custom_sort");
		$tie['mean'] /= sizeof($tie_odds);
		if (sizeof($win_2_odds) % 2 == 1) {
			$tie['median'] = $tie_odds[floor(sizeof($tie_odds)/2)]->odds;
		}
		else {
			$tie['median'] = ($tie_odds[sizeof($tie_odds)/2-1]->odds + $tie_odds[sizeof($tie_odds)/2]->odds)/2;
		}
		$diff_tie = strtotime($row->date) - strtotime($tie['top_date']);
	}
    else {
        $tie['mean'] = 0;
        $tie['median'] = 0;
        $diff_tie = 0;
    }	
	
	// obtain the score of each team
	$score1 = '';
	$score2 = '';
	if (strpos($row->result_det,'&nbsp;') === false && $row->result_det !== '') {
		//$count = 0;
		$aux = explode(",",$row->result_det);
		$result_1 = str_replace('(','',$aux[0]);
		$result_1 = explode(':',$result_1); // first time
		$result_2 = $aux[1];
		$result_2 = explode(':',$result_2); // second time
		$score1 = intval(trim($result_1[0])) + intval(trim($result_2[0]));
		$score2 = intval(trim($result_1[1])) + intval(trim($result_2[1]));
	}
	else {
		$result = explode(":",$row->result);
		$score1 = $result[0];
		$score2 = $result[1];
	}
    
    if ($score1 > $score2) {
        $final_result = '1';
    }
    else if ($score1 == $score2) {
        $final_result = 'X';
    }
    else if ($score1 < $score2) {
        $final_result = '2';
    }
	
	// store the odds statistics for the match
	if (sizeof($win_1_odds)>0 || sizeof($win_2_odds)>0 || sizeof($tie_odds)>0) { 
		print("Inserting match ".$row->ID." ...\n");
		$query_insert = "INSERT INTO odds_stats_per_match_1x2_closing
						(match_table_id,match_date,league,teamA,scoreA,teamB,scoreB,
						 avg_win_1,avg_tie,avg_win_2,
						 max_win_1,max_tie,max_win_2,
						 top_bookie_win_1,top_bookie_tie,top_bookie_win_2,
						 median_win_1,median_tie,median_win_2,
						 n_win_1,n_tie,n_win_2,t_win_1,t_tie,t_win_2, result)
						 VALUES
						 (
						 '".addslashes($row->ID)."',
						 '".addslashes($row->date)."',
						 '".addslashes(trim($row->league))."',
						 '".addslashes($row->team1)."',
						 '".addslashes($score1)."',
						 '".addslashes($row->team2)."',
						 '".addslashes($score2)."',
						 '".addslashes($win_1['mean'])."',
						 '".addslashes($tie['mean'])."',
						 '".addslashes($win_2['mean'])."',
						 '".addslashes($win_1['max'])."',
						 '".addslashes($tie['max'])."',
						 '".addslashes($win_2['max'])."',
						 '".addslashes($win_1['top_bookie'])."',
						 '".addslashes($tie['top_bookie'])."',
						 '".addslashes($win_2['top_bookie'])."',
						 '".addslashes(($win_1['median'] === '')?0:$win_1['median'])."',
						 '".addslashes(($tie['median'] === '')?0:$tie['median'])."',
						 '".addslashes(($win_2['median'] === '')?0:$win_2['median'])."',
						 '".addslashes(sizeof($win_1_odds))."',
						 '".addslashes(sizeof($tie_odds))."',
						 '".addslashes(sizeof($win_2_odds))."',
						 '".addslashes(sizeof($diff_win_1))."',
						 '".addslashes(sizeof($diff_tie))."',
						 '".addslashes(sizeof($diff_win_2))."',
                         '".addslashes($final_result)."'
						 );";
		$db->query($query_insert);
	}
}
	

?>