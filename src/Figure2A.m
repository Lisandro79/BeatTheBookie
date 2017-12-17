% function Figure2A()

%% Stragegy implementation with Historical closing odds
% Comparison of the returns of our strategy vs a random bet strategy
% at clossing odds

% comment the next 3 lines if using Matlab
% warning("off")
% pkg load statistics
% pkg load nan

% clear all
dbstop if error
addpath('./aux_files/')
addpath('./aux_plot/')
addpath('./strategies/')

%% Parameters
dat_dir = '../data/';
file_name = 'closing_odds.csv';
bet = 50; % money on each bet
marg = 0.05; % margin odds above the mean.
nSamps = 2000; % number of returns to calculate (with replacement) for the random strategy
rand('seed',1) % use always the same seed to get same results
runStrategies = 1; % 1: run both strategies, 0: load results from disk

%% Run strategies

fid = fopen([dat_dir file_name], 'r');
% 1. match_table_id: unique identifier of the game
% 2. league of the game
% 3. match date
% 4. home team
% 5. 90-minute score of home team
% 6. away team
% 7. 90-minute score of away team
% 8. average closing odds home win
% 9. average closing odds draw
% 10. average closing odds away win
% 11. maximum offered closing odds home win
% 12. maximum offered closing odds draw
% 13. maximum offered closing odds away win
% 14. name of bookmaker offering maximum closing odds for home win
% 15. name of bookmaker offering maximum closing odds for draw
% 16. name of bookmaker offering maximum closing odds for away win
% 17. number of available closing odds for home win
% 18. number of available closing odds for draw
% 19. number of available closing odds for away win
C = textscan(fid, '%s %s %s %s %f %s %f %f %f %f %f %f %f %s %s %s %f %f %f', 'delimiter', ',');
fclose(fid);

dat = [C{5} C{7} C{8} C{9} C{10} C{11} C{12} C{13} C{17} C{18} C{19}];

if runStrategies
    
    %% Implement Our Strategy
    s1 = beatTheBookie(dat, bet, marg);
    s1.name = 'BeatTheBookies';
    fprintf('Finished running "beatTheBookie"\n')
    
    % Proportion of Home, Draw or away for games selected by our strategy.
    s1.pHome = mean(s1.ids == 1);
    s1.pDraw = mean(s1.ids == 2);
    s1.pAway = mean(s1.ids == 3);
    
    %% Implement Random bet strategy
    nGamesStrategy = length(s1.money) -1; % number of games that were selected for the historical betting
    s2 = randomBetStrategy(dat, nSamps, nGamesStrategy, bet , s1);
    s2.name = 'RandomStrategy';
    fprintf('Finished running "random Strategy"\n')
    
    save([dat_dir 'returns_HistoricalClosingOdds'], 's1', 's2', 'bet')
    
else
    %% Or load pre-calculated results from disk
    load([dat_dir 'returns_HistoricalClosingOdds.mat']);
    
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
    s2_expectedAccuracies(m) = mean(s2_prob); 
    
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


%% Figure 2A: Compare "Beat the bookie" with the Random Bet Strategy
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

set(gca, 'YTick', -200000:50000:150000, 'YTickLabel', {-200000 -150000 -100000 -50000 0 50000 100000 150000})
set(gca, 'XTick', 0:10000:60000, 'XTickLabel', {0 10000 20000 30000 40000 50000 60000})

xlim([0 80000])
ylim([-180000 125000])
set(gca, 'FontSize', fontSize)

% Draw curly brace
drawbrace([length(s1.money)-1 s1.money(end)], [length(s1.money)-1 randomStrategyMean], 20, 'Color', 'k', 'LineWidth', 2);

tit = sprintf('%2.2f', delta_sigma);
ht = text(62000, 15000, [tit ' \sigma']);
set(ht,'Rotation',270)
set(ht,'FontSize',20)

% Draw histogram inset
axes('position', [0.71 0.20 0.22 0.3]);

final_returns = s2.money(:,end);
[counts,bins] = hist(final_returns, 30); %# get counts and bin locations
h = barh(bins,counts);
h.FaceColor = [1.0 0 0];
set(gca,'visible','off');

print(f1, '-dpng', '../figures/Figure2A.png')
print(f1, '-depsc', '../figures/Figure2A.eps')

