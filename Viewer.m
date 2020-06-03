function handles = Viewer(m)
    %Pass an ImageDisplayer object to open GUI. Returns graphics handles.
    % INPUT: 
    %   m - ImageDisplayer object
    % OUTPUT:
    %   handles - Struct containing graphics handles
    
    %--- Initialize GUI and return handles for each graphics object
    handles = initGUI();

    %--- Activate toolbar and rewrite some callbacks
    handles.fig.ToolBar = 'figure';
    handles.toolbar = findall(handles.fig,'tag','FigureToolBar');
    %--- Set Callbacks
    setToolbarCallback(handles);
    
    %--- Assign model-dependent values to objects
    set(handles.viewpopup, 'String',m.VIEWNAMES);
    
    %--- Menu controls
    % File
        % Set Default Crop
        handles.menu.file.defcrop = findobj(handles.fig,'tag','menu_defcrop');

    %--- Initial refresh of display and button panels
        %--> MOVED TO CONTROLLER

    %--- Listeners: Set callbacks for change in focus, view, crop, and
    %               parameters.
        %--> MOVED TO CONTROLLER
    
    %--- Collect objects to hide during cropping
    hideables = findobj(handles.fig,'style','pushbutton');
    hideables = cat(1,hideables,findobj(handles.fig,'Type','uibuttongroup'));
    hideables = cat(1,hideables,findobj(handles.fig,'Type','uipanel'));
    hideables = cat(1,hideables,handles.toolbar);
    
    handles.hideables = hideables;
    
end
% --- Initialization function loads figure and gets graphics object handles
function handles = initGUI()
    % Load up Matlab figure
    hFig = hgload('nrsegGUI_v3.fig');
    % Update close figure callback
%     set(hFig,'CloseRequestFcn',@warningCloseRequestFcn);
    
    %--- Basic figure components (menus, toolbars, etc.)
    hMenu = findobj(hFig, 'tag','cmenu1');
    hMenuItem = findobj(hFig, 'type','uimenu');
    hToolbar = findobj(hFig, 'tag', 'uitoolbar1');
    hCusToolbar = findobj(hFig,'tag','custom_toolbar');

    %--- Axes: Manually specify DataAspectRatio and ActivePositionProperty
    hAx = findobj(hFig, 'tag','axes1');
    set(hAx,'DataAspectRatio',[1,1,1])
    set(hAx,'ActivePositionProperty','outerposition')
    %--- Textbox (axis1)
    hTxt = findobj(hFig, 'tag','txtbx_axis1');
    %--- Image (axis1): Initialize as empty
    hImag = imagesc([],'Parent',hAx);
    set(hImag, 'uicontextmenu', hMenu);
    %--- Navigation
    hNav.pushbutton_next = findobj(hFig,'Tag','pushbutton_next');
    hNav.pushbutton_prev = findobj(hFig,'Tag','pushbutton_prev');
    hNav.pushbutton_add = findobj(hFig,'Tag', 'addagg_btn');
    hNav.pushbutton_sub = findobj(hFig,'Tag', 'subagg_btn');
    hNav.numaggs_txt = findobj(hFig,'Tag','numaggs_txt');
    hNav.focusidx_txt = findobj(hFig,'Tag','focusidx_txt');
    
    %--- Static panel: Cropping
    hPanel.crop = findobj(hFig, 'tag', 'uipanel_crop');
    %--- Cropping controls
    hCrop.crop = findobj(hFig, 'tag', 'pushbutton_crop');
    hCrop.reset = findobj(hFig,'tag','pushbutton_resetcrop');
    
    
    %--- Static panel: Toggle display of contours
    hContourViewPanel = findobj(hFig, 'tag', 'uibuttongroup_viewcontours');
    
    %--- Switch panels: Control view and parameter inputs
    hViewPopup = findobj(hFig,'tag','popupmenu_view');
    % Panels that will change visibility based on the selected view mode.
    % Must be in same order as the members of the Popup menu
    % 1. RawIm
    % 2. PreprocIm
    % 3. BGMask
    % 4. SharpIm
    % 5. CleanIm
    % 6. MarkerIm
    hSwitchPanel(1) = findobj(hFig,'tag', 'uipanel_rawim');
    hSwitchPanel(2) = findobj(hFig,'tag', 'uipanel_preproc');
    hSwitchPanel(3) = findobj(hFig,'tag', 'uipanel_bgmask');
    hSwitchPanel(4) = findobj(hFig,'tag','uipanel_sharpen');
    hSwitchPanel(5) = findobj(hFig,'tag','uipanel_clean');
    hSwitchPanel(6) = findobj(hFig,'tag','uipanel_watershed');
    hSwitchPanel(7) = findobj(hFig,'tag','uipanel_fitting');

    %--- Global vs custom parameters radio button
    hGlobalParamsToggle = findobj(hFig, 'tag', 'togglebutton_parammode');
    hResetCustomButton = findobj(hFig, 'tag', 'pushbutton_resetParams');
    %--- Output button
%     hCalcStad = findobj(hFig,'tag','fit_button');
    hGetOutputButton = findobj(hFig,'tag','getoutput_button');
    hGetAllOutputButton = findobj(hFig,'tag','getalloutput_button');
%     hOutput.fitcont  = hCalcStad;
    hOutput.getoutput = hGetOutputButton;
    hOutput.getalloutput = hGetAllOutputButton;
    
    % Create a structure containing the GUI handles
    handles = struct(...
        'fig' , hFig,...
        'ax' , hAx,...
        'image' , hImag,... % 'menu' , hMenu,...
        'txt' , hTxt,...
        'toolbar' , hToolbar,...
        'custoolbar',hCusToolbar,...
        'viewpopup' , hViewPopup,...
        'panel' , hPanel ,...
        'croptools' , hCrop,...
        'switchpanel' , hSwitchPanel,...
        'globalradio' , hGlobalParamsToggle,...
        'resetparams',hResetCustomButton,...
        'contourspanel' , hContourViewPanel,...
        'nav' , hNav,...
        'output',hOutput);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%  SET CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = setToolbarCallback(handles)
    % This is important for disabling save callback to avoid messing with the
    % default figure
    hToolbar = findall(handles.fig,'tag','FigureToolBar');
    hSaveButton = findall(hToolbar, 'tag', 'Standard.SaveFigure');
    hOpenButton = findall(hToolbar, 'tag', 'Standard.FileOpen');
    set(hSaveButton,'ClickedCallback','msgbox(''Save is not supported yet'',''Sorry'')');
    set(hOpenButton,'ClickedCallback','msgbox(''Open is not supported yet'',''Sorry'')');
end

function warningCloseRequestFcn(hObject,eventdata)
    answer = questdlg('Did you save this session AND your output?',...
        'So you are thinking of closing me...',...
        'Yes','No',...
        'No');
    switch answer
        case 'Yes'
            delete(hObject)
        case 'No'
            return
    end
end