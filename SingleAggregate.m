classdef SingleAggregate < matlab.mixin.Copyable & event.EventData & handle 
    %SingleAggregate Defines a single unit consisting of an SEM image and
    %associated parameters
    %   Construct with an input image of an input file location
    
    properties
        SegParams
        IsThisEmpty = false
    end
    
    properties (SetObservable = true)
        RawIm = 0
        CropReg = [1,1,1,1];
        PreprocIm = 0;
        BGPreMask = 0;
        BGContour
        WatershedContour
        SharpIm = 0;
        CleanIm = 0;
        FileName = ''
        FileExt = '.tif'
        LoadPath = ''
        HasLocation = false
        ParamMode
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
        VIEWNAMES = {'Raw Image', 'Preproc.', 'BG mask', 'Sharpening','Cleaning','Watershed'};
        VIEWNAMESVALS = {'RawIm','PreprocIm','BGMask', 'SharpIm','CleanIm','WatershedIm'};
        VIEWNAMESDICT = containers.Map(...
            {'Raw Image', 'Preproc.', 'BG mask','Sharpening','Cleaning','Watershed'},...
            {'RawIm','PreprocIm','BGMask', 'SharpIm','CleanIm','WatershedIm'});
        PARAMTOIMAGEMAP = containers.Map(...
            {...
            'r_open1','thd1','schm_size','sharp_rad','sharp_str',...
            'r_close1','r_open2','r_close2','r_erode1'...
            },{...
            'BGMask','BGMask','BGMask','SharpIm','SharpIm',...
            'CleanIm','CleanIm','CleanIm','CleanIm'...
            });
        DEFPARAMS = struct( 'r_open1', 8, 'thd1',0.15, 'schm_size', 5,...
                            'sharp_rad',5, 'sharp_str',50,...
                            'r_close1',1,'r_open2',2,'r_close2',3,'r_erode1',5); 
    end
    
    events
        CropChange
        ParamChange
    end
    

    
    %% Dynamic Methods
    methods
        %% Constructor
        function obj = SingleAggregate(varargin)
            %Construct an instance of this class
            %   Accepts variable arguments, either images or file names
            switch nargin
                case 0
                    obj = obj.clearAllProps();
                    obj.IsThisEmpty = true;
                case 1
                    %--- SingleAggregate(RawImage)
                    if isnumeric(varargin{1})
                        obj.RawIm = ...
                            SingleAggregate.preprocImage(varargin{1});
                    %--- SingleAggregate(FileLocation)
                    elseif ischar(varargin{1})
                        [obj.LoadPath,obj.FileName,obj.FileExt] = ...
                            fileparts(varargin{1});
                        obj.HasLocation = true;
                    %--- SingleAggregate(instance of SingleAggregate)
                    elseif isequal(class(varargin{1}),'SingleAggregate')
                        obj = copy(varargin{1});
                    else
                        disp('Unknown input. Returning empty SingleAggregate')
                        obj = obj.clearAllProps();
                    end
                case 2
                    if ischar(varargin{1}) && ischar(varargin{2})
                        obj.LoadPath = varargin{1};
                        [~,obj.FileName,obj.FileExt] = fileparts(varargin{2});
                        obj.HasLocation = true;
                    else
                        disp('Unknown input. Returning empty SingleAggregate')
                        obj = obj.clearAllProps();
                    end
                        
                    
                otherwise
                    disp('Unknown input. Returning empty SingleAggregate')
                    obj = obj.clearAllProps();
            end
        end
        
        %% Manipulating Segmentation parameters
        function obj = set.SegParams(obj,inparams)
%             disp('SingleAggregate.set.SetParams')
            % If nothing is assigned than just assign it, otherwise display
            % which parameters changed
            % ADD STEP TO ENSURE STRUCTURES HAVE THE SAME FIELDS
            if isempty(obj.SegParams)
%                 disp('SingleAggregate.SegParams was empty before')
                obj.SegParams = inparams;
            else
                % Replace the output statement with an Event
                changedparamnames = obj.checkChangedParams(inparams);
                if ~isempty(changedparamnames)
                    obj.wipeImagesAfterParamChange(changedparamnames);
%                     disp('SingleAggregate setting within set function')
                    obj.SegParams = inparams;
%                     disp('Done')
                end
                % Excecute the below if a parameter is changed:
                % Notify a ParamChange event for any listeners
                if ~isempty(changedparamnames)
%                     disp(' '); disp('Notification sent from SingleAggregate')
                    notify(obj,'ParamChange',ToggleEventData(changedparamnames))
                end

            end      
        end
        
        function changedparamnames = checkChangedParams(obj,inparams)
        %--- Returns a cell array of the parameter names that have been
        %changed.
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
        
        function obj = wipeImagesAfterParamChange(obj,changedparamnames)
        %--- For a given change to a parameter, wipe the appropriate
        %images so they can be recalculated.
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
    %             imnamelist = obj.VIEWNAMESVALS(min(changedImagesIdx):end);
    %             obj.clearIms(imnamelist{:});
                obj.clearImsAtAndAbove(obj.VIEWNAMESVALS{min(changedImagesIdx)});
            end
        end
                    
        %% Ordinary Methods
        function obj = loadRawIm(obj)
            if obj.HasLocation
                tmpname = [fullfile(obj.LoadPath,obj.FileName), obj.FileExt];
                tmpim = imread(tmpname);
                obj.RawIm = SingleAggregate.preprocImage(tmpim);
                % Set CropReg if not alreayd set
                if isequal(obj.CropReg, [1,1,1,1])
                    obj.CropReg = [1,1,fliplr(size(obj.RawIm))];
                end
            end
        end
        
        function obj = clearAllProps(obj)
            %clearAllProps clears all the properties
