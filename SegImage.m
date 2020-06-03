classdef SegImage < matlab.mixin.Copyable & event.EventData & handle 
    %SegImage stores an image and the segmentation parameters & sub-images.
    
    properties
        IsThisEmpty
        fileobj
        CropReg
        SegParams
        ParamMode = true % 1(true) = global, 0(false) = custom
        RawIm
        PreprocIm
        BGPreMask
        BGContour
        WatershedContour
        SharpIm
        CleanIm
        Stadium
        StadiumContour
        Outputs
    end
    
    properties (AbortSet = true)
        BGMask = 0;
        WatershedIm = 0;
    end
    
    properties (Dependent)
        CroppedRawIm
    end
    
    properties (Constant)
        DEFIM = 0;
        DEFCONTOUR = {[NaN,NaN]};
        VIEWNAMES = {'Raw Image', 'Preproc.', 'BG mask', 'Sharpening','Cleaning','Watershed','Fitting'};
        VIEWNAMESVALS = {'RawIm','PreprocIm','BGMask', 'SharpIm','CleanIm','WatershedIm','Stadium'};
%         VIEWNAMESVALS = {'RawIm','PreprocIm','BGMask', 'SharpIm','CleanIm','Stadium'};
        VIEWNAMESDICT = containers.Map(...
            {'Raw Image', 'Preproc.', 'BG mask','Sharpening','Cleaning','Watershed','Fitting'},...
            {'RawIm','PreprocIm','BGMask', 'SharpIm','CleanIm','WatershedIm','Stadium'});
        PARAMTOIMAGEMAP = containers.Map(...
            {...
            'r_open1','thd1','schm_size','sharp_rad','sharp_str',...
            'r_close1','r_open2','r_close2','r_erode1'...
            },{...
            'BGMask','BGMask','BGMask','SharpIm','SharpIm',...
            'CleanIm','CleanIm','CleanIm','CleanIm'...
            });
        DEFPARAMS = struct( 'r_open1', 12, 'thd1',0.2, 'schm_size', 12,...
                            'sharp_rad',5, 'sharp_str',50,...
                            'r_close1',1,'r_open2',2,'r_close2',3,'r_erode1',8); 
    end
    
    events
        CropChange
        ParamChange
    end
    
    %% DYNAMIC METHODS
    methods
        %--- Constructor and loadobj
        function obj = SegImage(varargin)
            %Construct an instance of the SegImage class. Construction
            %will end up with a SegImage instance with an image,
            %potentially a filehandler object, but NO SegParams.
            %   INPUT Options:
            %       [FullPath]
            %       [Image]
            %       [PathName, FileName]
            
            % Parse inputs. This will be updated as options are added.
            
            % Switch statements set up the fileobj and temporary rawim var
            switch nargin
                case 0
                    obj.fileobj = filehandler();
                    obj.IsThisEmpty = true;
                    rawim = 0;
                case 1 % Single input options
                    input = varargin{1};                    
                    if isequal(class(input),'string') || isequal(class(input),'char')
                    % If it is words
                        [path,name,ext] = fileparts(input);
                        obj.fileobj = filehandler(path,name,ext);
                        rawim = obj.fileobj.loadim;
                    elseif isnumeric(input)
                    % If it is a matrix
                        obj.fileobj = filehandler();
                        rawim = input;
                    else
                        error('Bad Input')
                    end
                    obj.IsThisEmpty = false;
                case 2 % Double input options [PathName, FileName]
                    path = varargin{1};
                    [~,name,ext] = fileparts(varargin{2});
                    obj.fileobj = filehandler(path,name,ext);
                    rawim = obj.fileobj.loadim;
                    obj.IsThisEmpty = false;
            end
            
            % Initialize RawIm
            if isequal(size(rawim,3),3)
                rawim = rgb2gray(rawim);
            end            
            obj.RawIm = double(rawim);
            
            % Initialize CropReg
            imsz = size(obj.RawIm);
            obj.CropReg = [1,1,fliplr(imsz)];
            
            % Initialize Parameters
            
        end        
        
        %--- Get outputs from the current aggregate
        function [NRoutputs, T] = getOutputs(obj)
            % TODO - consider if I want to allow for partial outputs
            obj.doGetIm('Stadium'); % Recalculate stadiums
            for k = 1:numel(obj.Stadium)
                tmp = obj.Stadium(k);
                % Reassign from the fitobj
                L = tmp.fitobj.L;
                R = tmp.fitobj.R;
                offset_angle = tmp.fitobj.offset_angle;
                x0 = tmp.fitobj.true_center_x + tmp.cpix(1);
                y0 = tmp.fitobj.true_center_y + tmp.cpix(2);
                
                NRoutputs(k).ParticleID = k;
                NRoutputs(k).Major_Axis = L+ 2*R;
                NRoutputs(k).Minor_Axis = 2*R;
                NRoutputs(k).Aspect_Ratio = NRoutputs(k).Major_Axis/NRoutputs(k).Minor_Axis;
                NRoutputs(k).Orientation = offset_angle;
                NRoutputs(k).x0 = x0;
                NRoutputs(k).y0 = y0;
                NRoutputs(k).Area = pi*R.^2 + 2*R*L;
                NRoutputs(k).Volume = pi*R.^2*(4/3 * R + L);
                NRoutputs(k).Surface_Area = 2*pi*R*(2*R + L);
            end
            obj.Outputs.Filename = [];
            if ~isempty(obj.fileobj)
                obj.Outputs.Filename = [obj.fileobj.FileName,obj.fileobj.FileExt];
            end
            obj.Outputs.stads = NRoutputs;
            % Calculate nematic order
            angs = [NRoutputs(:).Orientation];
            [~,obj.Outputs.S_2d] = calc_2D_order(angs);
            
            % Calculate gap statistics and my order parameter
            fitobjs = {obj.Stadium(:).fitobj}';
            cofmasss = cat(1,obj.Stadium(:).cpix);
            
