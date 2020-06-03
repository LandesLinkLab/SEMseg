%% Finding nearest neighbors
%--- create masks for each nanorod
LIm = m.CurrentAgg.WatershedIm;
[Y,X] = size(LIm);
stad_masks = false(Y,X,numel(stads));
for k = 1:numel(stads)
    L = stads(k).L;
    R = stads(k).R;
    theta = stads(k).theta;
    r0 = stads(k).r0;
    stad_masks(:,:,k) = stad2mask([Y,X],L,R,theta,r0);
end

stad_masks_idxed = stad_masks .* permute([1:size(stad_masks,3)],[1,3,2]);

%--- Find the shortest distance to a neighbor for each nanorod. This
%distance will be used to set the final donut region to search for all
%neighbors.
smallest_seps = nan(numel(stads),1);
maxrad = ceil(2*max([stads(:).R]));
for k = 1:numel(stads)
    neighbor_mask = stad_masks;
    neighbor_mask(:,:,k) = [];
    neighbor_mask = sum(neighbor_mask,3) > 0;
    
    nr_mask = stad_masks(:,:,k);

    for k2 = 1:maxrad
        tmp_mask = imdilate(nr_mask,strel('disk',k2));
        
        if sum(neighbor_mask(tmp_mask)) > 0
            smallest_seps(k) = k2; 
            break
        end
    end
end

%--- Find all the neighbors for each nanorod. May need to think about
%outliers at some point when determining nnrad;
nnrad = round(2*nanmean(smallest_seps));

for k = 1:numel(stads)
    nr_mask = stad_masks(:,:,k);
    donut_mask = imdilate(nr_mask,strel('disk',nnrad)) - nr_mask;
    donut_mask_stack = repmat(donut_mask,[1,1,numel(stads)]);
    overlap_stack = stad_masks & donut_mask_stack;
    overlap_vect = squeeze(sum(sum(overlap_stack,1),2));
    stads(k).NNidx = find(overlap_vect);
end

%--- Calculate their parallelness
for k = 1:numel(stads)
    theta1 = stads(k).theta;
    L1 = stads(k).L;
    R1 = stads(k).R;
    NNs = stads(k).NNidx;
    r01 = stads(k).r0;
    stads(k).NNord = nan(numel(NNs),1);
    stads(k).NNprojvect = nan(numel(NNs),1);
    for k2 = 1:numel(NNs)
        NN = NNs(k2);
        theta2 = stads(NN).theta;
        L2 = stads(NN).L;
        R2 = stads(NN).R;
        r02 = stads(NN).r0;
        
        % Parallel calculation
        d_theta = wrapTo360(abs(theta1 - theta2));
        nem_ord = (3*cosd(d_theta).^2-1)/2;
        stads(k).NNord(k2) = nem_ord;
        
        % Side-by-side calculation
        c2cvect = r02- r01;
        projvect = dot(c2cvect, [cosd(theta1),sind(theta1)]);
%         stads(k).NNprojvect(k2) = abs(projvect) < (L1/2 + R1) & abs(projvect) < (L2/2 + R2);
        stads(k).NNprojvect(k2) = 2*abs(projvect) < (L1/2 + R1 + L2/2 + R2);
    end
    stads(k).ordval = sum(stads(k).NNord .* stads(k).NNprojvect .* (stads(k).NNord>0));
end
S_r = sum([stads(:).ordval])/(2*(numel(stads)-1));