%             proplist = properties(obj)
            obj.RawIm = obj.DEFIM;
            obj.LoadPath = '';
            obj.FileName = '';
            obj.HasLocation = false;
        end
        
        function obj = set.CropReg(obj,inputval)
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
            obj.clearProcIms();
            notify(obj,'CropChange')
        end
        
        function obj = clearIms(obj,varargin)
        % Pass it a list of image names to clear those images
            for k = 1:numel(varargin)
                obj.(varargin{k}) = obj.DEFIM;
            end
        end
        
        function obj = clearImsAtAndAbove(obj,inname)
            tmpidx = strcmp(inname,obj.VIEWNAMESVALS);
            obj.clearIms(obj.VIEWNAMESVALS{find(tmpidx,1):end});
        end
        
        function obj = clearProcIms(obj)
            obj.clearIms(obj.VIEWNAMESVALS{2:end});
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%% HANDLE THE IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function value = isImLoaded(obj,viewname)
            tmp = size(obj.(viewname));
            if isequal(tmp,[0,0])
                error(['WHY IS ', viewname, ' EMPTY?!'])
            elseif isequal(tmp,size(obj.DEFIM))
                value = false;
            else
                value = true;
            end
        end
        
        function obj = doGetIm(obj, viewname)
            % This requires a cascade effect to get a later image if the
            % earlier on is not yet loaded
            newviewidx = find(strcmp(viewname,obj.VIEWNAMESVALS));
            for k = 1:newviewidx
                if ~obj.isImLoaded(obj.VIEWNAMESVALS{k})
                    obj.doGetIm_simple(obj.VIEWNAMESVALS{k});
                end
            end
%             obj.doGetIm_simple(viewname);
        end
        
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
                otherwise
                    outim = obj.(viewname);
            end
        end
        
        %-- Override set method for BGMask to recalculate the BGcontours
        function obj = set.BGMask(obj,inim)
            obj.BGMask = inim;
            if isequal(size(inim),[1,1])
%                 obj.BGContour = obj.DEFCONTOUR;
                obj.setcontours('BGContour',obj.DEFCONTOUR);
            else
%                 obj.BGContour = bwboundaries(inim);
                obj.setcontours('BGContour',bwboundaries(inim));
            end
        end
        
        function obj = set.WatershedIm(obj,inim)
            obj.WatershedIm = inim;
            if isequal(size(inim),[1,1])
                obj.setcontours('WatershedContour',obj.DEFCONTOUR);
%                 obj.WatershedContour = obj.DEFCONTOUR;
            else
%                 obj.WatershedContour = bwboundaries(inim > 1);
                obj.setcontours('WatershedContour',bwboundaries(inim > 1));
            end
        end
        
        function obj = setcontours(obj,contourname, contourval)
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
    end
    

    %% Static Methods
    methods (Static)
        function outim = preprocImage(inim)
            if size(inim,3) == 3
                inim = rgb2gray(inim);
            elseif size(inim,3) == 1
                
            else
                error('Trying to format a problem image');
            end
            outim = double(mat2gray(inim));
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function obj = doGetIm_simple(obj,viewname)
            switch viewname
                case 'RawIm'
                    obj.loadRawIm;
                case 'PreprocIm'
                    obj.PreprocIm = SingleAggregate.preprocImage(obj.CroppedRawIm);
                case 'BGMask'
                    tmpim = imopen(obj.PreprocIm,strel('disk',round(obj.SegParams.r_open1)));
                    obj.BGPreMask = tmpim;
                    thd = obj.SegParams.thd1;
                    tmpim = tmpim > thd;
                    bgfilt_area = pi*obj.SegParams.schm_size^2;
                    tmpim = bwareafilt(tmpim , [bgfilt_area,Inf]);
                    obj.BGMask = tmpim;
                case 'SharpIm'
                    tmpim = zeros(size(obj.BGMask));
                    tmpim(obj.BGMask) = obj.PreprocIm(obj.BGMask);
                    im_sharpened = imsharpen(tmpim, ...
                        'Radius', obj.SegParams.sharp_rad, ...
                        'Amount', obj.SegParams.sharp_str);
                    im_sharpened(im_sharpened < 0) = 0;
                    obj.SharpIm = im_sharpened>0;
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
                    obj.CleanIm = tmpim;
                case 'WatershedIm'
%                     markers = obj.CleanIm;
                    bound_outer = imdilate(obj.BGMask,strel('disk',10));
%                     bgm = bwskel(bound_outer & ~obj.CleanIm);
                    bgm = bwmorph(bound_outer & ~obj.CleanIm,'skel',Inf);
                    bgm2 = imfill(bgm,[1,1]);
                    im_masked = zeros(size(obj.BGMask));
                    maskedvals = obj.PreprocIm(obj.BGMask);
                    im_masked(obj.BGMask) = maskedvals - min(maskedvals);
                    im_blurred = imgaussfilt(im_masked,2);
                    gmag = imgradient(im_blurred,'Sobel');
                    gmag2 = imimposemin(gmag,obj.CleanIm | bgm2);
                    obj.WatershedIm = watershed(gmag2);
                    
                otherwise
                    error([viewname,' image view is not supported'])
            end
        end
    end
end

