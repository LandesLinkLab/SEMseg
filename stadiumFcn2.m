function [rhos] = stadiumFcn2(thetas, L, R, offset_angle, true_center_x, true_center_y)
%stadiumFcn2 is a function that draws a stadium using complex numbers

% Initialize rhos and format angles into radians
rhos = nan(size(thetas));
thetas = wrapTo180(thetas) * pi/180;
offset_angle = offset_angle * pi/180;

% Default arguments for funsies
if nargin == 1
    L = 3;
    R = 1;
    offset_angle = 0;
    true_center_x = 0;
    true_center_y = 0;
end

r_L = L/2 * exp(1i*offset_angle);

r_c = true_center_x + 1i * true_center_y;

r_R = 1i*R * exp(1i * offset_angle);

r_s = r_c + [1,1 ; -1,1 ; -1,-1; 1,-1] * [r_L, r_R];

theta_s = phase(r_s);

theta_pairs = [circshift(theta_s,[1,0]),theta_s];

angs = cell(size(theta_pairs,1),1);

for k = 1:size(theta_pairs,1)
    % Get shifted angle coordinates
    shiftedangs = wrapTo2Pi(thetas - theta_pairs(k,1));
    angs{k} = shiftedangs < wrapTo2Pi(theta_pairs(k,2)-theta_pairs(k,1));
end