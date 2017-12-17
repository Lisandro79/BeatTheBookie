function strategy = beatTheBookie(dat, bet, marg)

money = 0; % initial amount of money
m = 1; % counter for money
accuracy = [];
acc = 1;
nGames = size(dat, 1);
bet_games = [];
nValidOdds = 3;

for gm = 1 : nGames
    
    score_home = dat(gm, 1);
    score_away = dat(gm, 2);
    if score_home > score_away
        result = 1;
    elseif score_home == score_away
        result = 2;
    else
        result = 3;
    end
    
    averages = dat(gm, 3:5); % [avg_home avg_draw avg_away];
    maximums = dat(gm, 6:8); % [max_home max_draw max_away];
    counts = dat(gm, 9:11);
    
    % check that there is at least one valid bet. If the bets are still not
    % online for this time, continue to the next game
    if any(isnan(averages)) || any(isnan(maximums))
        continue
    end
    
    % Apply formula and decide whether to bet
    earn_margin(1) = ((1 ./ averages(1) - marg) * maximums(1) - 1) * (counts(1) > nValidOdds) ;
    earn_margin(2) = ((1 ./ averages(2) - marg) * maximums(2) - 1) * (counts(2) > nValidOdds);
    earn_margin(3) = ((1 ./ averages(3) - marg) * maximums(3) - 1) * (counts(3) > nValidOdds);
    
    if sum(earn_margin > 0) >= 1
        
        [~, bet_result] = max(earn_margin);
        possible_earn = bet  * (maximums(bet_result) - 1);
        
        max_odds(m) = maximums(bet_result); %#ok
        mean_odds(m) = averages(bet_result); %#ok
        ids(m) = bet_result;
        
        % calculate loss / earning
        if isequal(bet_result, result)
            money(m + 1) = money(m) + possible_earn;
            accuracy(acc) = 1;
        else
            money(m + 1) = money(m) - bet;
            accuracy(acc) = 0;
            
        end
        
        bet_games(m) = gm;
        m = m + 1;
        acc = acc + 1;
    end
    
end

strategy.money = money;
strategy.odds = max_odds;
strategy.mean_odds = mean_odds;
strategy.accuracy = accuracy;
strategy.ids = ids;

end
