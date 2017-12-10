import numpy as np
import pandas as pd
import matplotlib as mpl

dir_path = '../data/'
data = pd.read_csv(dir_path + "closing_odds.csv")
#data = np.genfromtxt(dir_path + "closing_odds.csv", delimiter=',')

# Fields:
# 1. match_table_id: unique identifier of the game
# 2. league of the game
# 3. match date
# 4. home team
# 5. 90-minute score of home team
# 6. away team
# 7. 90-minute score of away team
# 8. average closing odds home win
# 9. average closing odds draw
# 10. average closing odds away win
# 11. maximum offered closing odds home win
# 12. maximum offered closing odds draw
# 13. maximum offered closing odds away win
# 14. name of bookmaker offering maximum closing odds for home win
# 15. name of bookmaker offering maximum closing odds for draw
# 16. name of bookmaker offering maximum closing odds for away win
# 17. number of available closing odds for home win
# 18. number of available closing odds for draw
# 19. number of available closing odds for away win

n_games = data.shape[0]

[u'match_id', u'league', u'match_date', u'home_team', u'home_score',
       u'away_team', u'away_score', u'avg_odds_home_win', u'avg_odds_draw',
       u'avg_odds_away_win', u'max_odds_home_win', u'max_odds_draw',
       u'max_odds_away_win', u'top_bookie_home_win', u'top_bookie_draw',
       u'top_bookie_away_win', u'n_odds_home_win', u'n_odds_draw',
       u'n_odds_away_win']

leagues = data['league']
n_leagues = pd.unique(data['league']).shape[0]

prior_home = float(sum(data['home_score'] > data['away_score'])) / n_games
prior_draw = float(sum(data['home_score'] == data['away_score'])) / n_games
prior_away = float(sum(data['home_score'] < data['away_score'])) / n_games

print('Total number of games: ' + str(n_games) + "\n")
print('Total number of Leagues:' + str(n_leagues) + "\n")
print('Proportion of Home victories: ' + str(prior_home) + "\n")
print('Proportion of Draws: ' + str(prior_draw) + "\n")
print(('Proportion of Away victories: ' + str(prior_away) + "\n"))

# Calculate accuracy of prediction as a function of the implicit probability
# contained in the odds
odds_bins = np.arange(0, 1, 0.0125)  # probability bins
min_games = 100

# Home victory
p_home = 1 / data['avg_odds_home_win']
p_draw = 1 / data['avg_odds_draw']
p_away = 1 / data['avg_odds_away_win']

home_score = data['home_score']
away_score = data['away_score']

acc_home = []
acc_draw = []
acc_away = []

bin_odds_home_mean = []
bin_odds_draw_mean = []
bin_odds_away_mean = []

for bn in range(0, len(odds_bins) - 2):
    #print("bin " + str(bn + 1) + " from" + str(len(odds_bins) -1) + "\n")
    # Get the data from the bin
    inds_home = np.where((p_home > odds_bins[bn]) & (p_home <= odds_bins[bn + 1]))[0]
    inds_draw = np.where((p_draw > odds_bins[bn]) & (p_draw <= odds_bins[bn + 1]))[0]
    inds_away = np.where((p_away > odds_bins[bn]) & (p_away <= odds_bins[bn + 1]))[0]
    # Get accuracy for home, draw away
    if (len(inds_home) >= min_games):
        acc_home.append(float(sum(home_score[inds_home] > away_score[inds_home])) / len(inds_home))
        bin_odds_home_mean.append(np.mean(p_home[inds_home]))
    if (len(inds_draw) >= min_games):
        acc_draw.append(float(sum(home_score[inds_draw] == away_score[inds_draw])) / len(inds_draw))
        bin_odds_draw_mean.append(np.mean(p_draw[inds_draw]))
    if (len(inds_away) >= min_games):
        acc_away.append(float(sum(home_score[inds_away] < away_score[inds_away])) / len(inds_away))
        bin_odds_away_mean.append(np.mean(p_away[inds_away]))

mpl.pyplot.plot(acc_home, bin_odds_home_mean, '.k')
mpl.pyplot.plot(acc_draw, bin_odds_draw_mean, '.r')
mpl.pyplot.plot(acc_away, bin_odds_away_mean, '.b')
mpl.pyplot.show()

# linear regression
from sklearn import linear_model
from sklearn.metrics import r2_score

home_regr = linear_model.LinearRegression()
draw_regr = linear_model.LinearRegression()
away_regr = linear_model.LinearRegression()

x_home = np.array(bin_odds_home_mean).reshape(-1, 1)
y_home = np.array(acc_home).reshape(-1, 1)

x_draw = np.array(bin_odds_draw_mean).reshape(-1, 1)
y_draw = np.array(acc_draw).reshape(-1, 1)

x_away = np.array(bin_odds_away_mean).reshape(-1, 1)
y_away = np.array(acc_away).reshape(-1, 1)


# fit a linear regression line to the data
home_regr.fit(x_home, y_home)
draw_regr.fit(x_draw, y_draw)
away_regr.fit(x_away, y_away)

home_preds = home_regr.predict(x_home)
draw_preds = draw_regr.predict(x_draw)
away_preds = away_regr.predict(x_away)

print('Home r2: %1.3f, slope: %1.3f, intercept: %1.3f \n' % (r2_score(y_home, home_preds),
      home_regr.coef_[0][0], home_regr.intercept_[0]))

print('Draw r2: %1.3f, slope: %1.3f, intercept: %1.3f \n' % (r2_score(y_draw, draw_preds),
      draw_regr.coef_[0][0], draw_regr.intercept_[0]))

print('Away r2: %1.3f, slope: %1.3f, intercept: %1.3f \n' % (r2_score(y_away, away_preds),
      away_regr.coef_[0][0], away_regr.intercept_[0]))

