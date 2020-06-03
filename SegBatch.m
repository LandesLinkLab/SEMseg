classdef SegBatch < matlab.mixin.Copyable & event.EventData & handle
    %SegBatch stores a group of SegImage instances and the global
    %segmentation parameters   
    
    properties
        Aggs
        GlobalParams
    end
    
    properties (Constant)
        VIEWNAMES = SegImage.VIEWNAMES;
        VIEWNAMESVALS = SegImage.VIEWNAMESVALS;
        VIEWNAMESDICT = SegImage.VIEWNAMESDICT;
        DEFPARAMS = SegImage.DEFPARAMS;
    end
    
    methods
        function obj = SegBatch(varargin)
            if isequal(nargin,0)
                obj.Aggs = {SegImage};
            else
                if isa(varargin{1},'SegImage')
                    obj.Aggs = [varargin{:}];
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
        
        function s = saveobj(obj)
            for k = 1:numel(obj.Aggs)
                s.Aggs(k) = obj.Aggs{k}.saveobj;
            end
            s.GlobalParams = obj.GlobalParams;
            
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
                newobj = SegBatch(aggarray{:});
                newobj.GlobalParams = s.GlobalParams;
                obj = newobj;
            else
                obj = s;
            end
        end
    end
                
end

