function strat = randomBetStrategy_timeseries(dat_dir, files, bet, hours, nValidOdds, nGamesStrategy, nSamps, preload, s1)

% 1- Select random sample of games, same number as number of games in Beat
% the Bookie strategy
% For each game, select random time before the game, random outcome (home, draw, away)
% bet on the maximum odds for that outcome at that time
% calculate returns

% Proportion of Home, Draw or away that our strategy employed
pHome = s1.pHome;
pDraw = s1.pDraw;
pAway = s1.pAway;

% preload all files for speed
if preload
   all_data = nan(32,length(cell2mat(hours)),size(files,1));
   for fi = 1 : size(files,1)
       if mod(fi,1000) == 0
          fprintf('Preloading Game #%d \n', fi)
       end
       fid = fopen([dat_dir files(fi).name], 'r');
       C = textscan(fid, repmat('%f ' , [1,72*3]), 'delimiter', ',');
       fclose(fid);
       aux = cell2mat(C);
       all_data(:,:,fi) =  aux(:,cell2mat(hours));
   end
   hours{1} = hours{1} - hours{1}(1) + 1;
   hours{2} = hours{2} - hours{2}(1) + 1 + length(hours{1});
   hours{3} = hours{3} - hours{3}(1) + 1 + length(hours{1}) + length(hours{3});
end

% Pre-allocate matrixes
money = nan(nSamps, nGamesStrategy);
money(:,1) = 0;
accuracy = nan(nSamps, nGamesStrategy);
ids = nan(nSamps, nGamesStrategy);
c = 1;
wodds = 1;
wZeros = 1;

for samp = 1 : nSamps
    
    fprintf('Sample #%d \n', samp);
    dat_rnd = randperm(size(files,1));
    m = 1; % counter for money (returns always start at '0')
   
    fi = 1;
    while 1
        
        % Loop through until we get all valid games for the strategy
        if (m) > nGamesStrategy
            break
        end            
    
        if mod(fi,1000) == 0
            fprintf('Game #%d \n', fi);
        end
        
        if preload
            data = squeeze(all_data(:,:,dat_rnd(fi)));
        else
            fid = fopen([dat_dir files(dat_rnd(fi)).name], 'r');
            C = textscan(fid, repmat('%f ' , [1,72*3]), 'delimiter', ',');
            fclose(fid);
            data = cell2mat(C);
        end

        % sanity check: there are some games that had odds more than 8
        % hours away from the beginning of the game and then got cancelled.
        % We discard those few games here.
        if sum(isnan(data(:))) == (32 * 216)
            fprintf('Skip Game number %d, %s \n', dat_rnd(fi), files(dat_rnd(fi)).name);
            fi = fi + 1;
            continue;
        end

        % get result of the game
        name = strrep(files(dat_rnd(fi)).name, '.txt', '');
        C = strsplit(name, '_');
        score_home = str2double(C{end-1});
        score_away = str2double(C{end});
        if score_home > score_away
            result = 1;
        elseif score_home == score_away
            result = 2;
        else
            result = 3;
        end
        
        % Select what to bet (Home, Draw or away) according to the
        % respective probabilities. These probabilities come from
        % the results of our strategy.
        bet_result = sum(rand >= cumsum([0, pHome, pDraw, pAway]));

        % Choose time randomly
        randomTimeOutcome = randsample(hours{bet_result},1);
        
         % Check that there are at least nValidOdds in the selected hour
        if sum(~isnan(data(:, randomTimeOutcome))) < nValidOdds 
%             fprintf('Game without odds')
            wodds = wodds + 1;
            fi = fi + 1;
            continue
        end
        
        if any(data(:, randomTimeOutcome)) == 0
%             fprintf('Game with odds 0')
            wZeros = wZeros + 1;
            fi = fi + 1;
            continue
        end
               
        % select max odds at time/outcome
        max_odds(samp, m) = nanmax(data(:, randomTimeOutcome));
        mean_odds(samp, m) = nanmean(data(:, randomTimeOutcome));        
        
        % Estimate return for each game
        if (~isnan(max_odds(samp, m))) 
            aux_possible_earn = bet  * (max_odds(samp, m) - 1);
            
            % calculate loss / earning
            if isequal(bet_result, result)
                money(samp, m + 1) = money(samp, m) + aux_possible_earn;
                accuracy(samp, m) = 1;
                ids(samp, m) = bet_result;
                m = m + 1;
            else
                money(samp, m + 1) = money(samp, m) - bet;
                accuracy(samp, m) = 0;
                ids(samp, m) = bet_result;
                m = m + 1;
            end
            
        % Some games have bookies with very few valid odds. Skip them     
        else            
            c = c + 1;
            fi = fi + 1;
            continue;
        end
        
        fi = fi + 1;
    end
end

% sprintf('There were %d games with invalid / insufficient number of odds', c)
strat.money = money;
strat.name = 'RandomStrategy';
strat.max_odds = max_odds;
strat.mean_odds = mean_odds;
strat.accuracy = accuracy;
strat.ids = ids;
strat.wodds = wodds;
strat.wZeros = wZeros;

end
