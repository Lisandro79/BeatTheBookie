function Figure1()

%% Historical analysis of Bookies prediction accuracy
% Bookmakers prediction power. A historical analysis of 10 years of football
% games shows the tight relationship between the bookmakers’ predictions and
% the actual outcome of football games. 

% comment the next 3 lines if using Matlab
%warning("off")
%pkg load statistics
%pkg load nan

addpath('./aux_files/')
addpath('./aux_plot/')
figs_dir = '../figures/';
dat_dir = '../data/';
file_name = 'closing_odds.csv';

% Fields: 
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
fid = fopen([dat_dir file_name], 'r');
C = textscan(fid, '%s %s %s %s %f %s %f %f %f %f %f %f %f %s %s %s %f %f %f', 'delimiter', ',');
fclose(fid);

dat_hist = [C{5} C{7} C{8} C{9} C{10}];
dat_hist(:, 3:5) = 1 ./ dat_hist(:, 3:5);

leagues = C{2};
nLeagues = length(unique(leagues));
nGames = size(dat_hist, 1);

pHome = sum(dat_hist(:,1) > dat_hist(:,2)) / nGames;
pDraw = sum(dat_hist(:,1) == dat_hist(:,2)) / nGames;
pAway = sum(dat_hist(:,1) < dat_hist(:,2)) / nGames;

fprintf('Total number of games: %d \n', nGames); 
fprintf('Total number of Leagues: %d \n', nLeagues);
fprintf('Proportion of Home victories: %.3f \n', pHome);
fprintf('Proportion of Draws: %.3f \n', pDraw);
fprintf('Proportion of Away victories: %.3f \n', pAway);

%% Calculate accuracy of prediction as a function of the implicit probability 
%% contained in the odds
odds_bins = 0:0.0125:1; % probability bins
nGames2Bet = 100;

% Home victory
val_bin = 1; % counter for valid bins
for bn = 1 : length(odds_bins) - 1
   
    % Get the data from the bin
    dat_bin = dat_hist(dat_hist(:, 3) > odds_bins(bn) & dat_hist(:, 3) <= odds_bins(bn + 1), :);
    % Get accuracy for home, draw away
    if isempty(dat_bin) || size(dat_bin,1) < nGames2Bet
        continue
    end
        
    % Home wins
    acc_home(val_bin) = sum(dat_bin(:,1) > dat_bin(:,2)) / size(dat_bin,1); %#ok
    bin_odds_home_mean(val_bin) = nanmean(dat_bin(:,3)); %#ok
    val_bin = val_bin + 1; 
end

% Draw
val_bin = 1;
for bn = 1 : length(odds_bins) - 1
   
    % Get the data from the bin
    dat_bin = dat_hist(dat_hist(:, 4) > odds_bins(bn) & dat_hist(:, 4) <= odds_bins(bn + 1), :);
    % Get accuracy for home, draw away
    if isempty(dat_bin) || size(dat_bin,1) < nGames2Bet
        continue
    end

    nGms(val_bin) =  size(dat_bin,1); %#ok
    acc_draws(val_bin) = sum(dat_bin(:,1) == dat_bin(:,2)) / size(dat_bin,1);  %#ok
    bin_odds_draws_mean(val_bin) = nanmean(dat_bin(:,4)); %#ok
    val_bin = val_bin + 1;
end

% Away Victory
val_bin = 1;
for bn = 1 : length(odds_bins) - 1
   
    % Get the data from the bin
    dat_bin = dat_hist(dat_hist(:, 5) > odds_bins(bn) & dat_hist(:, 5) <= odds_bins(bn + 1), :);
    % Get accuracy for home, draw away
    if isempty(dat_bin) || size(dat_bin,1) < nGames2Bet
        continue
    end
    
    % Away wins
    acc_away(val_bin) = sum(dat_bin(:,1) < dat_bin(:,2)) / size(dat_bin,1); %#ok
    bin_odds_away_mean(val_bin) = nanmean(dat_bin(:,5)); %#ok
    val_bin = val_bin + 1; 
end

%% Plot results
f1 = figure(1); clf;
set(gcf, 'Position', [0 0 1200 800], 'InvertHardCopy', 'on', 'PaperPositionMode', 'auto');
hold on;

plot(bin_odds_home_mean, acc_home, 'ok', 'MarkerSize', 5, 'MarkerFace', 'k')
plot(bin_odds_draws_mean, acc_draws, 'om', 'MarkerSize', 5, 'MarkerFace', 'm')
plot(bin_odds_away_mean, acc_away, 'ob', 'MarkerSize', 5, 'MarkerFace', 'b')

xlabel('Estimated probability [ 1 / odds]')
ylabel('p(Correct)')

set(gca, 'FontSize', 20)

legend('Home Victory', 'Draw', 'Away Victory', 'Location', 'SouthEast'); legend boxoff;

print(f1, '-dpng', [figs_dir 'Figure1.png'])
print(f1, '-depsc', [figs_dir 'Figure1.eps'])

%% Linear regression

[slp, itrc, rsq, ~, ~] = run_corr (bin_odds_home_mean, acc_home);
fprintf('Home r2: %1.3f, slope: %1.3f, intercept: %1.3f \n', rsq, slp, itrc); 

[slp, itrc, rsq, ~, ~] = run_corr (bin_odds_draws_mean, acc_draws);
fprintf('Draw r2: %1.3f, slope: %1.3f, intercept: %1.3f \n', rsq, slp, itrc); 

[slp, itrc, rsq, ~, ~] = run_corr (bin_odds_away_mean, acc_away);
fprintf('Away r2: %1.3f, slope: %1.3f, intercept: %1.3f \n', rsq, slp, itrc); 


