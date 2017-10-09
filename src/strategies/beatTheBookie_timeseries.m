function strat = beatTheBookie_timeseries(dat_dir, files, bet, marg, nValidOdds, hours, discard_games_randomly, prop2discard)

% loop through hours
% apply formula
% keep all bookies and time when the criteria is met
% place bet only for 1 or the three options for all the bookies
% available. Discard the other options

money = 0;
accuracy = [];
m = 2; % counter for the money
acc = 1; % counter for accuracy
st2 = 1;
st = 1;
z = 0;

for fi = 1 : length(files)
   
    if mod(fi,1000) == 0
        fprintf('Game #%d \n', fi);
    end
   
    fid = fopen([dat_dir files(fi).name], 'r');
    C = textscan(fid, repmat('%f ' , [1,72*3]), 'delimiter', ',');
    fclose(fid);
    
    data = cell2mat(C);
    
    % sanity check: games with no bets
    if sum(isnan(data(:))) == (32 * 216)
        fprintf('Game number %d, %s, has only nans \n', fi, files(fi).name);
        z = z + 1;
        continue;
    end
    
    % get result of the game
    name = strrep(files(fi).name, '.txt', '');
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
    
    possible_earn = 0;

    for h = 1 : length(hours{1})
        
        avg_home = nanmean(data(:,hours{1}(h)));[max_home, bk_home_id] = nanmax(data(:, hours{1}(h)));
        avg_draw = nanmean(data(:,hours{2}(h)));[max_draw, bk_draw_id] = nanmax(data(:, hours{2}(h)));
        avg_away = nanmean(data(:,hours{3}(h)));[max_away, bk_away_id] =  nanmax(data(:, hours{3}(h)));
        
        averages = [avg_home avg_draw avg_away];
        maximums = [max_home max_draw max_away];
        bookies = [bk_home_id bk_draw_id bk_away_id];
        
        % check that there is at least one valid bet. If the bets are still not
        % online for this time, continue to the next game
        if isnan(avg_home) || isnan(avg_draw) || isnan(avg_away)
            continue
        end
        
        if isnan(max_home) && isnan(max_draw) && isnan(max_away)
            continue
        end
        
        % Apply formula and decide whether to bet
        earn_margin(1) = ((1 ./ avg_home - marg) * max_home - 1) * (sum(~isnan(data(:,hours{1}(h)))) > nValidOdds);
        earn_margin(2) = ((1 ./ avg_draw - marg) * max_draw - 1) * (sum(~isnan(data(:,hours{2}(h)))) > nValidOdds) ;
        earn_margin(3) = ((1 ./ avg_away - marg) * max_away - 1) * (sum(~isnan(data(:,hours{3}(h)))) > nValidOdds);
        
        if sum(earn_margin > 0) >= 1
            
            [~, id] = max(earn_margin);
            possible_earn = bet  * (maximums(id) - 1);
            break; 
        end
        
    end
    
    % If match did not reach the criteria for betting, move to the next
    % match
    %if sum(bets_id(:)) == 0
    if possible_earn == 0
        continue
    end
    
    % Artibtrarily skip some games to simulate a real situation of betting
    % where we miss some of the games
    if discard_games_randomly
        num = rand(1);
        if num < prop2discard
            continue
        end
    end
    
    % Decide where to place the bet: home, draw or away
    if possible_earn > 0    
        aux_possible_earn = possible_earn;
        bet_result = id;
        
        % There is an error in one of the odds: it was set to 126. I fix this here
        % I set a maximum earning of 15 for the bets
        if aux_possible_earn > 750
            continue
        end
       
        % calculate loss / earning
        if isequal(bet_result, result)
            money(m) = money(m-1) + aux_possible_earn;
            m = m + 1;
            accuracy(acc) = 1;
            ids(acc) = id;
            max_odds(acc) = maximums(id);
            mean_odds(acc) = averages(id);
            acc = acc + 1;   
        else
            money(m) = money(m-1) - bet;
            m = m + 1;
            accuracy(acc) = 0;
            ids(acc) = id;
            max_odds(acc) = maximums(id);
            mean_odds(acc) = averages(id);
            acc = acc + 1;
        end
        
    end
    
    clear data bets_id possible_earn
end

strat.money = money;
strat.name = 'BeatTheBookies';
strat.accuracy = accuracy;
strat.ids = ids;
strat.max_odds = max_odds;
strat.mean_odds = mean_odds;

end

