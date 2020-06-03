function mask = stad2mask(dims, varargin)
%stad2mask Creates a binary mask of a stadium object
%   INPUT
%       dims: [nrows,ncols]
%       varargin: Either a series of stadium parameters or a cfit object
%           for stadium fitting.
%           Stadium parameters: 
%                   L, R, offset_angle, r0
Y = dims(1);
X = dims(2);

if isequal(numel(varargin),1)
    fitobj = varargin{1};
    L = fitobj.L;
    R = fitobj.R;
    theta = fitobj.offset_angle;
    r0 = [fitobj.true_center_x, fitobj.true_center_y];
else
    L = varargin{1};
    R = varargin{2};
    theta = varargin{3};
    if isequal(numel(varargin),3)
        r0 = [0,0];
    else
        r0 = varargin{4};
    end
end

    % Inspect coordinates within a bounding rectangle around the stad   
    rect_rad = 1.5*(L/2 + R); % Half the diagonal
    startang = 90 - atand((L/2+R)/R);
    allangs = wrapTo360([startang*[-1,1], 180 + startang*[-1,1]] + theta);
    xi = cosd(allangs) * rect_rad + r0(1);
    yi = sind(allangs) * rect_rad + r0(2);
    mask = poly2mask(xi,yi,Y,X);
    
    tmpidx = find(mask);
    [ys,xs] = ind2sub([Y,X],tmpidx);
    ys = ys - r0(2);
    xs = xs - r0(1);
    tmpangs = atan2d(ys,xs);
    tmprhos_2 = xs.^2 + ys.^2;
    rhohats = stadiumFcn(tmpangs,L,R,theta,0,0);
    goodidx = tmpidx(tmprhos_2 <= rhohats.^2);
    
    mask = false([Y,X]);
    mask(goodidx) = true;