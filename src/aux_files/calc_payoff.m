
avg_odd = 3.93;
max_odd = 4.27;

p_margin = 0.04; 
p_real = (1 / avg_odd) - p_margin; % pur estimate of the "true" probability

p_max = 1 / max_odd;

payoff = p_real * max_odd - 1;

if payoff > 0
    msg = sprintf('Payoff = %2.2f. Place bet', payoff);
    disp(msg)
else
    msg = sprintf('Payoff = %2.2f. Do not Place bet', payoff);
    disp(msg) 
end
    