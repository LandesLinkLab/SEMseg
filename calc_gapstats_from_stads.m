function [gaps, sbs_flag, S_R, nrlink_coords] = calc_gapstats_from_stads(imsz,fitobjs,cofmasss)
%calc_gapstats_from_stads takes input stadium fits and calculates the gaps
%   INPUT
%       fitobjs: cell array of stadium fit objects
%       cofmasss: 2xN array of [x,y] center coordinates for each fit object
N = numel(fitobjs);
if nargin < 2
    cofmasss = zeros(N,2); 
end

% --- Loop over each fit object to make binary masks for each stadium fit
stadmasks = nan([imsz,N]);
staddists = stadmasks;
for k = 1:N
    tmpmask = stad2mask(imsz,fitobjs{k}.L,fitobjs{k}.R,...
        fitobjs{k}.offset_angle,...
        [fitobjs{k}.true_center_x + cofmasss(k,1),...
        fitobjs{k}.true_center_y + cofmasss(k,2)]);
    stadmasks(:,:,k) = tmpmask;
    staddists(:,:,k) = bwdist(tmpmask);
end

%--- Loop over each mask to get distances to all other masks
    % Optional storage of more states of the distance vectors
% distvects_store = cell(N,1);
% truncvects_store = cell(N,1);

minvects_store = cell(N,1);
Bidx_store = cell(N,1);
for k = 1:N
    % Get boundary of nanorod of interest
    B = bwboundaries(stadmasks(:,:,k));
    Bidx = sub2ind(imsz,B{1}(:,1),B{1}(:,2));
    Bidx_store{k} = Bidx;
    % Initialize data storage
    distvect = nan(size(staddists,3),numel(Bidx));
    truncvect = distvect;
    mindistvect = distvect;
    % Loop over all the nanorods and calculate the distance values at the
    % boundary pixels of the nanorod of interest
    for k2 = 1:size(staddists,3)
        % Grab distance image
        distim = staddists(:,:,k2);
        % Get distance values at the boundary
        distvals = distim(Bidx);
        % Smooth distance values
%         distvals_smoo = sgolayfilt(smooth(distvals),3,11);
        distvals_smoo = distvals;
        % Get the mean distance for the rod pair
        meandist = mean(distvals_smoo);
        distvect(k2,:) = distvals_smoo;
        % Get only the closest half of the values for each particle pair
        truncvect(k2,distvals_smoo < meandist) = distvals_smoo(distvals_smoo < meandist);
    end
    % Get just the closest particle at each point on the boundary
    [tmp,mindistidx] = min(truncvect);
    tmpidcs = sub2ind(size(truncvect),mindistidx,1:size(truncvect,2));
    mindistvect(tmpidcs) = tmp;
    % Optional plotting option 
    % Uncomment if you want to display the nearest distances for each NR
