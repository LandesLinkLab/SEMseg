classdef BatchAggregate < handle
    %BatchAggregate holds a group of SegImage objects
    %   Detailed explanation goes here
    
    properties
        Aggs
        GlobalParams
        PrevDefCrop = [];
    end
    
    properties (AbortSet = true)
        DefCrop = [0,0,0,0];
    end
    
    properties (Dependent, SetObservable = true)
        ParamModeList
        NumAggs
    end
    
    properties (Constant)
        VIEWNAMES = SegImage.VIEWNAMES;
        VIEWNAMESVALS = SegImage.VIEWNAMESVALS;
        VIEWNAMESDICT = SegImage.VIEWNAMESDICT;
        DEFPARAMS = SegImage.DEFPARAMS;
    end
    
    %% Dynamic Methods
    methods
    %% Constructor
        function obj = BatchAggregate(varargin)
            %Construct an instance of this class
            % Input is a SegImage object
            if isequal(nargin,0)
                obj.Aggs = {SegImage};
            else
                if isa(varargin{1},'SegImage')
%                     obj.Aggs = [varargin{:}];
                    obj.Aggs = varargin;
                elseif ischar(varargin{1})
                    % Improve parsing here for more complex sets of inputs
                    for k = 1:numel(varargin)
                        obj.Aggs{k} = SegImage(varargin{k});
                    end
                end
            end
            % Segmentation parameters
            obj.GlobalParams = obj.DEFPARAMS;
            % Set aggregate parameters to global values if they have global
            % as true
            for k = 1:numel(obj.Aggs)
                if obj.Aggs{k}.ParamMode % True for global
                    obj.Aggs{k}.SegParams = obj.GlobalParams;
                end
            end
        end
        
        %--- Keep track of the param mode for each SegImage
        function vals = get.ParamModeList(obj)
            vals = cellfun(@(xxx) xxx.ParamMode, obj.Aggs);
        end
        
        function val = get.NumAggs(obj)
            val = numel(obj.Aggs);
        end
        
        %--- Set ParamMode values
        function set.ParamModeList(obj,invals)
            invals = logical(invals);
            for k = 1:numel(invals)
                obj.Aggs{k}.ParamMode = invals(k);
            end
        end
        
        %--- Set DefCropMode
        function set.DefCrop(obj,inval)
            if ~isequal([1,4],size(inval))
                return
            else
                obj.updatePrevDefCrop;
                obj.DefCrop = inval;
            end
        end
                
        %--- Update crop regions for appropriate Aggs
        function updateCropRegs2Def(obj,updatemode)
            % Loop over each aggregate and update
            for k = 1:obj.len
                agg = obj.Aggs{k};
                imsz = size(agg.RawIm);
                fullreg = [1,1,fliplr(imsz(1:2))];
                switch updatemode
                    case 'fullonly'
                        updateflag = isequal(agg.CropReg,fullreg);
                    case 'fullandprev'
                        updateflag = isequal(agg.CropReg,fullreg) || isequal(agg.CropReg,obj.PrevDefCrop);
                    case 'all'
                        updateflag = true;
                    otherwise
                        error('Must specify an update mode for crop regs')
                end
                if updateflag
                    agg.CropReg = obj.DefCrop;
                end
            end
        end
    %% Ordinary Methods
        % Functions for adding and removing an aggregate. Should include
        % some overall updating to the system eventually
        function addAgg(obj,newAgg)
            if isequal(numel(obj.Aggs),1) && obj.Aggs{1}.IsThisEmpty
                obj.Aggs = {};
            end
            if isa(newAgg,'SegImage')
                % Determine the best direction to append
                [rs,cs] = size(obj.Aggs);
                if isequal(rs,cs)
                    appenddir = 1;
                else
                    [~,appenddir] = max([rs,cs]);
                end
                obj.Aggs = cat(appenddir,obj.Aggs,{newAgg});
            else
                error('Tried to add something that wasn''t a single aggregate');
            end
            % Try setting to the default crop
            if ~isequal(obj.DefCrop,[0,0,0,0])
                % Check if it is a valid crop size
                if BatchAggregate.isValidCrop(newAgg,obj.DefCrop)
                    newAgg.CropReg = obj.DefCrop;
                end
            end
        end
        
        %--- Pop Aggregate out from the aggregate list
        function remagg = subAgg(obj,idx)
            if idx > 0 && idx <= numel(obj.Aggs)
                remagg = obj.Aggs{idx};
                obj.Aggs(idx) = [];
            else
                error('Tried to remove invalid aggregate')
            end
        end
        
        function s = saveobj(obj)
            for k = 1:numel(obj.Aggs)
                s.Aggs(k) = obj.Aggs{k}.saveobj;
            end
            
            s.GlobalParams = obj.GlobalParams;
            s.DefCrop = obj.DefCrop;
            s.PrevDefCrop = obj.PrevDefCrop;
        end
        
        %--- Get the length of the the group of aggregates
        function val = len(obj)
            val = numel(obj.Aggs);
            % check if there is only one empty aggregate
            if isequal(val,1)
                if obj.Aggs{1}.IsThisEmpty
                    val = 0;
                end
            end
        end

    end
    
    methods(Access = protected)
        function updatePrevDefCrop(obj)
            obj.PrevDefCrop = obj.DefCrop;
        end
    end
    
    methods(Static)
        function obj = loadobj(s)
            if isstruct(s)
                % Reconstitute the aggregates first into a cell array
                aggarray = cell(1,numel(s.Aggs));
                for k = 1:numel(s.Aggs)
                    aggarray{k} = SegImage.loadobj(s.Aggs(k));
                end
                % Use aggregates for SegBatch construction
                newobj = BatchAggregate(aggarray{:});
                newobj.GlobalParams = s.GlobalParams;
                try
                    newobj.DefCrop = s.DefCrop;
                    newobj.PrevDefCrop = s.PrevDefCrop;
                catch
                    disp('Save does not contain default crop values')
                end
                obj = newobj;
            else
                obj = s;
            end
        end

    
    %--- validating a cropreg for a given agg
        function valflag = isValidCrop(agg,cropreg)
            %TODO - see if we need to subtract or add 1 from the cropreg
            %size
            imsz = size(agg.RawIm);
            imsz = fliplr(imsz(1:2)); % Ignore 3rd dimension
            cropsz = cropreg(1:2) + cropreg(3:4) - 1;
            valvec = [cropreg(1:2) >= 1,cropsz <= imsz];
            valflag = sum(valvec)==4;
        end
    end
end

