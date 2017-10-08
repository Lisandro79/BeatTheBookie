function [money, accum_bet] = plot_earning_trend(aux, bet_type, money, bet)

% For a given set of games, estimate the trend of earnings given an initial
% money (trnd) and an initial bet
% This function doubles the bet every time the earnings double
% Input:
% aux: matrix of games
% bet_type: 1 (home favourite), 2 (away favourite)
% money: total amount of initial money
% bet: amount to bet on each game

lim = money + bet * 10;
% lim =  money * 2;

for gm = 1 : size(aux, 1)
    
    accum_bet(gm) = bet;
    
    if bet_type == 1
        
        if aux(gm,1) > aux(gm,2)
            mony = (aux(gm, 9) - 1) * bet; % bet won
        else
            mony = -bet; % bet lost
        end
        
    elseif bet_type == 2
        
        if aux(gm,1) < aux(gm,2)
            mony = (aux(gm, 11) - 1) * bet; % bet won
        else
            mony = -bet; % bet lost
        end
        
    elseif bet_type == 3
        
        if aux(gm,1) == aux(gm,2)
            mony = (aux(gm, 10) - 1) * bet; % bet won
        else
            mony = -bet; % bet lost
        end
    end
    
    money(gm+1) = money(gm) + mony;
    
    if money(gm+1) > lim
        
        bet = bet * 2;
        
        if bet > 1000
            bet = 1000;
        end
        
        lim = lim * 2;
        
    end
    
end

figure;
plot(money)
xlabel ('Games')
ylabel('Money')

%%
% figure;
% plot(accum_bet)
% xlabel ('Games')
% ylabel('Bet')

% diff(find(diff(accum_bet) ~= 0))

bs = unique(accum_bet);
for m = 1 : length(bs)
    id(m) = find(accum_bet == bs(m), 1, 'first');
end

% Check for outlier odds
if bet_type == 1
    figure; plot(aux(:,9), '*g')
elseif bet_type == 2
    figure; plot(aux(:,11), '*g')
end

