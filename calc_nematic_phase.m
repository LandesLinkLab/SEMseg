function [ director , orderparam , outangs ] = calc_nematic_phase( inangs )
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here
N = numel(inangs);

%% Calculate matrix of which angles are flipped
% Rows of boolmat correspond to individual angles and columns correspond to
% different combinations of true and false
boolmat = false(N,2^N);
counter = 2; % Row 1 is all false
Nlist = 1:N;
for k = 1:N
    tmpcomb = nchoosek(Nlist,k);
    for l = 1:size(tmpcomb,1)
        boolmat((tmpcomb(l,:)) , counter) = true;
        counter = counter+1;
    end
end

%% Calculate converted angles and best director
inangs = wrapTo360(inangs);

NN = 2^N;
alldirectors = zeros(NN,1);
allops = zeros(NN,1);

for nn = 1:NN
    tmpangs = inangs;
    tmpangs(boolmat(:,nn)) = tmpangs(boolmat(:,nn))-180;
    tmpdirector = mean(tmpangs);
    tmpop = calc_orderparam(tmpdirector,tmpangs);
    
    alldirectors(nn) = tmpdirector;
    allops(nn) = tmpop;
end


[orderparam,idx] = max(allops); %Pick most ordered director
director = alldirectors(idx);
outangs = inangs;
outangs(boolmat(:,idx)) = outangs(boolmat(:,idx)) - 180;
function [sub_op] = calc_orderparam(sub_director,sub_angs)
thetas = sub_director-sub_angs;
sub_op = 0.5*mean(3*cosd(thetas).^2 - 1);