%     figure(100+k)
%     plot(truncvect')
%     title(['Distances from NR ',num2str(k)]);
%     figure(200+k)
%     plot(mindistvect');
%     title(['Min. distances from NR ',num2str(k)]);

        % Optional storage of more states of the distance vectors
%     distvects_store{k} = distvect;
%     truncvects_store{k} = truncvect;
    minvects_store{k} = mindistvect;
end

%--- Get linking lines between closest points
links = zeros(0,2);
link_coords = links;
link_lengths = links;
for k = 1:N
% for k = 1
    minvect = minvects_store{k};
    potlinks = find(sum(~isnan(minvect),2));
    % Only make links to later particles
    clearvars tmplinks
    
    % Find link locations for later particles
    lowlinks = potlinks(potlinks > k);
    if ~isempty(lowlinks)
        tmplinks(:,2) = lowlinks;
        tmplinks(:,1) = k;
    else
        tmplinks = zeros(0,2);
    end
    
    links = cat(1,links,tmplinks);
    tmp_coords = nan(numel(lowlinks),2);
    tmp_lengths = nan(numel(lowlinks),2);
    for k2 = 1:numel(lowlinks)
        tmpvect = minvect(lowlinks(k2),:);
        [val,idx] = min(tmpvect);
        tmp_coords(k2,1) = idx;
        tmp_lengths(k2,1) = val;
    end
    link_coords = cat(1,link_coords,tmp_coords);
    link_lengths = cat(1,link_lengths,tmp_lengths);
        
    % Fill in blanks for earlier particles
    uplinks = potlinks(potlinks < k);
    for k2 = 1:numel(uplinks)
        [~,idxpoint,~] = intersect(links, [uplinks(k2),k],'rows');
        tmpvect = minvect(uplinks(k2),:);
        % Reverse order of indices
        [val,idx] = min(fliplr(tmpvect));
        link_coords(idxpoint,2) = numel(tmpvect)-idx + 1;
        link_lengths(idxpoint,2) = val;
    end
end
%% Analysis
%--- Simplify link list by removing bad points
badpts = link_lengths(:,2)-link_lengths(:,1) ~= 0;
links(badpts,:) = [];
link_lengths(badpts,:) = [];
link_lengths(:,2) = [];
link_coords(badpts,:) = [];

%--- Get orientations for each NR for calculating side-by-side
nrorients = nan(size(links));
for k = 1:numel(links)
    nridx = links(k);
    nrorients(k) = fitobjs{nridx}.offset_angle;
end
% Threshold potential side-by-side NRs
orient_thd = 10;
parr_flag = abs(nrorients(:,1)-nrorients(:,2)) <= orient_thd;
% Check if they are close enough to side-by-side
parr_idx = find(parr_flag);
centeralign_links = false(size(parr_flag));
for k = 1:numel(parr_idx)
    % Get NR lengths and angles
    NR1 = links(parr_idx(k),1);
    NR2 = links(parr_idx(k),2);
    fitobj1 = fitobjs{NR1};
    fitobj2 = fitobjs{NR2};
    tmpLs = [fitobj1.L,fitobj2.L];
    tmpRs = [fitobj1.R,fitobj2.R];
    tmpAngles = [fitobj1.offset_angle,fitobj2.offset_angle];
    tmpx = [fitobj1.true_center_x + cofmasss(NR1,1), fitobj2.true_center_x + cofmasss(NR2,1)];
    tmpy = [fitobj1.true_center_y + cofmasss(NR1,2), fitobj2.true_center_y + cofmasss(NR2,2)];
    % Find the longest NR to use for comparison
    [~,longidx] = max(tmpLs);
    shortidx = setdiff([1,2],longidx);
    % Calculate the vector connecting the centers from long to short
    connectvect = [tmpx(shortidx)-tmpx(longidx),tmpy(shortidx)-tmpy(longidx)];
    projlength = abs(sum(connectvect .* [cosd(tmpAngles(longidx)),sind(tmpAngles(longidx))]));
    if projlength < (tmpLs(longidx)/2 + tmpRs(longidx))
        centeralign_links(parr_idx(k)) = true;
    end
end
% Centeralign links already takes into account the parale
sbs_flag = centeralign_links;
%--- Filter out links that are longer than half of the nanorod width
nw_widths = nan(numel(fitobjs),1);
for k = 1:numel(fitobjs)
    nw_widths(k) = fitobjs{k}.R;
end
widththd = nanmean(nw_widths);
badpts = link_lengths > widththd;
sbs_flag(badpts) = false;

%--- Calculate order parameter
parr_link_counter = repmat(sbs_flag,1,2);
sub_order = nan(N,1);
for k = 1:N
    sub_order(k) = sum(parr_link_counter(links == k));
end

S_R = sum(sub_order)/(2*(numel(sub_order)-1));

    % Calculate statistics
% med_gap = median(link_lengths);
% med_sbs_gap = median(link_lengths(parr_links));
% med_nonsbs_gap = median(link_lengths(~parr_links));

%--- Loop to get sets of coordinates for each link
link_x_coords = nan(size(links));
link_y_coords = link_x_coords;
for k = 1:size(links,1)
    lnk = links(k,:);
    coords = link_coords(k,:);
    tmpidx(1) = Bidx_store{lnk(1)}(coords(1));
    tmpidx(2) = Bidx_store{lnk(2)}(coords(2));
    [link_y_coords(k,:),link_x_coords(k,:)] = ind2sub(imsz,tmpidx);
end
nrlink_coords.x = link_x_coords;
nrlink_coords.y = link_y_coords;
gaps = link_lengths;
end

