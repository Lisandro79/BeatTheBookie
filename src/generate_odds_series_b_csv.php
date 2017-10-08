<?php

// for each match outputs a 32 x (72*3) matrix of odds
// the rows of the matrix are the different bookies
// the first 72 columns of each matrix are the odds offered for HOME win for the 72 hours previous the match
// the second 72 columns of each matrix are the odds offered for DRAW for the 72 hours previous the match
// the second 72 columns of each matrix are the odds offered for AWAY win for the 72 hours previous the match

date_default_timezone_set('UTC');

// mysql db connection configuration
$db = new PDO("mysql:host=localhost;dbname=odds_series_b;charset=utf8", 'root', 'toor');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// select the matches in the time range we want to analyze, discard matches we don't analyze (cancelled, postponed, etc.)
$query = "SELECT `date`,ID, result from 
                 matches m 
				 WHERE result not like '%CAN%' AND result not like '%WO%'
				 AND result not like '%AWA%' AND result not like '%ABN%' AND result not like '%INT%' 
				 AND result not like '%POSTP%' AND result <> '' AND NOT (result_det = '&nbsp;' and (result like '%ET%' or result like '%PEN%'))
				 ORDER BY `date` ASC;";
$r = $db->prepare($query);
$r->execute();

// all the bookies we're working with
$all_bookies = array('10Bet','12BET','188BET','bet-at-home','bet365','Betclic','Betsafe','Betsson','BetVictor','Betway','ComeOn',
'Coral','DOXXbet','Expekt','Jetbull','Ladbrokes','myBet','Paddy Power','Pinnacle Sports','SBOBET','Sportingbet','Stan James',
'Tipico','Unibet','William Hill','youwin','888sport','Interwetten','Titanbet','bwin','Betadonis','Betfair Sports');

// mapping name of bookie -> index of row in matrix
$bookie_name_to_index = array('Interwetten'=>0,
'bwin'=>1,
'bet-at-home'=>2,
'Unibet'=>3,
'Stan James'=>4,
'Expekt'=>5,
'10Bet'=>6,
'William Hill'=>7,
'bet365'=>8,
'Pinnacle Sports'=>9,
'Pinnacle'=>9,
'DOXXbet'=>10,
'Betsafe'=>11,
'Betway'=>12,
'888sport'=>13,
'Ladbrokes'=>14,
'Betclic'=>15,
'Sportingbet'=>16,
'myBet'=>17,
'Betsson'=>18,
'188BET'=>19,
'Jetbull'=>20,
'Paddy Power'=>21,
'Tipico'=>22,
'Coral'=>23,
'SBOBET'=>24,
'BetVictor'=>25,
'12BET'=>26,
'Titanbet'=>27,
'youwin'=>28,
'ComeOn'=>29,
'Betadonis'=>30,
'Betfair Sports'=>31,
'Betfair'=>31,
'mybet'=>17);

// define some constants
$interval_mins = 60;
$time_window_hours = 72;
$time_window = 60*60*$time_window_hours;

// function to sort odds by date
$cmp = function($a,$b) 
{
	if ($a->date < $b->date) return -1;
	if ($a->date == $b->date) {
		if ($a->marker == 1) return 1;
		else return -1;
	} 
	if ($a->date > $b->date) return 1;
};

// possible results of a match: 1st team wins, tie, 2nd team wins
$possible_results = array(0=>'1',1=>'X',2=>'2');

// how many matches will we process?
$total_matches = $r->rowCount();
$current_count = 1;