%             for k = 1:numel(obj.Stadium)
%                 stads(k) = obj.fitobj2stad_simple(obj.Stadium(k).fitobj,obj.Stadium(k).cpix);
%             end
%             obj.Outputs.S_R = calc_R_order(size(obj.PreprocIm),stads);
            numNRs = numel(fitobjs);
            if numNRs > 1
                [gaps, sbs_flag, S_R, nrlink_coords] = ...
                    calc_gapstats_from_stads(...
                    size(obj.PreprocIm),fitobjs,cofmasss);
            else
                gaps = NaN;
                sbs_flag = NaN;
                S_R = NaN;
                nrlink_coords = nan(2,2);
            end
            obj.Outputs.N = numNRs;
            obj.Outputs.S_R = S_R;
            obj.Outputs.median_gap = median(gaps);
            T = struct2table(NRoutputs);
            
            % Calculate radius of gyrations
            r0s = [cat(1,NRoutputs(:).x0),cat(1,NRoutputs(:).y0)];
            wghts = cat(1,NRoutputs(:).Area);
            obj.Outputs.R_g = calc_rad_of_gyr(r0s,wghts);
        end
        
        
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% MANIPULATING SEGMENTATION PARMETERS %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set.SegParams(obj,inparams)
            % If nothing is assigned than just assign it, otherwise display
            % which parameters changed
            % ADD STEP TO ENSURE STRUCTURES HAVE THE SAME FIELDS
            if isempty(obj.SegParams)
                obj.SegParams = inparams;
            else
                % Replace the output statement with an Event
                changedparamnames = obj.checkChangedParams(inparams);
                if ~isempty(changedparamnames)
                    obj.wipeImagesAfterParamChange(changedparamnames);
                    obj.SegParams = inparams;
                end
                % Excecute the below if a parameter is changed:
                % Notify a ParamChange event for any listeners
                if ~isempty(changedparamnames)
                    notify(obj,'ParamChange',ToggleEventData(changedparamnames))
                end

            end      
        end
        
        function outrad = autosetbgparams(obj)
            defthd = 0.2;
            tmprad = obj.calcautobgmask(obj.PreprocIm,defthd);
            outrad = tmprad;
            obj.SegParams.r_open1 = tmprad;
            obj.SegParams.thd1 = defthd;
            obj.SegParams.schm_size = tmprad;
        end
        %--- Returns a cell array of the parameter names that have been
        %changed.
        function changedparamnames = checkChangedParams(obj,inparams)
            if isequal(obj.SegParams,inparams)
                changedparamnames = [];
                return
            else
                changedparamnames = {};
                flds = fields(inparams);
                for k = 1:numel(flds)
                    if ~isequal(obj.SegParams.(flds{k}),inparams.(flds{k}))
                        changedparamnames = cat(1,changedparamnames,flds{k});
                    end
                end
            end
        end
        
        %--- For a given change to a parameter, wipe the appropriate
        %images so they can be recalculated.
        function wipeImagesAfterParamChange(obj,changedparamnames)
            if ~isempty(changedparamnames)
                changedImages = values(obj.PARAMTOIMAGEMAP,changedparamnames);
                % Ensure that it is in a cell
                if ~iscell(changedImages)
                    changedImages = {changedImages};
                end
                changedImagesIdx = zeros(size(changedImages));
                for k = 1:numel(changedImages)
                    changedImagesIdx(k) = find(strcmp(changedImages{k},obj.VIEWNAMESVALS));
                end
                % For now, just whipe the earliest image and everything above
                obj.clearImsAtAndAbove(obj.VIEWNAMESVALS{min(changedImagesIdx)});
            end
        end

        %--- Pass a list of image names to clear those images
        function clearIms(obj,varargin)
            for k = 1:numel(varargin)
                obj.(varargin{k}) = obj.DEFIM;
            end
        end
        
        %--- Cascading clearing of images at and above a given substep
        function clearImsAtAndAbove(obj,inname)
            tmpidx = strcmp(inname,obj.VIEWNAMESVALS);
            obj.clearIms(obj.VIEWNAMESVALS{find(tmpidx,1):end});
        end
             
        function set.CropReg(obj,inputval)
        % Override set function for Crop region so that it will reset the
        % preprocessed image. This can be made more complicated in a few
        % ways. 1) use a listener instead of overloading this function. 2)
        % implement a way to keep processed stuff if the new crop region is
        % within the previous
            val = round(inputval);
            % Return from function if it is the same value
            if isequal(obj.CropReg,val)
                return
            end
            if isequal(size(inputval),[1,4]) && isnumeric(inputval(1))
                obj.CropReg = val;
            else
                error('Invalid crop input')
            end
            % Clear the processed image and anything above it
            obj.clearImsAtAndAbove('PreprocIm');
            notify(obj,'CropChange')
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%% HANDLE THE IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %--- Check if a given image is currently stored
        function value = isImLoaded(obj,viewname)
            % Add an alternate path for Stadium
            if strcmp(viewname,'Stadium')
                if isstruct(obj.(viewname))
                    value = true;
                else
                    value = false;
                end
                return
            end
            tmp = size(obj.(viewname));
            if isequal(tmp,[0,0])
                error(['WHY IS ', viewname, ' EMPTY?!'])
            elseif isequal(tmp,size(obj.DEFIM))
                value = false;
            else
                value = true;
            end
        end
        
        %--- Get a specific image (including required cascade)
        function obj = doGetIm(obj, viewname)
            % This requires a cascade effect to get a later image if the
            % earlier on is not yet loaded
            newviewidx = find(strcmp(viewname,obj.VIEWNAMESVALS));
            for k = 1:newviewidx
                if ~obj.isImLoaded(obj.VIEWNAMESVALS{k})
                    obj.doGetIm_simple(obj.VIEWNAMESVALS{k});
                end
            end
        end
        
        %--- Specific view modes for more complicated images
        function outim = viewIm(obj, viewname)
            % If the processed image doesn't exist, do it now
            if ~obj.isImLoaded(viewname)
                obj.doGetIm(viewname);
            end
            switch viewname
                case 'BGMask'
                    outim = obj.BGPreMask;
                case 'WatershedIm'
                    outim = obj.PreprocIm;
                case 'Stadium'
                    outim = obj.PreprocIm;
                otherwise
                    outim = obj.(viewname);
            end
        end
        
        %--- Draw contours on image
        function drawContours(obj, ax, viewname)
            ax; % Switch axes
            % Delete old lines and text?
            lhs = findobj(ax,'Type','line');
            typehs = findobj(ax,'Type','text');
            delete(lhs);
            delete(typehs);
            hold on
            switch viewname
                case 'bgmask'
                case 'watershedim'
                    
                case 'fitcont'
                    tmp = obj.StadiumContour;
                    if isequal(obj.Stadium,0)
                        tmplocs = [NaN,NaN];
                    else
                        tmplocs = cat(1,obj.Stadium(:).cpix);
                    end

                    for k = 1:numel(tmp)
                        plot(tmp{k}(:,2),tmp{k}(:,1),'r','LineWidth',1);
                        text(tmplocs(k,1),tmplocs(k,2),num2str(k),...
                            'Color','r','FontSize',12);
                    end
                case 'none'
                   hold off
                   return
                otherwise
                    error('Contour selection options are bgmask, watershedim, fitcont, or none')
            end
            
            hold off
        end
        
        function numberNRs(obj,ax)
            ax; %switch axes
            if isequal(obj.Stadium,0)
                tmplocs = [NaN,NaN];
            else
                tmplocs = cat(1,obj.Stadium(:).cpix);
            end
            hold on
            for k = 1:size(tmplocs,1)
                text(tmplocs(k,1),tmplocs(k,2),num2str(k),...
                    'Color','r','FontSize',12);
            end
            hold off
        end
            
        
        %-- Override set method for BGMask to recalculate the BGcontours
        
        function set.BGMask(obj,inim)
            obj.BGMask = inim;
            if isequal(size(inim),[1,1])
                obj.setcontours('BGContour',obj.DEFCONTOUR);
            else
                obj.setcontours('BGContour',bwboundaries(inim));
            end
        end
        
        function set.WatershedIm(obj,inim)
            obj.WatershedIm = inim;
            if isequal(size(inim),[1,1])
                obj.setcontours('WatershedContour',obj.DEFCONTOUR);
            else
                obj.setcontours('WatershedContour',bwboundaries(inim > 1));
            end
        end
        
        function set.Stadium(obj, vals)
            obj.Stadium = vals;
            if isequal(vals,0)
                obj.setcontours('StadiumContour', obj.DEFCONTOUR);
            else
                tmpcont =  cell(numel(vals),1);
                angs = (1:360)';
                for k = 1:numel(vals)
                    rhos = stadiumFcn(angs,...
                        vals(k).fitobj.L, ...
                        vals(k).fitobj.R, ...
                        vals(k).fitobj.offset_angle, ...
                        vals(k).fitobj.true_center_x, ...
                        vals(k).fitobj.true_center_y);
                    tmppts = [rhos.*cosd(angs),rhos.*sind(angs)] + vals(k).cpix;
                    tmpcont{k} = fliplr(tmppts);
                end
                obj.setcontours('StadiumContour',tmpcont);
            end
        end
                    
        
        function setcontours(obj,contourname, contourval)
            obj.(contourname) = contourval;
        end
        
        
        %% Dependent Methods
        function value = get.CroppedRawIm(obj)
            if ~obj.isImLoaded('RawIm')
                error('Tried to crop before raw image was loaded')
            end
            croplims = [obj.CropReg(1:2),obj.CropReg(3:4)+obj.CropReg(1:2)-1];
            value = obj.RawIm(croplims(2):croplims(4), croplims(1):croplims(3));
        end
        
        %--- Save and Load Methods
        function s = saveobj(obj)
            s.fileobj = obj.fileobj.saveobj;
            s.RawIm = obj.RawIm;
            s.CropReg = obj.CropReg;
            s.SegParams = obj.SegParams;
            s.ParamMode = obj.ParamMode;
            s.IsThisEmpty = obj.IsThisEmpty;
        end
    end
    
    %% Static Methods include all segmentation functions.
    % Make fundamental changes here.
    methods(Static)
        function obj = loadobj(s)
            if isstruct(s)
                newObj = SegImage;
                newObj.fileobj = filehandler.loadobj(s.fileobj);
                newObj.RawIm = s.RawIm;
                newObj.CropReg = s.CropReg;
                newObj.SegParams = s.SegParams;
                newObj.ParamMode = s.ParamMode;
                newObj.IsThisEmpty = s.IsThisEmpty;
                obj = newObj;
            else
                obj = s;
            end
        end
        
        %--- Preprocess image: Crop and scale intensities to [0,1].
        function outim = preprocim(inim , cropreg)
            if isequal(size(inim,3),3)
                tmpim = rgb2gray(inim);
            else
                tmpim = inim;
            end
            cropbounds = [cropreg(1:2),(cropreg(1:2) + cropreg(3:4) -1)];
            outim = mat2gray(tmpim(...
                cropbounds(2):cropbounds(4),...
                cropbounds(1):cropbounds(3)));
        end
        
        %--- Calculate background premask image.
        function outim = calcbgpremask(inim,rad)
            outim = imopen(inim,strel('disk',rad));
        end
        
        %--- Calculate background mask from premask image.
        function outmask = calcmaskfrombgpre(inim,thd,flt_rad)
            tmpim = inim > thd;
            bgfilt_area = pi*2*flt_rad^2;
            outmask = bwareafilt(tmpim , [bgfilt_area,Inf]);
        end
        
        function outrad = calcautobgmask(inim,thd)
            rads = 1:25;
            N = numel(rads);
            sumvals = nan(N,1);
            % Loop over potential masks to pick the best
            for k = 1:N
                tmpim = SegImage.calcbgpremask(inim,rads(k));
                tmpim = SegImage.calcmaskfrombgpre(tmpim,thd,rads(k));
                sumvals(k) = sum(tmpim(:));
            end
            
            % Use the mask size to determine opening radius
            sumvals = smooth(sumvals);
            diffvect = diff(sumvals)./sumvals(2:end);
            [pks, locs] = findpeaks(diffvect);
            [~,tmp] = max(pks);
            maxids = locs(tmp);
            
            outrad = rads(maxids);
        end
        
        %--- OLD: Calculate background mask.
        function outmask = calcbgmask(inim, rad)
            tmpim = imopen(inim,strel('disk',rad));
            thd = 0.15;
            tmpim = tmpim > thd;
            bgfilt_area = pi*2*rad^2;
            outmask = bwareafilt(tmpim , [bgfilt_area,Inf]);
        end
        
        %--- OLD: Calculates background mask using automatic selection.
        function [outmask,autorad] = autobgmask(inim)
            rads = 1:25;
            N = numel(rads);
            sumvals = nan(N,1);
            % Loop over potential masks to pick the best
            for k = 1:N
                tmpim = SegImage.calcbgmask(inim,rads(k));
                sumvals(k) = sum(tmpim(:));
            end
            
            % Use the mask size to determine opening radius
            sumvals = smooth(sumvals);
            diffvect = diff(sumvals)./sumvals(2:end);
            [pks, locs] = findpeaks(diffvect);
            [~,tmp] = max(pks);
            maxids = locs(tmp);
            
            outmask = SegImage.calcbgmask(inim,rads(maxids));
            autorad = rads(maxids);
        end
        
        %--- Perform sharpening operation on masked image
        function outim = sharpenim(inim, sharp_rad, sharp_str, sharp_thd)
            tmpim = imsharpen(inim,...
                'Radius',sharp_rad,...
                'Amount',sharp_str,...
                'Threshold',sharp_thd);
            outim = tmpim > 0;
        end
        
        %--- Clean sharpened image
        function outim = cleansharpim(inim, erod_rad)
            tmpim = imclose(inim,strel('disk', 1));
            tmpim = imopen(tmpim,strel('disk',2));
            tmpim = imclose(tmpim,strel('disk',3));
            tmpim = imerode(tmpim,strel('disk',erod_rad));
            tmpim = imfill(tmpim,'holes');
            outim = tmpim;
        end
        
        %--- Construct minimum for watershed
        function outmins = minforimposition(bgmask, markers)
            bound_outer = imdilate(bgmask,strel('disk',10));
