classdef (ConstructOnLoad) SegmentationParameters < handle & event.EventData
    %Object that stores the segmentation parameters for an aggregate 
    %(Single or Batch) and handles undo states.
    
    properties
        StartingParams
        SavedParams = [];
        NumSavedParams = 5
        CurrentParamIdx = 0
        IsEmpty = true
    end
    
    properties (SetObservable = true, Access = private)
        WorkingParams
    end
    
    properties (Dependent)
        CurrentParams
        CurrentView
    end
    
    events
        ParamChange
    end
    
    methods
        %--- Construct an instance of SegmentationParameters class
        function obj = SegmentationParameters(inParams)
            %   Input is cell array of segmentation parameters. If no
            %   parameters are passed, initialize as an empty object.
            if nargin == 1
                obj.initSegParams(inParams);
            end
        end
        
        %--- Initialize segmentation parameters using an input structure
        function obj = initSegParams(obj,inParams)
            obj.StartingParams = inParams; % Keep original for reverting
            obj.WorkingParams = inParams;
            obj.SavedParams = inParams; % Save the initial state for undo
            obj.IsEmpty = false; % Mark this object as no longer empty
        end
        
        %--- Store the working state in the saved states
        function obj = cacheParams(obj)
            % Store the current parameter and truncate the set of saved
            % parameters.
            if isequal(obj.WorkingParams,obj.SavedParams(1))
                return % Don't cache if the values are the same
            end
            % If we are currently in an undo state, get rid of the forward
            % states before caching.
            if ~isequal(obj.CurrentParamIdx,0)
                obj.SavedParams(1:obj.CurrentParamIdx) = [];
                obj.CurrentParamIdx = 0;
            end
            obj.SavedParams = cat(1,obj.WorkingParams, obj.SavedParams);
            obj.SavedParams = obj.SavedParams(1:obj.NumSavedParams);
        end
        
        %--- Navigating through the saved states
        function obj = stepThroughSavedParams(obj,inc)
            newIdx = obj.CurrentParamIdx + inc;
            if isequal(newIdx,0) % Move back to top level
                obj.CurrentParamIdx = 0;
            elseif newIdx < 0 || newIdx > min(obj.NumSavedParams,numel(obj.SavedParams))
                % Don't allow the time step to move outside the number of
                % active states
                return
            else
                obj.CurrentParamIdx = newIdx;
                obj.WorkingParams = obj.SavedParams(obj.CurrentParamIdx);
            end
        end
        
        %--- Return whatever parameters are currently active
        function outputval = get.CurrentParams(obj)
            if isequal(obj.CurrentParamIdx,0)
                outputval = obj.WorkingParams;
            else
                outputval = obj.SavedParams(obj.CurrentParamIdx);
            end
        end
        
        %--- Only set the working parameters if they have changed
        function set.CurrentParams(obj,inparams)
            if isempty(obj.WorkingParams)
                obj.WorkingParams = inparams;
                return
            end
            fs = fields(inparams);
            changedflag = false;
            for k = 1:numel(fs)
                if ~isequal(obj.WorkingParams.(fs{k}),inparams.(fs{k}))
                    changedflag = true;
                    break
                end
            end
            if changedflag
                obj.WorkingParams = inparams;
%                 obj.setWorkingParams(fs{k});
            end
        end
        
    end
    
    %--- Notify Viewer of changed parameter
    methods (Access = protected)
        function setWorkingParams(obj,paramname)
            disp('Notify SegParam')
            notify(obj,'ParamChange',ToggleEventData(paramname))
        end
    end
end

