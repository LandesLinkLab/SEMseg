classdef ImageDisplayer < handle
    %ImageDisplayer sits between the Batch object and the Controller/Viewer
    %   Detailed explanation goes here
    
    properties
        Batch
        ParamParams
        SegParams
%         ParamModeList
    end
    
    properties (SetObservable = true, AbortSet = true)
        CurrentState
        FocusIdx = 1
        ViewMode = 'RawIm';
    end
    
    properties (Dependent, SetObservable = true)
        ParamModeList
    end
    
    properties (Dependent)
        CurrentView
        NumAggs
        CurrentParams
        CurrentSegParams
        FocusSegParamsStruct
        CurrentAgg
        ParamMode
        GlobalParams
    end
    
    properties (Constant)
        VIEWNAMES = SegImage.VIEWNAMES;
        VIEWNAMESVALS = SegImage.VIEWNAMESVALS;
        VIEWNAMESDICT = SegImage.VIEWNAMESDICT;
        DEFPARAMS = SegImage.DEFPARAMS;
    end
    
    events
        RefreshTriggered
    end
    
    %% Dynamic Methods
    methods
        function obj = ImageDisplayer(Batch)
            %Construct an instance of this class
            obj.Batch = Batch;
            obj.initSegParams;
        end
        
        function reload_batch(obj,Batch)
            obj.Batch = [];
%             obj.ParamParams = [];
%             obj.SegParams = [];
            % Attempting a hax fix for now
            
            for k = 1:Batch.NumAggs
                storedsegparams(k) = Batch.Aggs{k}.SegParams;
            end
            
            obj.Batch = Batch;
        % Deal with SegParams
            batchsegparams = SegmentationParameters(Batch.GlobalParams);
            for k = 1:obj.NumAggs
                obj.addToSegParams(k,batchsegparams);
            end
            for k = 1:obj.NumAggs
                % TODO - Maybe don't refer all the way down to the
                % aggregates for this, since I don't want too much
                % cross-pollinating. Could make methods in BatchAggregate.
%                 if obj.Batch.Aggs{k}.IsThisEmpty
                    obj.SegParams(k).single = SegmentationParameters(...
                                        obj.Batch.Aggs{k}.SegParams);
%                 end
            end
            obj.FocusIdx = 1;
            obj.triggerRefresh;
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% FOCUS CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %--- Change the focus of the batch
        function obj = changeFocus(obj,newidx)
            if newidx > obj.NumAggs
                newidx = newidx - obj.NumAggs;
            elseif newidx < 1
                newidx = obj.NumAggs + newidx;
            else
                
            end
            obj.FocusIdx = newidx;
        end
        
        function triggerRefresh(obj)
            notify(obj,'RefreshTriggered');
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%% PARAMETER CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %--- Initialize the structure array with shared handles for 'batch'
        %and nothing for 'single' 
        function obj = initSegParams(obj,varargin)
            % SegParams is a structure array containing references to
            % segmentation parameters
            % In order to pass a set of parameters here you must use the 
            % appropriate structure.
            
            % UPDATE HERE - to include aggregate handles for swapping
            % between stored images later.
            
            switch nargin
                case 1
                    inparams = obj.DEFPARAMS;
                case 2
                    inparams = varargin{1};
                otherwise
                    error('Does not support non-structure parameter input')
            end
            batchsegparams = SegmentationParameters(inparams);
            for k = 1:obj.NumAggs
                obj.addToSegParams(k,batchsegparams);
            end
            obj.initParamParams;
        end
        
        function obj = addToSegParams(obj,k,batchsegparams)
            obj.SegParams(k).batch = batchsegparams; % Shared handle
            obj.SegParams(k).single = []; % Empty initially
