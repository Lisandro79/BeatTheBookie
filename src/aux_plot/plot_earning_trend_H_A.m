function [money, accum_bet, acc] = plot_earning_trend_H_A(aux, bet_type, money, bet, increase_bet)

% lim =  money + bet * 12;

z = 1;

for gm = 1 : size(aux, 1)
    
    if bet > 3000
        bet = 3000;
    end
    
    accum_bet(z) = bet; %#ok
    
    if bet_type(gm) == 1
        if aux(gm,1) > aux(gm,2)
            mony = (aux(gm,9) - 1) * bet; % bet won
            acc(z) = 1;
        else
            mony = -1 * bet; % bet lost
            acc(z) = 0;
        end
        
    elseif bet_type(gm) == 2
        
        if aux(gm,1) < aux(gm,2)
            mony = (aux(gm,11) - 1) * bet; % bet won
            acc(z) = 1;
        else
            mony = -1 * bet; % bet lost
            acc(z) = 0;
        end
        
    elseif bet_type(gm) == 3
        
        if aux(gm,1) == aux(gm,2)
            mony = (aux(gm,10) - 1) * bet; % bet won
            acc(z) = 1;
        else
            mony = -1 * bet; % bet lost
            acc(z) = 0;
        end
        
    else
        continue; % not a game to bet, go to next game
        
    end
    
    money(z+1) = money(z) + mony;
    
    bet = money(z+1) * 0.025;
%     if money(z+1) > lim && increase_bet == 1
%         
%         bet = bet * 2;
%         
%         lim = lim * 2;
%         
%     end
    z = z + 1;
end

