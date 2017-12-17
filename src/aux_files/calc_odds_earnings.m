function calc_odds_earnings


home = 1.70;
draw = 3.75;
away = 4.75;


pHome_draw = (1 / home) + (1 / draw);
min_odds = 1 / pHome_draw;
msg = sprintf('probability of Home - Draw: %2.2f, min odds required: %2.2f', pHome_draw, min_odds);
disp(msg)