%             obj.ParamModeList{k} = 'batch';
        end

        function obj = deleteSegParams(obj,k)
            obj.SegParams(k) = [];
        end
        %--- Set the parameters for the different parameters
        %%%%%%%%% UPDATE HERE FOR NEW PARAMETERS %%%%%%%%%%%
        function obj = initParamParams(obj)
            % Opening radius for BG removal
            tag = 'r_open1';
            minval = 1;
            maxval = 50 + minval;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            % Pass the BatchAggregate and two structures (slider and edit)
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            % Threshold cuttoff for binarizing
            tag = 'thd1';
            minval = 0;
            maxval = 1;
            slstep = [0.01,0.1];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            
            % Shmutz size filtering
            tag = 'schm_size';
            minval = 0;
            maxval = 50;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            
            % Sharpening radius
            tag = 'sharp_rad';
            slstep = [0.1,2];
            minval = slstep(1);
            maxval = 50;
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            
            % Sharpening strength
            tag = 'sharp_str';
            minval = 0;
            maxval = 100;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            
            % Cleaning closing 1
            tag = 'r_close1';
            minval = 0;
            maxval = 40;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            
            % Cleaning opening
            tag = 'r_open2';
            minval = 0;
            maxval = 40;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            
            % Cleaning closing 2
            tag = 'r_close2';
            minval = 0;
            maxval = 40;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
            % Cleaning closing 2
            tag = 'r_erode1';
            minval = 0;
            maxval = 40;
            slstep = [1,2];
            startval = obj.DEFPARAMS.(tag);
            obj.ParamParams.(tag) = ParameterInterfacer(obj,...
                struct('Tag',tag,'Min',minval,'Max',maxval,...
                'SliderStep',slstep/(maxval-minval),'Value',startval),...
                struct('Tag',tag,'String',num2str(startval),'Value',startval)...
                );
        end
        
        %--- Get the SegParams struct for the current FocusIndex
        function segparams = get.FocusSegParamsStruct(obj)
            segparams = obj.SegParams(obj.FocusIdx);
        end
        
        %--- Get the SegParams object for the focus and the parammode
        function segparams = get.CurrentSegParams(obj)
            segparams = obj.FocusSegParamsStruct.(obj.ParamMode);
        end
        
        %--- Get the current parameters based on what view we are using
        function params = get.CurrentParams(obj)
            switch obj.ParamMode
                case 'batch'
                    params = obj.FocusSegParamsStruct.batch.CurrentParams;
                case 'single'
                    % If there hasn't been a single aggregate parameter
                    % structure assigned yet, do it now
                    if isempty(obj.FocusSegParamsStruct.single)
                        obj.SegParams(obj.FocusIdx).single = ...
                            SegmentationParameters(...
                            obj.FocusSegParamsStruct.batch.CurrentParams);
                    end
                    params = obj.FocusSegParamsStruct.single.CurrentParams;
                otherwise
                    error('Does not support non-structure parameter input')
            end
        end
        
        function obj = setViewParams(obj)
            obj.CurrentAgg.SegParams = obj.CurrentParams;
        end
        
        %--- Excecute 'refactor' method in the ParameterInterfacer objects
        function obj = refactorSegParams(obj)
            paramlist = fields(obj.ParamParams);
            for k = 1:numel(paramlist)
%                 disp('ImageDisplayer.refactorSegParams')
                obj.ParamParams.(paramlist{k}).refactorUIcomponents();
            end
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% BATCH MANAGEMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addAgg(obj,newAgg)
            if isa(newAgg,'SegImage')
                obj.Batch.addAgg(newAgg);
                obj.addToSegParams(obj.NumAggs,obj.FocusSegParamsStruct.batch);
%                 notify(obj,'RefreshTriggered')
            else
                return
            end
        end
        
        
        function subAgg(obj, idx)
            obj.Batch.subAgg(idx);
            obj.deleteSegParams(idx);
            if obj.FocusIdx > obj.NumAggs
                obj.FocusIdx = obj.NumAggs;
            end
            obj.triggerRefresh;
        end
        
        function subCurrAgg(obj)
%             if obj.NumAggs == 1
%                 msgbox('Can''t remove last aggregate');
%                 return
%             end
            obj.subAgg(obj.FocusIdx);
        end
    
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% DEPENDENT PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function im = get.CurrentView(obj)
        % grab the appropriate image from the Batch
            obj.CurrentAgg.SegParams = obj.CurrentParams;
            im = obj.CurrentAgg.viewIm(obj.ViewMode);
        end
        
        function agg = get.CurrentAgg(obj)
            agg = obj.Batch.Aggs{obj.FocusIdx};
        end
        
        function val = get.NumAggs(obj)
%             val = numel(obj.Batch.Aggs);
            val = obj.Batch.NumAggs;
        end
        
         %--- Carry ParamModeList dependency through from BatchAggregate
        function vals = get.ParamModeList(obj)
            vals = obj.Batch.ParamModeList;
        end
        
        function set.ParamModeList(obj,invals)
            obj.Batch.ParamModeList = invals;
        end
        
        function val = get.ParamMode(obj)
            tmpval = obj.ParamModeList(obj.FocusIdx);
            if tmpval
                val = 'batch';
            else
                val = 'single';
            end
        end     
        
        function set.ParamMode(obj,val)
            logval = strcmp(val,'batch');
            obj.ParamModeList(obj.FocusIdx) = logval;
            obj.CurrentAgg.SegParams = obj.CurrentParams;
        end

    end
    
    %% Protected Methods (Not protected anymore)
%     methods (Access = protected)
    methods
        function resetSingleToBatchParams(obj)
        %--- Be careful using this method, as it will completely wipe the
        %previous saved states of the single aggregate.
%             obj.FocusSegParamsStruct.single = SegmentationParameters(...
%                                 obj.FocusSegParamsStruct.batch.CurrentParams);
            if ~isempty(obj.SegParams(obj.FocusIdx).single)
                obj.SegParams(obj.FocusIdx).single.CurrentParams =...
                    obj.SegParams(obj.FocusIdx).batch.CurrentParams;
            end
        end
    end
end

