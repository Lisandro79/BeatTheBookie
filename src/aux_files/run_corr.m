function [slp, itrc, rsq, r_corr, p_val] = run_corr (x, y)

% x = S(su).time; y = dat;
p = polyfit(x , y, 1);
slp = p(1);
itrc = p(2);
yfit = polyval(p, x);
yresid = y - yfit;
SSresid = sum(yresid.^2);
SStotal = (length(y)-1) * var(y);
rsq = 1 - SSresid/SStotal;
[R,P] = corrcoef(x, y);
r_corr = R(2);
p_val = P(2);