while($row = $r->fetch(PDO::FETCH_OBJ)) 
{

	print($row->ID.": "." $current_count / $total_matches ...\n");
	$matrix_1 = array(); // one matrix per result
	$matrix_X = array();
	$matrix_2 = array();
	$odds_exist = false;
	foreach($possible_results as $res_key=>$match_res) {
		$matrix = array();
        // for each match/result combination select all the odds we have for the match (for all bookies and dates)
		$odds_query = "SELECT oh.result, oh.disabled_date, ohs.odds as odds,ohs.odds_datetime, oh.bookmaker FROM 
						odds_history oh
						INNER JOIN
						odds_history_series ohs
						ON oh.odds_history_id = ohs.odds_history_id
						WHERE 
						oh.ID = '".$row->ID."'
						AND 
						bettype = '1x2' AND oh.result = '".$match_res."' AND ohs.odds <> '';
						";
		$res = $db->prepare($odds_query);
		$res->execute();
		
        // set up an array of objects that contains the odds, the bookie of each odd and the dates of each odd
		$time_start = strtotime($row->date) - $time_window;
		$disabled_dates = array();
		$dates_obj = array();
		while($row_ = $res->fetch(PDO::FETCH_OBJ)) {
			$odds_exist = true;
			$result = $row_->result;
            $disabled_dates[$bookie_name_to_index[$row_->bookmaker]] = $row_->disabled_date; // store the dates in which each odd offer was disabled
			$obj = new stdClass();
			$obj->date = strtotime($row_->odds_datetime);
			$obj->date_str = $row_->odds_datetime;
			$obj->odds = $row_->odds;
            $obj->bookmaker_index = $bookie_name_to_index[$row_->bookmaker];
			$obj->marker = 0;
			$dates_obj[] = $obj;		
		}
		
		// set up intermediate markers in the series that identify when we have to sample the odds
        for ($i = 0; $i < ($time_window/($interval_mins*60)) ; $i++) {
			$obj = new stdClass();
			$obj->date = strtotime($row->date) - $i*$interval_mins*60;
			$obj->date_str = date('Y-m-d H:i:s',$obj->date);
			$obj->odds = 'nan';
			$obj->marker = 1;
			$dates_obj[] = $obj;
		}
		
        // mark when each odd offer for each bookie was disabled
		foreach($disabled_dates as $key => $disabled_date) {
			if ($disabled_date) {
				$obj = new stdClass();
				$obj->date = strtotime($disabled_date);
				$obj->date_str = $disabled_date;
				$obj->odds = 'disabled';
				$obj->marker = 2;
                $obj->bookmaker_index = $key;
                $dates_obj[] = $obj;
			}
		}
		
		// sort the array of objects by datetime
		usort($dates_obj,$cmp);

		$current_array = array_fill(0,sizeof($all_bookies),'nan'); // array with odds (per bookie) as they stand at each iteration (each hour)
		                                                               // nan means disabled
		$already_disabled = array();
		$column_count = 0;
		foreach($dates_obj as $date_obj) {
			if ($date_obj->marker == 1) { // if we have reached a marker with identifier == 1, sample
				foreach($already_disabled as $disabled) {
					$current_array[$disabled] = 'nan';
				}
				$matrix[$column_count] = $current_array;
				$column_count++; // advance a column
			}
			else if ($date_obj->marker == 2) { // if the bookie disable the odd offer add to the already disabled array
				$already_disabled[] = $date_obj->bookmaker_index;
			} else { // otherwise store the odd in the running array
				$current_array[$date_obj->bookmaker_index] = $date_obj->odds;
			}
		}
		
		switch($res_key) { // store matrices for each possible result
			case 0:
				$matrix_1 = $matrix;
				break;
			case 1:
				$matrix_X = $matrix;
				break;
			case 2:
				$matrix_2 = $matrix;
				break;
		}
	}
	
	if ($odds_exist) {
		$matrix = array_merge($matrix_1,$matrix_X,$matrix_2); // merge the matrices before storage
		
		$matrix_str = '';
		for ($k = 0; $k < sizeof($all_bookies); $k++) { // set up the string that will output to file
			$line = '';
			for ($j = 0; $j < sizeof($matrix); $j++) {
				if ($j==0) {
					$line .= $matrix[$j][$k];
				}
				else {
					$line .= ','.$matrix[$j][$k];
				}
			}
			$matrix_str .= $line."\n";
		}
        
        // obtain the score of each team
        if ( (!isset($row->result_det)) || $row->result_det == "&nbsp;") {
			preg_match ( '/([0-9:]+)/', trim($row->result), $preg_matches);
			$score_parts = explode(':',$preg_matches[0]);
            $score1 = $score_parts[0];
            $score2 = $score_parts[1];
		}
		else {
			preg_match ( '/([0-9:, ]+)/', trim($row->result), $preg_matches);
			$parts = explode(",",$preg_matches[0]);
			$score_parts_1 = explode(":",$parts[0]);
			if (isset($parts[1])) {
				$score_parts_2 = explode(":",$parts[1]);
			}
			
			$score1 = $score_parts_1[0] + (isset($score_parts_2[0])?$score_parts_2[0]:0);
			$score2 = $score_parts_1[1] + (isset($score_parts_2[1])?$score_parts_2[1]:0);
		}
		
		// save matrix to file
		file_put_contents("..\\data\\odds_series_b\\match_".$row->ID.'_'.date('Y_m_d_H_i_s',strtotime($row->date)).'_'.$score1.'_'.$score2.'.txt',$matrix_str);  
	}
    $current_count++;
}


?>
