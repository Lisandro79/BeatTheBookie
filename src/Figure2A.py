import numpy as np
import pandas as pd
import matplotlib as mpl
from scipy.stats import norm

import random
import bisect

bet = 50 # money on each bet
marg = 0.05 # margin odds above the mean.
n_samples = 10 # number of returns to calculate (with replacement) for the random strategy
#rand('seed',1) # use always the same seed to get same results
runStrategies = 1 # 1: run both strategies, 0: load results from disk


dir_path = '../data/'

# if your file has no headers please uncomment this line and comment the following
#data = pd.read_csv(dir_path + "closing_odds.csv",
#                   names = ['match_id','league','match_date','home_team',
#                           'home_score','away_team','away_score','avg_odds_home_win',
#                            'avg_odds_draw','avg_odds_away_win','max_odds_home_win',
#                            'max_odds_draw','max_odds_away_win','top_bookie_home_win',
#                            'top_bookie_draw','top_bookie_away_win','n_odds_home_win',
#                            'n_odds_draw','n_odds_away_win'], header=None) 

data = pd.read_csv(dir_path + "closing_odds.csv")

# helper function from: https://eli.thegreenplace.net/2010/01/22/weighted-random-generation-in-python

class WeightedRandomGenerator(object):
    def __init__(self, weights):
        self.totals = []
        running_total = 0

        for w in weights:
            running_total += w
            self.totals.append(running_total)

    def next(self):
        rnd = random.random() * self.totals[-1]
        return bisect.bisect_right(self.totals, rnd)

    def __call__(self):
        return self.next()


def beatthebookie_strategy(data, bet, marg):
    nValidOdds = 3

    result = 0 * (data['home_score'] > data['away_score']) \
           + 1 * (data['home_score'] == data['away_score']) \
           + 2 * (data['home_score'] < data['away_score'])

    earn_margin_home = ((1 / data['avg_odds_home_win'] - marg) * data['max_odds_home_win'] - 1) * \
                        (data['n_odds_home_win'] > nValidOdds)
    earn_margin_draw = ((1 / data['avg_odds_draw'] - marg) * data['max_odds_draw'] - 1) * \
                        (data['n_odds_draw'] > nValidOdds)
    earn_margin_away = ((1 / data['avg_odds_away_win'] - marg) * data['max_odds_away_win'] - 1) * \
                        (data['n_odds_away_win'] > nValidOdds)
    
    max_margin = np.max(pd.concat([earn_margin_home,earn_margin_draw,earn_margin_away],axis=1),axis=1)
    max_arg = pd.concat([earn_margin_home,earn_margin_draw,earn_margin_away],axis=1).apply(np.argmax,axis=1)
    max_margin_max_odd = (max_arg == 0) * data['max_odds_home_win'] + \
                         (max_arg == 1) * data['max_odds_draw'] + \
                         (max_arg == 2) * data['max_odds_away_win']
    max_margin_mean_odd = (max_arg == 0) * data['avg_odds_home_win'] + \
                         (max_arg == 1) * data['avg_odds_draw'] + \
                         (max_arg == 2) * data['avg_odds_away_win'
                         ]
    top_bookie = (max_arg == 0) * data['top_bookie_home_win'] + \
                 (max_arg == 1) * data['top_bookie_draw'] + \
                 (max_arg == 2) * data['top_bookie_away_win']
    
    should_bet = max_margin > 0
    bets_outcome = bet * (max_margin_max_odd - 1) * (max_arg == result) - bet * (max_arg != result)
    accuracy = (max_arg == result)[should_bet].apply(int)
    
    return [np.cumsum(bets_outcome[should_bet]), accuracy, max_margin_max_odd[should_bet], max_margin_mean_odd[should_bet], \
            max_arg.iloc(np.where(should_bet)), top_bookie[should_bet]]


[s1_money, s1_accuracy, s1_max_odds, s1_mean_odds, s1_ids, s1_top_bookie] = beatthebookie_strategy(data,bet,marg)

def random_strategy(data, n_samples, n_games, bet, p_home, p_draw, p_away):
    
    money = np.zeros([n_samples, n_games])
    accuracy = np.zeros([n_samples, n_games])
    max_odds = np.zeros([n_samples, n_games])
    mean_odds = np.zeros([n_samples, n_games])
    ids = np.zeros([n_samples, n_games])
           
    wrg = WeightedRandomGenerator([p_home,p_draw,p_away])
    
    dat = data[(data['avg_odds_home_win'] != 0.0) & (data['avg_odds_draw'] != 0.0) & (data['avg_odds_away_win'] != 0.0)]
    
    result = 0 * (dat['home_score'] > dat['away_score']) \
           + 1 * (dat['home_score'] == dat['away_score']) \
           + 2 * (dat['home_score'] < dat['away_score'])
    
    for samp in range(0,n_samples):
        print("sample: %1.0f \n" % (samp))
        inds = np.random.choice(range(0,dat.shape[0]-1),(n_games),replace=False)
        sample = dat.iloc[inds]
        sample_result = result.iloc[inds]
        bet_side = np.array([wrg.next() for i in xrange(n_games)])
        sample_max_odds = (bet_side == 0) * sample['max_odds_home_win'] + \
                         (bet_side == 1) * sample['max_odds_draw'] + \
                         (bet_side == 2) * sample['max_odds_away_win']
        sample_mean_odds = (bet_side == 0) * sample['max_odds_home_win'] + \
                         (bet_side == 1) * sample['max_odds_draw'] + \
                         (bet_side == 2) * sample['max_odds_away_win']
        
        bets_outcome = bet * (sample_max_odds - 1) * (sample_result == bet_side) - bet * (sample_result != bet_side)
        money[samp,] = np.cumsum(bets_outcome)
        accuracy[samp,] = (sample_result == bet_side).apply(int)
        max_odds[samp,] = sample_max_odds
        mean_odds[samp,] = sample_mean_odds
        ids[samp,] = bet_side
    
    return [money, accuracy, max_odds, mean_odds, ids]

