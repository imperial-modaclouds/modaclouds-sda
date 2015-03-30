function [ F_value ] = createF( n, p_pertest )

funMU = @(a,x) a(1,1)*x+a(1,2)*x+a(1,3);

[M,R] = size(n);
F_value = zeros(M,R);

for m = 0:M-1
    if m == 0
        F_value(m+1,:) = ones(1,R);
        continue
    end
    for r = 1:R
        F_value(m+1,r) = funMU(p_pertest{m,r},n(m+1,r));
    end
end


end
