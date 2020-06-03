function [ppim] = preprocFcn(varargin)
%preprocFcn Takes raw image or image location and preprocesses
%   Detailed explanation goes here
DEFPATH = 'X:\Rashad Baiyasi\NRaggregate segmentation\Files from Qingfeng\Image for analysis to Rashad\10222018\BSA';
DEFNAME = '1';
DEFEXT = '.tif';
f.lp = '';
f.fn = '';
f.fe = '';
f.delim = '\';
cropreg = [1,1,1536,1024];
switch nargin
    case 1
        if isnumeric(varargin{1})
            RawIm = varargin{1};
            ppim = imcrop(RawIm, cropreg);
            return
        elseif ischar(varargin{1})
            [f.lp, f.fn, f.fe] = fileparts(varargin{1});
        else
            error('No file or image');
        end
    otherwise
        error('Bad input')
end

if isempty(f.lp)
    f.lp = DEFPATH;
end
if isempty(f.fn)
    f.fn = DEFNAME;
end
if isempty(f.fe)
    f.fe = DEFEXT;
end

RawIm = imread([f.lp,f.delim,f.fn,f.fe]);
if size(RawIm,3) == 3
    RawIm = rgb2gray(RawIm);
end
RawIm = mat2gray(RawIm);
ppim = imcrop(RawIm, cropreg);