function latticestrain, x, A
cosx = cos(x)
d = A[0]*(1.+A[1]*(1.-3.*cosx*cosx))
return, d
end
