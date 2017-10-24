import os
source = open('../data/odds_series.csv','r') # replace path for '../data/odds_series_b.csv' for the other dataset
path = "../data/odds_series/" # replace path for "../data/odds_series_b/" for the other dataset
header = True
for line in source.readlines():
    if header:
        header = False
        continue
    cols = line.rstrip().split(',')
    details = cols[0:5]
    fn = 'match_' + details[0] + "_" + "_".join(details[1].split("-")) + "_" + "_".join(details[2].split(":")) + "_" + "_".join(details[3:]) + ".txt"
    cols_mat = zip(*[iter(cols[5:])]*(72*3))
    file_str = "\n".join([",".join(line) for line in cols_mat]) + "\n"
    f = open(os.path.join(path,fn),"w")
    f.write(file_str)
    f.close()
    