[p_home, p_draw, p_away] = [np.mean(s1_ids[0:]==0), np.mean(s1_ids[0:]==1), np.mean(s1_ids[0:]==2)]

[s2_money, s2_accuracy, s2_max_odds, s2_mean_odds, s2_ids] = random_strategy(data, n_samples, s1_money.shape[0], 
                                                                             bet, p_home, p_draw, p_away)

# Mean closing odds and Expected accuracy

# Compute descriptive stats
#mS1 = mean(s1.mean_odds);
#mS2 = mean(s2.mean_odds(:));
mean_s1 = np.mean(s1_mean_odds)
mean_s2 = np.mean(s2_mean_odds[:])

#stdS1 = std(s1.mean_odds);
#stdS2 = std(s2.mean_odds(:));

std_s1 = np.std(s1_mean_odds)
std_s2 = np.std(s2_mean_odds[:])

# These are are the intercepts obtained in the regression analysis of
# Figure 1 (see Figure1.py)
offsets = [-0.034, -0.057, -0.037]

# Calculate Expected Accuracy of our strategy
s1_mean_accuracy = np.mean(s1_accuracy[:])
s1_expected_accuracy = np.mean(pd.concat([(1 / s1_mean_odds[s1_ids[:]==0]) + offsets[0], 
                                            (1 / s1_mean_odds[s1_ids[:]==1]) + offsets[1], 
                                            (1 / s1_mean_odds[s1_ids[:]==2]) + offsets[2]]))

# Calculate Expected Accuracy of Random bet Strategy
s2_expected_accuracies = np.zeros((n_samples))
for m in range(0,n_samples):
    
    odds_home = s2_mean_odds[m, s2_ids[m,:]==0]
    odds_draw = s2_mean_odds[m, s2_ids[m,:]==1]
    odds_away = s2_mean_odds[m, s2_ids[m,:]==2]
    s2_prob = np.concatenate([(1 / odds_home) + offsets[0],
                         (1 / odds_draw) + offsets[1], 
                         (1 / odds_away) + offsets[2]])
    s2_expected_accuracies[m] = np.mean(s2_prob)

s2_mean_accuracy = np.mean(np.mean(s2_accuracy))
s2_expected_accuracy = np.mean(s2_expected_accuracies)

random_strategy_mean = np.nanmean(s2_money[:,-1])
random_strategy_std = np.nanstd(s2_money[:,-1])

delta_sigma = (np.array(s1_money)[-1] - random_strategy_mean) / random_strategy_std # distance to the mean in standard deviations

#p = norm.cdf(np.array(s1_money)[-1],random_strategy_mean,random_strategy_std)
# percentage of z values expected to lie above zσ.  CI = (−zσ, zσ)
#prop = (1 - p);
#fraction = 1 / prop; % expressed as fraction

print('Mean odds of our strategy: %2.3f (STD=%2.3f) \nMean Odds Random Bet Strategy: %2.3f (STD= %2.3f) \n' % (mean_s1, std_s1, mean_s2, std_s2))

print('Beat The Bookie statistics:\n');
print(' # of bets: %2.0f \n Return: %2.4f\n Profit: %2.0f\n Expected Accuracy: %2.1f\n Accuracy: %2.2f \n' % (s1_money.shape[0], 
  np.array(s1_money)[-1]/(s1_money.shape[0] * bet) * 100,np.array(s1_money)[-1], s1_expected_accuracy * 100, s1_mean_accuracy * 100) )

print('Random bet strategy statistics:\n');
print(' # of bets: %2.0f \n Return: %2.4f\n Profit: %2.0f\n STD: %2.4f\n Expected Accuracy: %2.1f\n Accuracy: %2.2f \n' % (s2_money.shape[1],
  random_strategy_mean/(s2_money.shape[1]*bet) * 100, random_strategy_mean, random_strategy_std, s2_expected_accuracy * 100, s2_mean_accuracy * 100) )

mpl.pyplot.plot(range(s1_money.shape[0]),s1_money)
mpl.pyplot.show()