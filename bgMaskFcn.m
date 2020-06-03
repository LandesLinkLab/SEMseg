function [output] = bgMaskFcn(inim, varargin)
%bgMaskFcn Sample function performing background masking and showing
%intermediate steps
%   INPUT
%       inim: input grayscale image cropped to remove SEM UI
%       varargin = { bgfilt_rad, shmutz_size, thd_sig_fact}

[Y,X] = size(inim);

defargs = {18, 18, 2};
if nargin > 1
    argind = find(~cellfun(@isempty, varargin));
    defargs(argind) = varargin(argind);
end
[bgfilt_rad, shmutz_size, thd_sig_fact] = defargs{:};

im_opened_bg = imopen(inim , strel('disk',bgfilt_rad));
% Filter shmutz out based on the opening radius used to remove background
bgfilt_area = pi*shmutz_size^2;
% Threshold the opened image based on 2 std over the mean
thd1 = mean(im_opened_bg(:)) + thd_sig_fact*std(im_opened_bg(:));
bg_mask = logical(bwareafilt(im_opened_bg>thd1 , [bgfilt_area,Inf]));
% Filter im2 with the background mask.
im2 = zeros(size(inim));
im2(bg_mask) = inim(bg_mask); %- min(im(bg_mask));

fig = figure(1);
% imagesc(im2);
imagesc(bg_mask);
axis image off
colormap gray

output = fig;