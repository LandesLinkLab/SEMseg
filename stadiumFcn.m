function [rhos] = stadiumFcn(thetas, L, R, offset_angle, true_center_x, true_center_y)
%stadiumFcn is a function that draws a stadium
%   INPUT:

rhos = nan(size(thetas));
thetas = wrapTo180(thetas);
% Default arguments for funsies
if nargin == 1
    L = 3;
    R = 1;
    offset_angle = 0;
    true_center_x = 0;
    true_center_y = 0;
end

% Shift vector from center of nanorod to endcap
r_L = L/2;
phi_L = offset_angle;

% Shift vector from origin to center of nanorod
r_c = norm([true_center_x,true_center_y]);
phi_c = atan2d(true_center_y,true_center_x);

% Transition point between the piecewise pieces
theta_cross = atand(2*R/L);
r_cross = sqrt(R^2 + (L/2)^2);

[~,theta_1] = vecsum_polard([r_cross,theta_cross+phi_L],[r_c,phi_c]);
[~,theta_2] = vecsum_polard([r_cross,(180-theta_cross+phi_L)],[r_c,phi_c]);
[~,theta_3] = vecsum_polard([r_cross,(-180+theta_cross+phi_L)],[r_c,phi_c]);
[~,theta_4] = vecsum_polard([r_cross,(-theta_cross+phi_L)],[r_c,phi_c]);

% theta_1 = angle(r_c*exp(1i*phi_c*pi/180) + r_cross*exp(1i*theta_cross*pi/180)*exp(1i*phi_L*pi/180))*180/pi;

theta_pairs = [theta_4,theta_1 ; theta_1,theta_2; theta_2,theta_3; theta_3,theta_4];

angs = cell(size(theta_pairs,1),1);
for k = 1:size(theta_pairs,1)
    % Get shifted angle coordinates
    shiftedangs = wrapTo360(thetas - theta_pairs(k,1));
    angs{k} = shiftedangs < wrapTo360(theta_pairs(k,2)-theta_pairs(k,1));
end
% angs_1 = thetas > theta_4 & thetas < theta_1;
% angs_2 = thetas > theta_1 & thetas < theta_2;
% angs_3 = thetas > theta_2 | thetas < theta_3;
% angs_4 = thetas > theta_3 & thetas < theta_4;
angs_1 = angs{1};
angs_2 = angs{2};
angs_3 = angs{3};
angs_4 = angs{4};

% Calculate rho for each section of the stadium
% Calculate right-hand circle
r_0_1 = sqrt(r_c^2 + r_L^2 + 2*r_c*r_L*cosd(phi_L-phi_c));
phi_0_1 = phi_c + atan2d(r_L*sind(phi_L-phi_c), r_c +r_L*cosd(phi_L-phi_c));

rhos(angs_1) = r_0_1 * cosd(thetas(angs_1)-phi_0_1) ...
    + sqrt(R^2 - r_0_1^2*(sind(thetas(angs_1)-phi_0_1)).^2);

% Calculate left-hand circle
r_0_2 = sqrt(r_c^2 + r_L^2 + 2*r_c*r_L*cosd(180+phi_L-phi_c));
phi_0_2 = phi_c + atan2d(r_L*sind(180+phi_L-phi_c), r_c +r_L*cosd(180 + phi_L-phi_c));

rhos(angs_3) = r_0_2 * cosd(thetas(angs_3)-phi_0_2) ...
    + sqrt(R^2 - r_0_2^2*(sind(thetas(angs_3)-phi_0_2)).^2);

% Calculate top line
rhos(angs_2) = (R + r_c*sind(phi_c-phi_L)) * secd(thetas(angs_2) - 90 - phi_L);

% Calculate bottom line
rhos(angs_4) = (-R + r_c*sind(phi_c-phi_L)) * secd(thetas(angs_4) - 90 - phi_L);
