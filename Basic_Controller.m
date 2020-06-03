function [m,v1] = Basic_Controller()
%Basic_Controller main program

% controller knows about model and view
m = SingleAggregate('X:\Rashad Baiyasi\NRaggregate segmentation\Files from Qingfeng\Image for analysis to Rashad\10222018\BSA\1.tif');
v1 = Basic_Viewer(m);
movegui(v1.fig, 'onscreen');

pause(3)
m.loadRawIm();

end

