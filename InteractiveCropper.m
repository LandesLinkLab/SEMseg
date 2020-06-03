classdef InteractiveCropper < handle
    %InteractiveCropper is an interactive cropping tool
    %   Changes the KeyPressFcn of the parent figure to detect keystrokes
    %   and record rectangle positions. Deleting the InteractiveCropper
    %   resets the KeyPressFcn of the parent figure to the previous
    %   function.
    
    properties
        ax
        r
        StoredKeyPressFcn
        StoredDeleteFcn
        BeingDeleted = false
        ChangedFigState = false
    end
    
    properties (SetObservable = true)
        KeyRecord = '';
        RectPos = [1,1,1,1];
    end
    
    methods
        function obj = InteractiveCropper(in_ax)
            %Input: Target axes handle
            obj.ax = in_ax;
            if isvalid(obj.ax.Parent)
                % Turn off all modes
                zoom off
                pan off
                rotate3d off
                datacursormode off
                brush off
%                 disp('Changing figure stuff');
                % Store old KeyPressFcn and assign new one
                obj.StoredKeyPressFcn = get(obj.ax.Parent,'KeyPressFcn');
                set(obj.ax.Parent,'KeyPressFcn', @obj.recordKeystroke);
                % Update figure delete function and store old one
                obj.StoredDeleteFcn = get(obj.ax.Parent,'DeleteFcn');
                set(obj.ax.Parent,'DeleteFcn', @obj.FigDeleteFcn)
%                 set(obj.ax.Parent,'CloseRequestFcn', @obj.FigDeleteFcn);
                obj.ChangedFigState = true;
            end
            % Create and imrect object
            obj.r = imrect(obj.ax);
        end
        
        function recordKeystroke(obj, fig, keydata)
%             disp(obj)
%             disp(fig)
%             disp(keydata)
            try
                obj.RectPos = obj.r.getPosition;
                obj.KeyRecord = keydata;
            catch
                
            end
        end
        
        function delete(obj)
            
%             disp('deleting IC')
            obj.BeingDeleted = true;
%             if isvalid(obj.ax.Parent)
            try
                set(obj.ax.Parent,'KeyPressFcn',obj.StoredKeyPressFcn);
                set(obj.ax.Parent,'DeleteFcn',obj.StoredDeleteFcn);
%                 set(obj.ax.Parent,'CloseRequestFcn','closereq');
%             end
            catch
            end
            delete(obj.r);
        end
        
        function FigDeleteFcn(obj,~,~)
%             disp('deleting object first')
            delete(obj)
%             delete(obj.ax.Parent)
        end
%         function el = getaddlistener(obj)
%             el = addlistener(obj,'RectPos','PostSet',@(src,eventData)disp(obj.RectPos));
%         end
    end
end

