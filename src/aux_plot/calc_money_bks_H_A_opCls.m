function [money, accum_bet, acc, central_money, bk_money, nTrans] = calc_money_bks_H_A_opCls(aux, bet_type, money, ...
    bet, increase_bet, bookies_home_code_yrs, bookies_away_code_yrs, bk_money, accumulator)

% Game by game, place bets on each bookie
% Check if there is enough money in a bookie and place a bet.
% Keep the history of the central money to see the zeros


% lim =  money + bet * 12;

loss = 0.03; %loss on every transaction

central_money = money;

z = 1;
c = 1;
nTrans = 0;

bet_type = bet_type(~isnan(bet_type));
aux = aux(~isnan(bet_type), :);
bookies_home_code_yrs = bookies_home_code_yrs(~isnan(bet_type));
bookies_away_code_yrs = bookies_away_code_yrs(~isnan(bet_type));

for gm = 1 : size(aux, 1)
    
    if bet > 3000
        bet = 3000;
    end
    
    accum_bet(z) = bet; %#ok
    
    if bet_type(gm) == 1
        
        id_bk = bookies_home_code_yrs(gm);
        % Add money to the bookie if we are below the limit
        if bk_money(id_bk) < bet
            bk_money(id_bk) = bk_money(id_bk) + bet;
            central_money(c+1) = central_money(c) - bet;
            % Transfer money from another bookie if we ran out of central
            % money
            if central_money(c+1) <= bet
               [~, id_max] = max(bk_money);
               bk_money(id_max) = bk_money(id_max) - (bet + (bet * loss)); % we are losing a margin with the movement
               central_money(c+1) = central_money(c+1) + bet;
               nTrans = nTrans + 1;
            end
            c = c + 1;
        end
               
        
        if aux(gm,1) == 1
            mony = (aux(gm,5) - 1) * bet; % bet won
            bk_money(id_bk) = bk_money(id_bk) + mony;
            acc(z) = 1;
        else
            mony = -1 * bet; % bet lost
            bk_money(id_bk) = bk_money(id_bk) + mony;
            acc(z) = 0;
        end
        
    elseif bet_type(gm) == 2
        
        id_bk = bookies_away_code_yrs(gm);
        % Add money to the bookie if we are below the limit
        if bk_money(id_bk) < bet
            bk_money(id_bk) = bk_money(id_bk) + bet;
            central_money(c+1) = central_money(c) - bet;
            
            % Transfer money from another bookie if we ran out of central
            % money
            if central_money(c+1) <= bet
               [~, id_max] = max(bk_money);
               bk_money(id_max) = bk_money(id_max) - (bet + (bet * loss)); % we are losing a margin with the movement
               central_money(c+1) = central_money(c+1) + bet;
               nTrans = nTrans + 1;
            end
            
            c = c + 1;
        end
        
        if aux(gm,1) == 2
            mony = (aux(gm,7) - 1) * bet; % bet won
            bk_money(id_bk) = bk_money(id_bk) + mony;
            acc(z) = 1;
        else
            mony = -1 * bet; % bet lost
            bk_money(id_bk) = bk_money(id_bk) + mony;
            acc(z) = 0;
        end
        
    elseif bet_type(gm) == 3
        
        if aux(gm,1) == 0
            mony = (aux(gm,6) - 1) * bet; % bet won
            acc(z) = 1;
        else
            mony = -1 * bet; % bet lost
            acc(z) = 0;
        end
        
    else
        continue; % not a game to bet, go to next game
        
    end
    
    money(z+1) = money(z) + mony;
    
    bet = money(z+1) * accumulator;
%     if money(z+1) > lim && increase_bet == 1
%         
%         bet = bet * 2;
%         
%         lim = lim * 2;
%         
%     end
    z = z + 1;
    
%     if z == 4000
%         disp('here')
%     end
end



