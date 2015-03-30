function r = multi_core(n,c)
[M,R] = size(n);
r = zeros(1,M);

r(1) = 1./sum(n(1,:));

for i = 2:M
    r(i) = 1./approximate(sum(n(i,:)),c(i-1),50);
end

end

function value = approximate(x,y,k)
    value = - ((-x)*exp(-k*x) -y*exp(-k*y)) / (exp(-k*x) + exp(-k*y));
end