function strategy = randomBetStrategy(dat, nSamps, nGamesStrategy, bet, s1)

% We build the null distribution by sampling with replacement N games (same
% amount as in "Beat the Bookie" strategy) and running the random strategy
% on each sample.
% The strategy selects the highest odd offered across bookmakers.

money = nan(nSamps, nGamesStrategy + 1); % pre-allocate matrix of returns
accuracy = nan(nSamps, nGamesStrategy); % pre-allocate matrix of returns
money(:,1) = 0;
ids = nan(nSamps, nGamesStrategy);
max_odds = nan(nSamps, nGamesStrategy);
mean_odds = nan(nSamps, nGamesStrategy);

for samp = 1 : nSamps
    
    m = 1; % counter for money
    
    % Select a random sample of games
    rnd_idx = randperm(size(dat,1));
    dat_rnd = dat(rnd_idx(1: nGamesStrategy),:);
    nGames = size(dat_rnd, 1);
    
    gm = 1;
    while gm <= nGames
        
        score_home = dat_rnd(gm, 1);
        score_away = dat_rnd(gm, 2);
        if score_home > score_away
            result = 1;
        elseif score_home == score_away
            result = 2;
        else
            result = 3;
        end
        
        averages = dat_rnd(gm, 3:5); % [avg_home avg_draw avg_away];
        maximums = dat_rnd(gm, 6:8); % [max_home max_draw max_away];
        
        % Select what to bet (Home, Draw or away) according to the
        % respective probabilities. These probabilities come from
        % the results of our strategy.
        id = sum(rand >= cumsum([0, s1.pHome, s1.pDraw, s1.pAway]));
        % id = randsample(3,1,true); % choose randomly if to bet home, away or tie
        
        % Check that there is at least one valid Odds offer. If the bets are still not
        % online for this time, continue to the next game
        if isnan(averages(id)) || isnan(maximums(id)) || averages(id) == 0 || maximums(id) == 0
            continue
        end
        
        possible_earn = bet  * (maximums(id) - 1);
        bet_result = id;
        
        % calculate loss / earning
        if isequal(bet_result, result)
            money(samp, m + 1) = money(samp, m) + possible_earn;
            accuracy(samp, m) = 1;
        else
            money(samp, m + 1) = money(samp, m) - bet;
            accuracy(samp, m) = 0;
        end
        
        ids(samp, m) = id;
        max_odds(samp, m) = maximums(id);
        mean_odds(samp, m) = averages(id);
        
        % SANITY CHECK
        if mean_odds(samp, m) == 0 || mean_odds(samp, m) == Inf || isnan(mean_odds(samp, m))
            fprintf('Games with non valid odds values');
        end

        m = m + 1;
        gm = gm + 1;
    end
    
    if mod(samp, 20) == 0
        disp(['Completed ' num2str(samp / nSamps * 100) '% of games'])
    end
    
 
end

strategy.money = money(:,1 : m - 1);
strategy.max_odds = max_odds;
strategy.mean_odds = mean_odds;
strategy.accuracy = accuracy;
strategy.ids = ids;

end
