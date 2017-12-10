function calc_prob


%%

nGames = 50; % number of games
bet = 100; % units: escudos

pwin = 0.8; % probability of winning
ploss = 1 - pwin; % loosing probability

rate = 0.25;  % paying bet (what the house pays). This will be the average of
% bet payment with multiple bets

earnings =  ( (rate * win) -  ploss) * bet * nGames