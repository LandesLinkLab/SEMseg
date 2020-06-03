function dcm_obj = activate_datacursoridx(fig_handle)
% Summary of this function goes here
%   Detailed explanation goes here
if nargin == 0
    fig_handle = gcf;
end

dcm_obj = datacursormode(fig_handle);
dcm_obj.UpdateFcn = @datacursor_index;
