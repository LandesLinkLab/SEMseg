function [rhos] = stadiumFcn3(thetas, L, R, offset_angle, true_center_x, true_center_y)
%stadiumFcn is a function that draws a stadium
%   INPUT:

rhos = nan(size(thetas));
thetas = wrapToPi(thetas);
% Default arguments for funsies
if nargin == 1
    L = 3;
    R = 1;
    offset_angle = 0;
    true_center_x = 0;
    true_center_y = 0;
end

rotvec = exp(1i*offset_angle);
% Shift vector from center of nanorod to endcap
L_vec = L/2;
% r_L = L/2;
% phi_L = offset_angle;

% Shift vector from origin to center of nanorod
c = true_center_x + 1i*true_center_y;
% r_c = norm([true_center_x,true_center_y]);
% phi_c = atan2(true_center_y,true_center_x);

% Transition point between the piecewise pieces
R_vec = 1i * R;
% cross = L/2 + 1i*R;
% theta_cross = atan(2*R/L);
% r_cross = sqrt(R^2 + (L/2)^2);

topr_trans = c+(L_vec+R_vec)*rotvec;
botl_trans = c+(-L_vec-R_vec)*rotvec;

trans_theta(1) = angle(topr_trans);
trans_theta(2) = angle(c+(-L_vec+R_vec)*rotvec);
trans_theta(3) = angle(botl_trans);
trans_theta(4) = angle(c+(L_vec-R_vec)*rotvec);

% Find the minimum point to rotate about
[minval,lowest_trans] = min(trans_theta);
sort_trans_theta = circshift(trans_theta,(1-lowest_trans));
sort_labels = circshift(1:4,(1-lowest_trans));

angidx = discretize(thetas,[-Inf,sort_trans_theta,Inf]);

angs = cell(4,1);
% angs{lowest_trans}= [thetas(angidx == 5), thetas(angidx==1)];
angs{lowest_trans} = angidx == 5 | angidx == 1;
for k = 2:4
%     angs{sort_labels(k)} = thetas(angidx == k);
    angs{sort_labels(k)} = angidx == k;
end

angs_1 = angs{1};
angs_2 = angs{2};
angs_3 = angs{3};
angs_4 = angs{4};

% % Calculate rho for each section of the stadium
% % Calculate right-hand circle
% r_0_1 = sqrt(r_c^2 + r_L^2 + 2*r_c*r_L*cos(phi_L-phi_c));
% phi_0_1 = phi_c + atan2(r_L*sind(phi_L-phi_c), r_c +r_L*cos(phi_L-phi_c));
% 
tmpvec = c+L_vec*rotvec;
r_0_1 = abs(tmpvec);
phi_0_1 = angle(tmpvec);
rhos(angs_1) = r_0_1 * cos(thetas(angs_1)-phi_0_1) ...
    + sqrt(R^2 - r_0_1^2*(sin(thetas(angs_1)-phi_0_1)).^2);
% 
% % Calculate left-hand circle
% r_0_2 = sqrt(r_c^2 + r_L^2 + 2*r_c*r_L*cos(pi+phi_L-phi_c));
% phi_0_2 = phi_c + atan2(r_L*sind(pi+phi_L-phi_c), r_c +r_L*cos(pi + phi_L-phi_c));
% 
tmpvec = c-L_vec*rotvec;
r_0_2 = abs(tmpvec);
phi_0_2 = angle(tmpvec);

rhos(angs_3) = r_0_2 * cos(thetas(angs_3)-phi_0_2) ...
    + sqrt(R^2 - r_0_2^2*(sin(thetas(angs_3)-phi_0_2)).^2);

% % Calculate top line
% rhos(angs_2) = (R + r_c*sin(phi_c-phi_L)) * sec(thetas(angs_2) - pi/2 - phi_L);
% rhos(angs_2) = real(topr_trans*exp(1i*thetas(angs_2)));
rhos(angs_2) = -(imag(c*exp(1i*thetas(angs_2)))) + (imag((R_vec+L_vec)*rotvec*exp(1i*thetas(angs_2))));
% 
% % Calculate bottom line
% rhos(angs_4) = (-R + r_c*sin(phi_c-phi_L)) * sec(thetas(angs_4) - pi/2 - phi_L);
