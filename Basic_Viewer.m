function handles = Basic_Viewer(m)
%Basic_Viewer Controls view of SingleAggregate object
handles = initGUI();
handles.DEFPATH = 'X:\Rashad Baiyasi\NRaggregate segmentation\Files from Qingfeng\Image for analysis to Rashad\10222018\BSA\';
onChangedF(handles, m);

h1 = event.proplistener(m, findprop(m,'RawIm'), 'PostSet', ...
    @(o,e) onChangedF(handles, e.AffectedObject));
setappdata(handles.fig, 'proplistener', h1);
end

function handles = initGUI()
% load FIG file
hFig = hgload('nrsegGUI_v1.fig');
% hFig = openfig('nrsegGUI_v1.fig');

% extract handles to GUI components
hAx = findobj(hFig, 'tag','axes1');
% set(hAx,'XLimMode','auto','YLimMode','auto','DataAspectRatioMode','manual');
% hSlid = findobj(hFig, 'tag','slider1');
hTxt = findobj(hFig, 'tag','txtbx_axis1');
hMenu = findobj(hFig, 'tag','cmenu1');
hMenuItem = findobj(hFig, 'type','uimenu');
hToolbar = findobj(hFig, 'tag', 'uitoolbar1');

setToolbarCallback(hToolbar);

hImag = imagesc(0,'Parent',hAx);
set(hImag, 'uicontextmenu', hMenu);

% return a structure of GUI handles
handles = struct('fig',hFig, 'ax',hAx, 'image',hImag,...
    'menu',hMenu, 'txt',hTxt, 'toolbar',hToolbar);
end

function onChangedF(handles,model)
    set(handles.image, 'CData',model.RawIm);
    handles.ax.XLimMode = 'auto';
    handles.ax.YLimMode = 'auto';
    set(handles.txt, 'String', model.FileName);
end