%             bound_skel = bwmorph(bound_outer & ~markers,'skel',Inf);
            bound_skel = bwskel(bound_outer & ~markers);
            % Clean up skeleton by removing non-closed edges
            neighcount = conv2(bound_skel,ones(3),'same') - bound_skel;
            neighcount(~bound_skel) = Inf;
            while(sum(neighcount(:) <= 1))
                bound_skel(neighcount(:) <= 1) = false;
                neighcount = conv2(bound_skel,ones(3),'same') - bound_skel;
                neighcount(~bound_skel) = Inf;
            end
                
            bgm = imfill(bound_skel,[1,1]);
            outmins = bgm | markers;         
        end
        
        function outlines = linedetect(im,bgmask)
            imsmoo = imgaussfilt(im .* bgmask,2);
            R3 = repmat([-1,2,-1],[3,1]);
            R1 = R3';
            R2 = [-1,-1,2; -1,2,-1; 2,-1,-1];
            R4 = fliplr(R2);

            Rs = -1*cat(3,R1,R2,R3,R4);
            imnew = zeros([size(im),size(Rs,3)]);
            for k = 1:size(Rs,3)
                tmpim = conv2(imsmoo,Rs(:,:,k),'same');
                tmpim(tmpim < 0) = 0;
                imnew(:,:,k) = tmpim;
            end
            lineim = mat2gray(sum(imnew,3));
            lineim_thd = 0.1;
            lineim_adj = lineim - lineim_thd;
            lineim_adj(lineim_adj < 0) = 0;
            
