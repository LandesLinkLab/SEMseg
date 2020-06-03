classdef (ConstructOnLoad) ToggleEventData < event.EventData
   properties
      NewState
   end
   
   methods
      function data = ToggleEventData(newState)
         data.NewState = newState;
      end
   end
end
