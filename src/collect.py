import os, fnmatch
from itertools import cycle

dest = open('odds_series.csv','w') # replace by 'odds_series_b.csv' for b dataset

flatten = lambda l: [item for sublist in l for item in sublist]

header_cols = ['match_id','match_date','match_time','score_home','score_away'] \
+ flatten([[''.join(map(str,t)) for t in zip(cycle(['home_b'+str(x)+'_']),range(0,72))] \
+ [''.join(map(str,t)) for t in zip(cycle(['draw_b'+str(x)+'_']),range(0,72))] \
+ [''.join(map(str,t)) for t in zip(cycle(['away_b'+str(x)+'_']),range(0,72))] for x in range(1,33)]) 


header = ','.join(header_cols) + "\n"

dest.write(header)

path = "../data/odds_series/" # replace by "../data/odds_series_b/" for b dataset

for fn in fnmatch.filter(os.listdir(path), '*.txt'):
    f = open(os.path.join(path,fn),"r")
    collected = []
   
    details = fn.rstrip(".txt").split("_")
    match_id = details[1]
    match_year = details[2]
    match_month = details[3]
    match_day = details[4]
    match_hour = details[5]
    match_minutes = details[6]
    match_seconds = details[7]
    match_score_home = details[8]
    match_score_away = details[9]
    
    for line in f.readlines():
        for col in line.rstrip().split(","):
            collected.append(col)
            
    match_cols = [match_id, match_year + "-" + match_month + "-" + match_day, match_hour + ":" + match_minutes + ":" + match_seconds, match_score_home, match_score_away] + collected
    match_line = ','.join(match_cols) + "\n"
    dest.write(match_line)
    f.close()

dest.close()

    
    