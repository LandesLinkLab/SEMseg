function [r_0, phi_0] = vecsum_polard( v1 , v2 )
%vecsum_polard sums two vectors together in polar form
r_1 = v1(1);
phi_1 = v1(2);
r_2 = v2(1);
phi_2 = v2(2);

phi_d = phi_2 - phi_1;

r_0 = sqrt(r_1^2 + r_2^2 + 2*r_1*r_2*cosd(phi_d));
phi_0 = phi_1 + atan2d(r_2*sind(phi_d) , r_1 + r_2*cosd(phi_d));