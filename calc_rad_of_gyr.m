function [R_g] = calc_rad_of_gyr(cents, wgths)
%calc_rad_of_gyr calculate the radius of gyration for a set of particle
%positions
%   INPUT
%       cents: centroid positions for each nanoparticle, expressed as an
%       Nx2 matrix of [x,y] positions.
%       wgths: (optional) Nx1 matrix of weights, such as particle area
N = size(cents,1);
if nargin < 2
    wgths = ones(N,1);
end

wgth_cents = cents .* repmat(wgths,1,2);
r_com = sum(wgth_cents,1)/ sum(wgths);

shift_cents = cents - repmat(r_com,N,1);
dists2 = sum(shift_cents.^2,2);

R_g = sqrt(sum(dists2)/N);
end

