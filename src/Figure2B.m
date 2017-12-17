function Figure2B ()

%% Stragegy implementation with Historical time series odds (from 5 hours
%% before the start of each game)

% This betting strategy searches for suitable bets from 5 to 1 hour
% before the onset of the game. Places bets on a first-come first serve
% basis

% Uncomment the next 3 lines if using Octave
%warning("off")
%pkg load statistics
%pkg load nan

% clear all
dbstop if error
addpath('./aux_plot/')
addpath('./strategies/')

%% Parameters
dat_dir = '../data/odds_series/';
save_data_dir = '../data/';
figs_dir = '../figures/';
files = dir([dat_dir '*.txt']);

save_data_name = 'returns_ContinuousOddsSeries';
runStrategies = 1; % 1: run the two strategies and plot results, 0: load results of strategies from disk and plot
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
    
rand('seed',2) % use always the same seed to get same results

if runStrategies
    
    %% Beat the Bookie with timeseries odds
    s1 = beatTheBookie_timeseries(dat_dir, files, bet, marg, nValidOdds, hours, discard_games_randomly, prop2discard);
        
    % Proportion of Home, Draw or away for games selected by our strategy.
    s1.pHome = mean(s1.ids == 1);
    s1.pDraw = mean(s1.ids == 2);
    s1.pAway = mean(s1.ids == 3);
    
    %% Implement Random bet strategy
    nGamesStrategy = length(s1.money) - 1; % number of games that were selected for the historical betting
    s2 = randomBetStrategy_timeseries(dat_dir, files, bet, hours, nValidOdds, nGamesStrategy, nSamps,1, s1);     
    save([save_data_dir save_data_name], 's1', 's2', 'bet')
else
    load([save_data_dir save_data_name])
end


%% Mean closing odds and Expected accuracy

% Compute descriptive stats
mS1 = mean(s1.mean_odds);
mS2 = mean(s2.mean_odds(:));
stdS1 = std(s1.mean_odds);
stdS2 = std(s2.mean_odds(:));

% These are are the intercepts obtained in the regression analysis of
% Figure 1 (see Figure1.m)
offsets = [-0.034, -0.057, -0.037];

% Calculate Expected Accuracy of our strategy
s1_prob = [ ( 1 ./ s1.mean_odds(s1.ids==1 )) + offsets(1) , (1 ./ s1.mean_odds(s1.ids==2)) + offsets(2), ...
    (1 ./ s1.mean_odds(s1.ids==3)) + offsets(3)];
s1_accuracy = mean(s1.accuracy);
s1_expectedAccuracy = mean(s1_prob);

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

delta_sigma = (s1.money(end) - randomStrategyMean) / randomStrategyStd; % distance to the mean in standard deviations

p = normcdf(s1.money(end),randomStrategyMean,randomStrategyStd);
% percentage of z values expected to lie above zσ.  CI = (−zσ, zσ)
prop = (1 - p);
fraction = 1 / prop; % expressed as fraction

clc
fprintf('Mean odds of our strategy: %2.3f (STD=%2.3f) \nMean Odds Random Bet Strategy: %2.3f (STD= %2.3f) \n', ...
    mS1, stdS1, mS2, stdS2);

fprintf('Beat The Bookie statistics:\n');
fprintf('# of bets: %2.0f \n Return: %2.4f\n Profit: %2.0f\n Expected Accuracy: %2.1f\n Accuracy: %2.2f \n',length(s1.money)-1, ...
    s1.money(end)/((length(s1.money)-1) * bet),s1.money(end), s1_expectedAccuracy * 100, s1_accuracy * 100);

fprintf('Random bet strategy statistics:\n');
fprintf('# of bets: %2.0f \n Return: %2.4f\n Profit: %2.0f\n STD: %2.4f\n Expected Accuracy: %2.1f\n Accuracy: %2.2f \n',length(s2.money), ...
    randomStrategyMean/((length(s2.money)-1)*bet), randomStrategyMean, randomStrategyStd, s2_expectedAccuracy * 100, s2_accuracy * 100);

%% Figure 2B: Compare our strategy with the Random Bet Strategy

f1 = figure(1); clf;
set(gcf, 'Position', [0 0 1200 800], 'InvertHardCopy', 'on', 'PaperPositionMode', 'auto')
hold on

% Random strategy
p3 = plot(mean(s2.money), 'r', 'LineWidth', 3);
p1 = plot(s2.money', '-r', 'LineWidth', 3);
for m = 1 : length(p1)
    p1(m).Color(4) = 0.01;
end

% Beat the bookie
p2= plot(s1.money, 'b', 'LineWidth', 3);
p2.Color(4) = 0.8;

xlabel('Game Number')
ylabel('Returns [U$D]')
fontSize = 16;
set(gca, 'FontSize', fontSize)
legend([p2, p3], 'Our Strategy', 'Random Bet Strategy', 'Location', 'SouthWest')
legend boxoff

% Change color of line back to black without affecting the legend
p3 = plot(mean(s2.money), 'k', 'LineWidth', 3);
p3.Color(4) = 0.7;

set(gca, 'YTick', -400000:10000:400000, 'YTickLabel', {-40000 -30000 -20000 -10000 0 10000 20000 30000 40000})

xlim([0 10500])
ylim([-30000 40000])
set(gca, 'FontSize', fontSize)

% Draw curly brace
drawbrace([length(s1.money)-1 s1.money(end)], [length(s1.money)-1 randomStrategyMean], 20, 'Color', 'k', 'LineWidth', 2);

tit = sprintf('%2.2f', delta_sigma);
ht = text(8000, 22000, [tit ' \sigma']);
set(ht,'Rotation',270)
set(ht,'FontSize',20)

% Draw histogram inset
axes('position',[ 0.69 0.24 0.23 0.45]);
final_returns = s2.money(:,end);
[counts,bins] = hist(final_returns, 30); %# get counts and bin locations
h = barh(bins,counts);
h.FaceColor = [1.0 0 0];
set(gca,'visible','off');

print(f1, '-dpng', './paper_figures/Figure2B.png')
% print(f1, '-depsc', './paper_figures/Figure2B.eps')

