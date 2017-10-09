function Figure3()

% comment the next 3 lines if using Matlab
%warning("off")
%pkg load statistics
%pkg load nan

dbstop if error
addpath('./aux_files/')
addpath('./aux_plot/')
addpath('./strategies/')

%% Parameters
dat_dir = '../data/';
dat_series_dir = '../data/odds_series_b/';
figs_dir = '../figures/';
files = dir([dat_series_dir '*.txt']);

save_data_name = 'returns_ContinuousOddsSeries_b';
runStrategies = 1; 
bet = 50; % money to bet
marg = 0.05; % place bets above this margin
nValidOdds = 3;  % minimum number of required valid odds at each time step
hoursBeforeOnset = 5;
hours = {(71-hoursBeforeOnset+1):71 (143-hoursBeforeOnset+1):143 (215-hoursBeforeOnset+1):215};
% if "1", the script will randomly discard a proportion of the available bets
% this parameter was used to test the robustness of the strategy against Bookies blocks
% or for the cases where the odds offered online had changed at the bookmakers site.
discard_games_randomly = 0;
prop2discard = 0.3; % if "discard_games_randomly == 1", proportion of games to discard

nSamps = 2000; % number of returns to calculate (with replacement) for the "Random Bet Strategy"
    
rand('seed',1) % use always the same seed to get same results

%% Load datasets
file_name = 'paper_trading.csv';
fid = fopen([dat_dir file_name], 'r');
% Match Id, team 1, team 2, league, date, result, date laid, bookmaker, bet
% type, bet laid result, odds date time, odds, amount, win / loss, profit
C = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s %f %s %f %f', 'delimiter', ',');
paper_trading = C{15};
paper_trading_accuracy = C{14};
paper_trading_odds = C{12};
paper_trading_betResult = C{10};
fclose(fid);

file_name = 'real_betting.csv';
fid = fopen([dat_dir file_name], 'r');
C = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s %f %s %f %f', 'delimiter', ',');
real_betting = C{15};
real_betting_accuracy = C{14};
real_betting_odds = C{12};
real_betting_betResult = C{10};
fclose(fid);

%% Calculate profit for Paper Trading and Real betting
money_paperTrading = cumsum(paper_trading);
money_realBetting = cumsum(real_betting);

money = [money_paperTrading; money_realBetting + money_paperTrading(end)];
accuracy = [paper_trading_accuracy; real_betting_accuracy];
nBets = length(accuracy);

samps_trad = length(money_paperTrading);
samps_real = length(money_realBetting);

paper_trading_acc = sum(paper_trading_accuracy == 1 ) / length(paper_trading_accuracy);
paper_trading_return = money_paperTrading(end) / (samps_trad * bet);
paper_trading_profit = money_paperTrading(end);

real_betting_acc = sum(real_betting_accuracy == 1 ) / length(real_betting_accuracy);
real_betting_return = money_paperTrading(end) / (samps_real * bet);
real_betting_profit = money_realBetting(end);

combined_accuracy = sum(accuracy == 1) / nBets;
combined_return = money(end) / (nBets * bet);
combined_profit = money(end);
 
odds = [paper_trading_odds; real_betting_odds];
mean_odds = mean(odds);
std_odds = std(odds);

betResults = [paper_trading_betResult ; real_betting_betResult];

s1.pHome = sum(strcmp(betResults, '1')) / nBets;
s1.pDraw = sum(strcmp(betResults, 'X')) / nBets;
s1.pAway = sum(strcmp(betResults, '2')) / nBets;

clc
fprintf('Paper Trading:\n');
fprintf('Accuracy: %2.1f \nReturn: %2.3f \nProfit: %2.1f \nNumber of bets: %d\n', paper_trading_acc * 100, ...
    paper_trading_return, paper_trading_profit, samps_trad);

fprintf('Real Betting:\n');
fprintf('Accuracy: %2.1f \nReturn: %2.3f \nProfit: %2.1f \nNumber of bets: %d\n', real_betting_acc * 100, ...
    real_betting_return, real_betting_profit, samps_real);

fprintf('Combined:\n');
fprintf('Accuracy: %2.1f \nReturn: %2.3f \nProfit: %2.1f \nNumber of bets: %d\n', combined_accuracy * 100, ...
    combined_return, combined_profit, nBets);


%% Run Random Bet Strategy
if runStrategies == 1
    s2 = randomBetStrategy_timeseries(dat_series_dir, files, bet, hours, nValidOdds, nBets, nSamps, 1, s1);     
    save([dat_dir save_data_name], 's2', 'bet')
else
    load([dat_dir save_data_name])
end


%% Print out the results for the random bet strategy

% These are are the intercepts obtained in the regression analysis of
% Figure 1 (see Figure1.m)
offsets = [-0.034, -0.057, -0.037];

% Calculate Expected Accuracy of Random bet Strategy
for m = 1 : size(s2.mean_odds, 1)
    
    oddsHome = s2.mean_odds(m, s2.ids(m,:)==1);
    oddsDraw = s2.mean_odds(m, s2.ids(m,:)==2);
    oddsAway = s2.mean_odds(m, s2.ids(m,:)==3);
    s2_prob = [ ( 1 ./ oddsHome) + offsets(1), (1 ./ oddsDraw) + offsets(2), ...
            (1 ./ oddsAway) + offsets(3)];
    s2_expectedAccuracies(m) = mean(s2_prob); %#ok
    
end
s2_accuracy = mean(mean(s2.accuracy,2));
s2_expectedAccuracy = mean(s2_expectedAccuracies);

randomStrategyMean = nanmean(s2.money(:,end));
randomStrategyStd = nanstd(s2.money(:,end));

delta_sigma = (combined_profit - randomStrategyMean) / randomStrategyStd; % distance to the mean in standard deviations

p = normcdf(combined_profit, randomStrategyMean, randomStrategyStd);
% percentage of z values expected to lie above zσ.  CI = (−zσ, zσ)
prop = (1 - p);
fraction = 1 / prop; % expressed as fraction

fprintf('Random bet strategy statistics:\n');
fprintf('# of bets: %2.0f \n Return: %2.4f\n Profit: %2.0f\n STD: %2.4f\n Expected Accuracy: %2.1f\n Accuracy: %2.2f \n',length(s2.money), ...
    randomStrategyMean/((length(s2.money)-1)*bet), randomStrategyMean, randomStrategyStd, s2_expectedAccuracy * 100, s2_accuracy * 100);


%% Plot results
f1 = figure(1); clf;

set(gcf, 'InvertHardCopy', 'on', 'PaperPositionMode', 'auto')
hold on;

plot(money_paperTrading, 'LineWidth', 2.5)
aux = money_realBetting - money_realBetting(1);
plot(samps_trad + 1 : samps_trad + samps_real, aux + money_paperTrading(end), 'LineWidth', 2.5)

xlabel('Game Number')
ylabel('Returns [U$D]')

set(gca, 'FontSize', 10)
ylim([0 3000])

legend('Paper Trading', 'Real betting', 'Location', 'NorthWest'); legend boxoff;

print(f1, '-dpng', [figs_dir 'Figure3.png'])
print(f1, '-depsc', [figs_dir 'Figure3.eps'])


