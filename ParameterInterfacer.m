classdef ParameterInterfacer < handle
    %ParameterInterfacer connects the set of UI controls for a parameter 
    % and the ImageDisplayer object.
    %   Initialize within ImageDisplayer object with the values that will
    %   be used to set relevant parameters in a slider and edit text box
    %   that will be passed once the Viewer is initialized.
    
    properties
        ImDisp
        SliderParams
        EditTxtParams
        Sldr
        EditTxt
        Name
    end
    
    methods
        function obj = ParameterInterfacer(ImDisp,SliderParams,EditTxtParams)
            %Construct by passing the parent Aggregate and two structures
            %contatining the parameter parameters for a slider and and edit
            %text box.
            obj.ImDisp = ImDisp;
            obj.SliderParams = SliderParams;
            obj.EditTxtParams = EditTxtParams;
            obj.Name = obj.SliderParams.Tag;
        end
        
        function obj = linkSubPanel(obj,pnl)
            % Pass a subpanel holding a slider and edit textbox to give
            % them their appropriate callbacks
            chs = allchild(pnl);
            sldr = findobj(chs,'Style','slider');
            edittxt = findobj(chs,'Style','edit');
            
            if ~isempty(edittxt) && ~isempty(sldr)
                obj.linkSliderAndEditTxt(sldr,edittxt);
            else
                error('Panel does not contain slider and edit textbox')
            end
        end
        
        function obj = linkSliderAndEditTxt(obj,sldr,edittxt)
            %Pass slider and edit textbox handles to give them callbacks
            obj.Sldr = sldr;
            obj.setUIparams(obj.Sldr,obj.SliderParams);
            set(obj.Sldr,'Callback',{@obj.sldr_callback,obj.ImDisp});
            obj.EditTxt = edittxt;
            obj.setUIparams(obj.EditTxt,obj.EditTxtParams);
            set(obj.EditTxt,'Callback',{@obj.edittxt_callback,obj.ImDisp});
        end
        
        function sldr_callback(obj,src,event,ImDisp)
        %--- Excecute on slider callback
            sldr = src;
            validstepsize = sldr.SliderStep(1)*(sldr.Max-sldr.Min);
            val = src.Value;
            newval = ParameterInterfacer.makeValidSlideVal(val,sldr,validstepsize);
            src.Value = newval;
            edittxt = findobj(src.Parent,'style','edit');
            set(edittxt,'String',num2str(newval),'Value',newval);
            ImDisp.CurrentSegParams.CurrentParams.(src.Tag) = newval;
            ImDisp.setViewParams;
            
%             ImDisp.CurrentSegParams.CurrentParams.(src.Tag)
        end
        
        function edittxt_callback(obj,src,event,ImDisp)
        %--- Excecute on edit textbox callback
            sldr = obj.Sldr;
            validstepsize = sldr.SliderStep(1)*(sldr.Max-sldr.Min);
            [num,status] = str2num(src.String);
            if status
                sldr.Value = ParameterInterfacer.makeValidSlideVal(num,sldr,validstepsize);
                src.String = num2str(sldr.Value);
                ImDisp.CurrentSegParams.CurrentParams.(src.Tag) = sldr.Value;
                ImDisp.setViewParams;
            else
                src.String = num2str(sldr.Value);
            end     
        end
           
        function setUIparams(obj,src,inparams)
        %--- Set parameters for UI components using a set of input
        %parameters.
            paramnames = fields(inparams);
            for k = 1:numel(paramnames)
                src.(paramnames{k}) = inparams.(paramnames{k});
%                 [src.Tag, num2str(src.Value)]
%                 src
            end
        end
        
        function refactorUIcomponents(obj)
        %--- Refactor UI components using the working parameters in the
        %ImageDisplayer
            src = obj.Sldr;
            newval = obj.ImDisp.CurrentParams.(src.Tag);
            if ~isequal(src.Value,newval)
                src.Value = newval;
                obj.sldr_callback(src,[],obj.ImDisp);
            end
        end
            
    end
    methods (Static)
        function outnum = makeValidSlideVal(num,sldr,validstepsize)
        %--- Use the internal parameters of the UI slider to return a legal
        %value for a given parameter.
            if num > sldr.Max
                outnum = sldr.Max;
            elseif num < sldr.Min
                outnum = sldr.Min;
            else
                if nargin > 2
                    % Update it by moving it to the closest step value
                    modval = mod(num,validstepsize);
                    posstep = [modval,validstepsize-modval];
                    [minval,minidx] = min(posstep);
                    % This automatically applys the correct direction for the step
                    outnum = num + minval*(minidx-1.5)*2;
                else
                    outnum = num;
                end
            end
            if num > sldr.Max
                outnum = sldr.Max;
            elseif num < sldr.Min
                outnum = sldr.Min;
            end
        end
    end
end

