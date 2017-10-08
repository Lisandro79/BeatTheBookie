
clc
rate1 = 1.6;
rate2 = 3.5;
bet = 1000;

margin = 1 / rate1 + 1 / rate2;

if  margin < 1
    
    x1 =  1 * bet; 
    x2 = rate1 / rate2 * bet;
    
%     1000 * 1.55
    
    msg =  sprintf('Earning margin: %f.', margin); disp(msg)
    msg =  sprintf('Sure bet at rate1: %f, rate 2: %f.', x1, x2); disp(msg)
    
else
    
    
    msg =  sprintf('Still not profitable for arbitrage: %f', margin); disp(msg)
    
end

% rate2 / rate1

% bet1 = x1 * bet
% bet2 = x2 * bet
