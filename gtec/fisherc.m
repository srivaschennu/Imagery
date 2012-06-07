function f = fisherc(d,x)

error(nargchk(2, 2, nargin));

% Convert numeric values to logicals
d = logical(d);

% Length 
n = length(d);

% Lengths of groups 0 and 1
n1 = sum(d);
n0 = sum(~d);
if(n0==0)
    error('There are no data with x=0!');
elseif(n1==0)
    error('There are no data with x=1!');
elseif (n0+n1 ~= n || sum(isnan(d))>0 || sum(isnan(x))>0)
    error('Data may not contain NANs');
end

% Mean of groups 0 and 1
x1 = mean(x(d));
x0 = mean(x(~d));

% Variance of y
var_x1 = var(x(d));
var_x0 = var(x(~d));

%Fisher criterion score
f = ((x1-x0).^2)/(var_x1+var_x0);