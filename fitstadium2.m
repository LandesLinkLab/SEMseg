function [fitobj, gof, output] = fitstadium2( pts , cofmass , wgts)
%fitstadium Performs robust nonlinear least squares fitting to a stadium.
%   INPUT
%       pts: Nx2 matrix of [x,y] coordinates sampled from the perimeter 
%           of a candidate nanorod.
%       cofmass: (optional) center of mass reported as an [x,y] coordinate 
%           pair.
%       weights: (optional) set of weights for fitting
%   OUTPUT
%       fitobj: Fit results, returned as a fit object
%       gof: Goodness-of-fit statistics as a structure
%       output: Fitting algorithm information

% Get cofmass if it is not provided
if nargin == 1
    cofmass = mean(pts,1);
end

if nargin < 3
    wgts = [];
end

% Calculate polar representation
dispvect = pts - cofmass;
% es = dispvect(:,1) + 1i*dispvect(:,2);
% rhos = abs(es);
% thetas = angle(es)*180/pi;
% rhos = sqrt(sum(dispvect.^2,2));
rhos = vecnorm(dispvect')';
thetas = atan2(dispvect(:,2),dispvect(:,1));

aFittype = fittype('stadiumFcn3(x, L, R, offset_angle, true_center_x,true_center_y)');
offset_angle_init = 45; % Default value in case I remove the PCA step

% Calculate intial position for offset_angle
[coeff,~,latent] = pca([pts(:,1),pts(:,2)]);
offset_angle_init = atan(coeff(2,1)/coeff(1,1));
offset_angle_init = wrapTo2Pi(offset_angle_init);
if offset_angle_init > pi
    offset_angle_init = offset_angle_init - pi;
end

% Calculate parameter limits and initailization
L_opt = [1,4*max(rhos),2*mean(rhos)];
R_opt = [1,4*max(rhos),1*mean(rhos)];
offset_angle_opt = [0,pi,offset_angle_init];
true_center_x_opt = [-max(rhos),max(rhos),0];
true_center_y_opt = true_center_x_opt;

options = fitoptions(aFittype);
k = 1;
options.Lower = [L_opt(k), R_opt(k), offset_angle_opt(k), true_center_x_opt(k), true_center_y_opt(k)];
k = 2;
options.Upper = [L_opt(k), R_opt(k), offset_angle_opt(k), true_center_x_opt(k), true_center_y_opt(k)];
k = 3;
options.StartPoint = [L_opt(k), R_opt(k), offset_angle_opt(k), true_center_x_opt(k), true_center_y_opt(k)];
options.Robust = 'LAR';
options.Display = 'off';
options.Weights = wgts;
% options.Normalize = 'off';
% options.DiffMaxChange = 0.01;
% options.DiffMinChange = 1e-10;
[fitobj, gof, output] = fit(thetas,rhos,aFittype,options);