%             inverseim = 1-im;
%             outlineim = lineim_adj > 0;
%             tmpskel = bwskel(outlineim);
%             tmp2 = tmpskel .* inverseim;
            
            
            outlines = lineim_adj;
        end
        
        %--- Perform watershed
        function [outim,gmag] = wtrshd(inim, inmins)
            im_blurred = imgaussfilt(inim,2);
            gmag = imgradient(im_blurred,'Sobel');
            gmag2 = imimposemin(gmag, inmins);
            outim = watershed(gmag2);
        end
        
        function outim = wtrshd_line(inlines, inmins)
            gmag = inlines;
            gmag2 = imimposemin(gmag,inmins);
            outim = watershed(gmag2);
        end
        
        function outconts = wtrshd_contours(inL)
            numnr = max(inL(:)) - 1;
            outconts = cell(numnr,1);
            for k = 1:numnr
                tmpim = inL == k + 1;
                outconts(k) = bwboundaries(tmpim);
            end
        end
        
        %--- Fit with stadium
        function [fitresults,s] = fitwtrshd2stadium(L)
            s = regionprops(L, ...
                'Area','Eccentricity','Centroid','ConvexArea',...
                'Solidity','PixelList','PixelIdxList','Perimeter');
            
            fitresults = struct();
            % Look at on specific nanorod
            wb = waitbar(0,'Calculating stadium fits');
            for k = 2:numel(s)
                BW = false(size(L));
                BW(s(k).PixelIdxList) = true;

                % Get perimeter pixels
                Perim = bwboundaries(BW,8);
                Perim = Perim{1};
                cpix = s(k).Centroid;

                pts = fliplr(Perim);
                cofmass = cpix;
                [fitobj, gof, output] = fitstadium( pts , cofmass );
                fitresults(k-1).fitobj = fitobj;
                fitresults(k-1).cpix = cpix;
                fitresults(k-1).gof = gof;
                fitresults(k-1).output = output;
                waitbar((k-1)/(numel(s)-1),wb);
            end
            close(wb)
        end
        
        function stad = fitobj2stad_simple(fitobj,cpix)
            stad.L = fitobj.L;
            stad.R = fitobj.R;
            stad.theta = fitobj.offset_angle;
            stad.x0 = fitobj.true_center_x + cpix(1);
            stad.y0 = fitobj.true_center_y + cpix(2);
        end
            
    end
    
    %% Protected methods
    methods (Access = protected)
        function obj = doGetIm_simple(obj,viewname)
            switch viewname
                case 'RawIm'
                    obj.fileobj.loadim;
                case 'PreprocIm'
                    obj.PreprocIm = obj.preprocim(obj.RawIm,obj.CropReg);
                case 'BGMask'
                    obj.BGPreMask = obj.calcbgpremask(obj.PreprocIm, obj.SegParams.r_open1);
                    obj.BGMask = obj.calcmaskfrombgpre(...
                                                obj.BGPreMask,...
                                                obj.SegParams.thd1,...
                                                obj.SegParams.schm_size);
                case 'SharpIm'
                    tmpim = zeros(size(obj.BGMask));
                    tmpim(obj.BGMask) = obj.PreprocIm(obj.BGMask);
                    obj.SharpIm = obj.sharpenim(tmpim,...
                        obj.SegParams.sharp_rad,...
                        obj.SegParams.sharp_str,...
                        0);
                        
                case 'CleanIm'
                    tmpim = obj.SharpIm;
                    if obj.SegParams.r_close1
                        tmpim = imclose(tmpim,strel('disk',obj.SegParams.r_close1));
                    end
                    if obj.SegParams.r_open2
                        tmpim = imopen(tmpim,strel('disk',obj.SegParams.r_open2));
                    end
                    if obj.SegParams.r_close2
                        tmpim = imclose(tmpim,strel('disk',obj.SegParams.r_close2));
                    end
                    if obj.SegParams.r_erode1
                        tmpim = imerode(tmpim,strel('disk',obj.SegParams.r_erode1));
                    end
                    tmpim = imfill(tmpim,'holes');
                    obj.CleanIm = tmpim;
                    
                case 'WatershedIm'
                    obj.WatershedIm = obj.wtrshd(obj.PreprocIm,...
                                            obj.minforimposition(...
                                                obj.BGMask, obj.CleanIm));
                case 'Stadium'
                    obj.Stadium = obj.fitwtrshd2stadium(obj.WatershedIm);
                    
                otherwise
                    error([viewname,' image view is not supported'])
            end
        end
    end
end

