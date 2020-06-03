function [ director , ord_2d , ord_s ] = calc_2D_order( inangs )
%calc_2D_order Calculates the director and 2d order parameter and nematic
%order parameter for a series of orientations
%   Director calculation based on:
% ---   "Measuring order and biaxiality", Robert J. Low, 2002,
% ---   https://doi.org/10.1088/0143-0807/23/2/303 
N = numel(inangs);

% Calculate unit vectors, ez, for each orientation
inangs = inangs(:);
ez = [cosd(inangs),sind(inangs)];
ez(:,3) = 0; % Needs to be 3d for kron product
ez = ez'; % Use column vectors for kron product

% Calculate sub dyadic, Pzz
invN = 1/N;
Pzz = invN * kron(ez(:,1),ez(:,1));
for k = 2:N
    Pzz = Pzz + invN * kron(ez(:,k),ez(:,k));
end
Pzz = reshape(Pzz,[3,3]);

% Calculate 2nd rank ordering tensor and eigenvectors
Qzz = 0.5 * (3*Pzz - eye(3));
[V,D] = eig(Qzz);

D = sum(D,1); %Collapse eigenvalue matrix
[ord_s,idx] = max(D);
evect = V(:,idx);


% Calculate ord_2d
director = atan2d(evect(2),evect(1));
ord_2d = invN * sum(cosd(2*(director-inangs)));
end