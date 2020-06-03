function [m,v1] = Controller()
    %Opens an empty instance of segmentation GUI. Returns ImageDisplayer
    %object and GUI component handles.
    
    %TODO - Access configuration files
    
%--- Initialize BatchAggregate, ImageDisplayer, and call Viewer
%       function to open GUI window.
    m1 = BatchAggregate;
    m = ImageDisplayer(m1);
    v1 = Viewer(m);
    % Get GUI on the screen and refresh display
    movegui(v1.fig,'onscreen');
    refreshDisplay(v1, m);
    refreshButtonPanels(v1, m);
    
%--- KEYPRESS
    set(v1.fig,'KeyPressFcn',{@recordKeyPress,m})
%--- TOOLBAR
    % Add toolbar callbacks
    v1 = addUserInputCallbacks(m, v1);
    % Crop
    hTmpButton = findall(v1.custoolbar,'tag','crop_button');
    set(hTmpButton,'ClickedCallback', {@interactiveCrop_callback,m,v1});
    % Add aggregate
    hOpenButton = findall(v1.custoolbar,'tag','addagg_button');
    set(hOpenButton, 'ClickedCallback',{@addAgg_callback,m});
    % Subtract aggregate
    hTmpButton = findall(v1.custoolbar,'tag','subtract_button');
    set(hTmpButton,'ClickedCallback', {@subCurrAgg_callback,m});

%--- MENU
    % Default Crop button
    set(v1.menu.file.defcrop,'MenuSelectedFcn',@(hobj,evnt)getDefCrop_Fcn(hobj,evnt,m))
    
%--- BUTTONS
    % Set focus-change change events
    set(v1.nav.pushbutton_next, 'Callback', {@iterateFocus,m,1})
    set(v1.nav.pushbutton_prev, 'Callback', {@iterateFocus,m,-1})
    set(v1.nav.pushbutton_add,'Callback',{@addAgg_callback,m})
    set(v1.nav.pushbutton_sub,'Callback',{@subCurrAgg_callback,m})
    % Crop buttons
    set(v1.croptools.crop,'Callback',{@interactiveCrop_callback,m,v1});
    set(v1.croptools.reset,'Callback',{@resetCrop_callback,m,v1});
    % Param Control buttons
    set(v1.resetparams,'Callback',{@resetParams_callback,m,v1});
    % Output buttons
%     set(v1.output.fitcont,'Callback',{@fitstadiums_callback,m,v1});
    set(v1.output.getoutput,'Callback',{@getOutput_callback,m,v1});
    set(v1.output.getalloutput,'Callback',{@getAllOutput_callback,m,v1});

%--- Other navigation options
    set(v1.nav.focusidx_txt,'Callback',{@jumpFocus,m,v1});
    
%--- VIEW CONTROLS
    % Set view popup menu callback
    set(v1.viewpopup,'Callback',{@changeView_callback,m});
    % Listeners: Set callbacks for change in focus, view, crop, and
    %               parameters.
    h1 = event.proplistener(m, {...
        findprop(m,'FocusIdx'),...
        findprop(m,'ViewMode')}, 'PostSet', ...
        @(o,e) refreshAndRefactorDisplay(v1, e.AffectedObject));
    
    h2 = event.proplistener(m, findprop(m,'ViewMode'), 'PostSet', ...
        @(o,e) refreshButtonPanels(v1, e.AffectedObject));
    
    h3 = event.listener(m.Batch.Aggs, 'ParamChange', ...
        @(o,e) paramChangeFcn(v1, e, m));
    
    h4 = event.listener(m.Batch.Aggs, 'CropChange', ...
        @(o,e) refreshAndRefactorDisplay(v1, m));
    
    h5 = event.listener(m, 'RefreshTriggered', ...
        @(o,e) refreshAndRefactorDisplay(v1,m));
    
    setappdata(v1.fig, 'proplistener', h1);
    setappdata(v1.fig, 'panellistener',h2);
    setappdata(v1.fig, 'propupdatelistener',h3);
    setappdata(v1.fig, 'cropupdatelistener',h4);
    setappdata(v1.fig, 'refreshtriggerlistener',h5);

    % Set Contours callback
    setContoursCallback(v1.contourspanel, m, v1);

%--- PARAMETER INTERFACING
    % BG masking panel
    tmpch = findobj(v1.switchpanel(3),'tag','r_open1_panel');
    m.ParamParams.r_open1.linkSubPanel(tmpch(1));
    tmpch = findobj(v1.switchpanel(3),'tag','thd1_panel');
    m.ParamParams.thd1.linkSubPanel(tmpch(1));
    tmpch = findobj(v1.switchpanel(3),'tag','schm_size_panel');
    m.ParamParams.schm_size.linkSubPanel(tmpch(1));
    % Sharpening panel
    TAG = 'sharp_rad';
    tmpch = findobj(v1.switchpanel(4),'tag',[TAG,'_panel']);
    m.ParamParams.(TAG).linkSubPanel(tmpch(1));
    TAG = 'sharp_str';
    tmpch = findobj(v1.switchpanel(4),'tag',[TAG,'_panel']);
    m.ParamParams.(TAG).linkSubPanel(tmpch(1));
    % Cleaning panel
    TAG = 'r_close1';
    tmpch = findobj(v1.switchpanel(5),'tag',[TAG,'_panel']);
    m.ParamParams.(TAG).linkSubPanel(tmpch(1));
    TAG = 'r_open2';
    tmpch = findobj(v1.switchpanel(5),'tag',[TAG,'_panel']);
    m.ParamParams.(TAG).linkSubPanel(tmpch(1));
    TAG = 'r_close2';
    tmpch = findobj(v1.switchpanel(5),'tag',[TAG,'_panel']);
    m.ParamParams.(TAG).linkSubPanel(tmpch(1));
    TAG = 'r_erode1';
    tmpch = findobj(v1.switchpanel(5),'tag',[TAG,'_panel']);
    m.ParamParams.(TAG).linkSubPanel(tmpch(1));
    % Watershed panel


    % Radio button for global control
    set(v1.globalradio,'Callback',{@switchParamMode_callback,m,v1});

    % % Hook up contour view
    % hookupContoursView(v1.contourspanel, m, v1);
    
    %--- Add paths
    loadpath = cd;
    savepath = cd;
    impath = cd;
    outputpath = cd;
    
    hPaths.load = loadpath;
    hPaths.save = savepath;
    hPaths.images = impath;
    hPaths.output = outputpath;
    guidata(v1.fig,hPaths);
end

%% KEYBOARD CONTROLS
function recordKeyPress(hfig,keydata,model)
    switch keydata.Key
        case('rightarrow')
            iterateFocus([],[],model,1);
        case('leftarrow')
            iterateFocus([],[],model,-1);
        case {'delete','backspace'}
            subCurrAgg_callback([],[],model)
            
        otherwise
            disp(keydata.Key)
    end
end
%% FOCUS CHANGES
%
function ReleaseFocusFromAnyUI(uiObj)
    set(uiObj, 'Enable', 'off');
    drawnow update;
    set(uiObj, 'Enable', 'on');
end

%--- Jump to specific focus point
function jumpFocus(o,~,model,viewer)
    val = o.String;
    o.String = num2str(model.FocusIdx);
    % Check if val is a number
    val2 = str2double(val);
    if isnan(val2)
        return
    end
    % Check if val2 is a whole number
    if ~(sign(val2) == 1 && rem(val2,1) == 0)
        return
    end
    % Check if val2 is a valid idx
    if val2 <= model.NumAggs
        model.changeFocus(val2);
    end
    ReleaseFocusFromAnyUI(o);
end

%--- Step through focus
function iterateFocus(o,~,model,val)
    % Update focus index
    model.changeFocus(model.FocusIdx+val);
    ReleaseFocusFromAnyUI(o);
end

%% TOOLBAR CONTROLS
%--- Remap buttons on Figure Toolbar
function handles = addUserInputCallbacks(model, handles)
    hToolbar = findall(handles.fig,'tag','FigureToolBar');
    % Remap open button to load batch
    hOpenButton = findall(hToolbar,'tag','Standard.FileOpen');
    set(hOpenButton, 'ClickedCallback',{@loadBatch_callback,model});
    % Remap save button to save batch
    hSaveButton = findall(hToolbar,'tag','Standard.SaveFigure');
    set(hSaveButton,'ClickedCallback',{@saveBatch_callback,model});
end

%Callbacks
%--- Load Batch
function loadBatch_callback(src,event,model)
    pathhandles = guidata(src);
    % Select file with batch info
    [name,path] = uigetfile('*.mat','Load previous state of GUI',pathhandles.load);
    if name % If a file was selected, load in the data
        dat = load(fullfile(path,name));
        model.reload_batch(BatchAggregate.loadobj(dat.s));
        pathhandles.load = path;
        guidata(src,pathhandles);
    end
    % Refactor refresh callback
    fig = ancestor(src,'figure');
    clbk = getappdata(fig,'propupdatelistener');
    clbk.Source = model.Batch.Aggs;
end
%--- Save Batch
function saveBatch_callback(src,event,model)
    pathhandles = guidata(src);
    [name,path] = uiputfile('*.mat','Save state of GUI',pathhandles.save);
    if name
        s = model.Batch.saveobj;
        % Reassign Global Params because batch doesn't store them
        s.GlobalParams = model.SegParams(1).batch.CurrentParams;
        save(fullfile(path,name),'s','-v7.3');
        pathhandles.save = path;
        guidata(src,pathhandles);
    end
    
end

%% BATCH MANAGEMENT

%Callbacks
%--- Add an image to the end of the batch
function addAgg_callback(src,event,model)
    % TODO - Get starting path from config file
%     StartingPathName = 'X:\Rashad Baiyasi\NRaggregate segmentation\Files from Qingfeng\Image for analysis to Rashad\10222018\BSA';
    pathhandles = guidata(src);
    StartingPathName = pathhandles.images;
    delim = '\';
    % Select file(s)
    [FileNames,PathName] = uigetfile('*.tif', 'Select image to add to batch',...
        StartingPathName,'MultiSelect','on');
    if ~iscell(FileNames)
        if FileNames
            FileNames = {FileNames};
        else
            disp('No aggregate added');
            return
        end
    end
    % TODO - validate that they are the correct file type
    
    % Switch to Raw image view
    model.ViewMode = 'RawIm';
    saveidx = model.Batch.len+1;
   
    % Add each image to ImageDisplayer and Batch
    wb = waitbar(0,'Loading images');
    for k = 1:numel(FileNames)
        FileName = FileNames{k};
        newAgg = SegImage([PathName,delim,FileName]);
        model.addAgg(newAgg);
        waitbar(k/numel(FileNames),wb);
    end
    close(wb)
    
    % Update saved path
    pathhandles.images = PathName;
    guidata(src,pathhandles);
    
    % Update property listener source to include the new images
    fig = ancestor(src,'figure');
    clbk = getappdata(fig,'propupdatelistener');
    clbk.Source = model.Batch.Aggs;
    
    % Set focus to first new idx and trigger a refresh
    model.FocusIdx = saveidx;
    model.triggerRefresh;
    ReleaseFocusFromAnyUI(src);
end
%--- Remove the current image from the batch
function subCurrAgg_callback(src,event,model)
    % Removes the current focus aggregate
    if model.NumAggs == 1
        msgbox('Can''t remove last aggregate');
        return
    end
    answer = questdlg('Remove current aggregate from batch?',...
                        'Are you sure?',...
                        'Yes','No','Yes');
    switch answer
        case 'Yes'
            % Delete current aggregate
            model.subCurrAgg;
        case 'No'
    end
    ReleaseFocusFromAnyUI(src);    
end


%% VIEW/DISPLAY MANAGEMENT
%--- Refresh displayed image and graphics object values
function refreshDisplay(handles, model)
    % If the image is the same size, then keep the zoom state the same.
    % Otherwise reset the x and y limits to sit tight on the image. May want to
    % remove the preserving zoom functionality later
    if ~isequal(size(handles.image.CData),size(model.CurrentView))
        set(handles.image, 'CData', model.CurrentView);
        matsize = size(handles.image.CData);
        set(handles.ax,'XLim', [0.5, matsize(2)+0.5]);
        set(handles.ax,'YLim', [0.5, matsize(1)+0.5]);
    else
        handles.image.CData = model.CurrentView;
    end

    handles.ax.DataAspectRatio = [1,1,1];
%             disp(' ');disp('Setting text')
    set(handles.txt, 'String', model.CurrentAgg.fileobj.FileName);
%             disp(' ');disp('Setting viewpopup')
    set(handles.viewpopup,'Value',find(strcmp(model.VIEWNAMESVALS,model.ViewMode)))
    set(handles.nav.numaggs_txt,'String',num2str(model.Batch.len));
    set(handles.nav.focusidx_txt,'String',num2str(model.FocusIdx));
%     disp('refreshDisplay@Viewer.m')
    
    % Reset display stuff
    switch model.ParamMode
        case 'batch'
            set(handles.globalradio,'Value',0);
        case 'single'
            set(handles.globalradio,'Value',1);
    end
    refreshToggleButton(handles.globalradio);
    
    % Figure out contours view
    cpanel = handles.contourspanel;
    switch model.ViewMode
        case 'BGMask'
            set(findobj(cpanel,'Tag','bgmask'),'Value',1);
        case 'WatershedIm'
            set(findobj(cpanel,'Tag','watershedim'),'Value',1);
        case 'RawIm'
            set(findobj(cpanel,'Tag','none'),'Value',1);
        case 'Stadium'
            set(findobj(cpanel,'Tag','fitcont'),'Value',1);
        otherwise
    end
    contview = findobj(handles.contourspanel,'Value',1);
    switchContoursView_callback(contview,[],model,handles);
%     model.refactorSegParams();
end
%--- Refresh display and refactor segmentation parameters
function refreshAndRefactorDisplay(handles,model)
    refreshDisplay(handles,model);
    model.refactorSegParams();
    refreshButtonPanels(handles,model);
end
%--- Refresh toggle button appearance
function refreshToggleButton(hobj,evnt)
    switch hobj.Value
        case 0
            hobj.BackgroundColor = [0.5,0.8,0.5];
            hobj.String = {'Global'};
        case 1
            hobj.BackgroundColor = 0.94*[1,1,1];
            hobj.String = {'Custom'};
        otherwise
            error('How is a toggle button not 1 or 0?');
    end
end
%--- Set the visible SwitchPanel based on ViewMode
function refreshButtonPanels(handles,model)
    % Get a logical array corresponding to the potential panels
    isactive = strcmp(model.VIEWNAMESVALS, model.ViewMode);
    for k = 1:numel(handles.switchpanel)
%         handles.switchpanel(k).Visible = isactive(k);
        switch isactive(k)
            case 0
                handles.switchpanel(k).Visible = 'off';
            case 1
                handles.switchpanel(k).Visible = 'on';
                switch model.ParamMode
                    case 'batch'
                        set(handles.switchpanel(k),'BackgroundColor',[0.8,0.95,0.8]);
                    case 'single'
                        set(handles.switchpanel(k),'BackgroundColor',0.94*ones(1,3));
                    otherwise
                        set(handles.switchpanel(k),'BackgroundColor',0.94*ones(1,3));
                end
        end
    end
end
%--- Set the appropriate callbacks for ContourView panel
function setContoursCallback(cpanel, model, viewer)
    tmp = findobj(cpanel,'style','radiobutton');
    for k = 1:numel(tmp)
        set(tmp,'Callback', {@switchContoursView_callback, model, viewer});
    end    
    
end

%Callbacks
%--- Change ImageDisplayer ViewMode property
function changeView_callback(src,event,model)
    model.ViewMode = model.VIEWNAMESDICT(src.String{src.Value});
end
%--- Switch view of contours
function switchContoursView_callback(src,evnt,model,viewer)
    val = src.Tag;
    % Delete previous lines and text handles
    lhs = findobj(viewer.ax,'Type','line');
    typehs = findobj(viewer.ax,'Type','text');
    delete(lhs);
    delete(typehs);
    switch val
        case 'bgmask'
            viewer.ax;
            hold on
            tmp = model.CurrentAgg.BGContour;
            for k = 1:numel(tmp)
                plot(tmp{k}(:,2),tmp{k}(:,1),'r','LineWidth',2);
            end
            hold off
        case 'watershedim'
            viewer.ax;
            hold on
            tmp = model.CurrentAgg.WatershedContour;
            for k = 1:numel(tmp)
                plot(tmp{k}(:,2),tmp{k}(:,1),'r','LineWidth',1);
            end
            hold off
        case 'fitcont'
            viewer.ax;
            hold on
            tmp = model.CurrentAgg.StadiumContour;
            if isequal(model.CurrentAgg.Stadium,0)
                tmplocs = [NaN,NaN];
            else
                tmplocs = cat(1,model.CurrentAgg.Stadium(:).cpix);
            end
            
            for k = 1:numel(tmp)
                plot(tmp{k}(:,2),tmp{k}(:,1),'r','LineWidth',1);
                text(tmplocs(k,1),tmplocs(k,2),num2str(k),...
                    'Color','r','FontSize',12);
            end
            hold off
            
        case 'none'
%             lhs = findobj(viewer.ax,'Type','line');
%             delete(lhs);
        otherwise
            error('Invalid contour selection option')
    end
end

%% CROP CONTROLS
%--- Set a default crop
function getDefCrop_Fcn(hobject,eventdata,model)
    currcropreg = model.CurrentAgg.CropReg;
    currcoords = [currcropreg(1:2),currcropreg(3:4)+currcropreg(1:2)-1];
    fh = 170;
    g = 10;
    w = 50;
    h = 20;
    starty_1 = 60;
    starty_label = starty_1 + g + h;
    starty_instruct = starty_label + h + g;
    fig = figure(83493);
    delete(allchild(fig))
    fig.Name = 'Default crop';
    fig.NumberTitle = 'off';
    fig.ToolBar = 'none';
    fig.MenuBar = 'none';
    for k = 1:4
        tmph = uicontrol(fig,'style','edit','Tag',['cropcoord_',num2str(k)]);
        tmph.Position = [...
                            g + (w+g)*(k-1),...
                            starty_1, w, h];
        tmph.String = num2str(currcoords(k));
        edithandle(k) = tmph;
    end
    % Add labels over each edit text
    x1y1_label = uicontrol(fig,'style','text','Tag','x1y1_label','String','( x1  ,  y1 )');
    x1y1_label.Position = [g,starty_label,2*w+g,h];
    
    x2y2_label = uicontrol(fig,'style','text','Tag','x2y2_label','String','( x2  ,  y2 )');
    x2y2_label.Position = [3*g+2*w,starty_label,2*w+g,h];
    
    % Add instructions
    instruct = uicontrol(fig,'style','text','Tag','instruct','String',...
                        'Input starting and ending coordinates for default crop');
    instruct.Position = [g,starty_instruct,4*w + 3*g,2*h];
    instruct.FontSize = 10;
    fig.Position(3) = g+4*(g+w);
    fig.Position(4) = fh;
    
    % Add button
    setbutt = uicontrol(fig,'style','pushbutton','tag','setbutt','String','Overwrite default crop');
    setbutt.Position = [g,starty_1 - 2*h - g, 4*w + 3*g, 2*h];
    set(setbutt,'Callback',{@setDefCrop,model})
end

function setDefCrop(hobj,evnt,m)
    newcoords = nan(1,4);
    for k = 1:4
        tmpobj = findobj(hobj.Parent,'tag',['cropcoord_',num2str(k)]);
        newcoords(k) = round(str2double(tmpobj.String));
    end
    newcropreg = [newcoords(1:2),newcoords(3:4)-newcoords(1:2)+1];
    m.Batch.DefCrop = newcropreg;
    m.Batch.updateCropRegs2Def('fullandprev');
end

%--- Start cropping mode
function activateCropView(cropreg, model,viewer)
    % Must account for previous cropping if not in RawIm view
    switch model.ViewMode
        case 'RawIm'
            model.CurrentAgg.CropReg = round(round(cropreg));
        otherwise
            oldreg = model.CurrentAgg.CropReg;
            newreg = [oldreg(1:2) + round(cropreg(1:2)) - 1, round(cropreg(3:4))];
            model.CurrentAgg.CropReg = newreg;
    end

    figure(viewer.fig)
end

%--- End cropping mode
function cropFinishedFcn(model,KeyData,viewer)
    kr = KeyData.KeyRecord;
    cropreg = viewer.Icropper.RectPos;
    switch kr.Key
        case 'return'
            activateCropView(cropreg, model,viewer);
            delete(KeyData);
            viewer.cropbutton.Value = 0;
            if strcmp(model.ViewMode,'RawIm')
                model.ViewMode = 'PreprocIm';
            end
            model.triggerRefresh;
        case 'escape'
            delete(KeyData);
            viewer.cropbutton.Value = 0;
        case 'backspace'
            delete(KeyData);
            viewer.cropbutton.Value = 0;
        otherwise
            return
    end
    for k = 1:numel(viewer.hideables)
        viewer.hideables(k).Visible = 'on';
    end
end
%Callbacks
%--- Start interactive cropping
function viewer = interactiveCrop_callback(src,evnt,model,viewer)
    %TODO - figure out if the IC object is actually getting added to
    %handles, since I don't see where the output goes.
    % Turn off buttons
    for k = 1:numel(viewer.hideables)
        viewer.hideables(k).Visible = 'off';
    end
    % Create an InteractiveCropper instance and add it to handles
    viewer.Icropper = InteractiveCropper(viewer.ax);
    % Create a listener
    h1 = addlistener(   viewer.Icropper,...
                        findprop(viewer.Icropper,'KeyRecord'),...
                        'PostSet', ...
                        @(o,e)cropFinishedFcn(  model,...
                                                e.AffectedObject,viewer));
    setappdata(viewer.fig, 'croplistener', h1);
end

%--- (TODO) Reset Crop
function viewer = resetCrop_callback(src,evnt,model,viewer)
% Reset crop to something.. not really sure yet
end


%% PARAMETER CONTROLS
%--- Execute on parameter change
function paramChangeFcn(handles,evnt,model)
    refreshAndRefactorDisplay(handles,model)
end

%Callbacks
%--- Switch ParamMode between batch and single
function viewer = switchParamMode_callback(src,evnt,model,viewer)
    switch src.Value
        case 0
            model.ParamMode = 'batch'; 
        case 1
            model.ParamMode = 'single';
    end
    model.refactorSegParams();
    refreshButtonPanels(viewer,model);
    refreshToggleButton(src,evnt);
end

%--- Reset custom parameters to batch value
function viewer = resetParams_callback(src,evnt,model,viewer)
    model.resetSingleToBatchParams;
    model.refactorSegParams();
    refreshButtonPanels(viewer,model);

end
%% OUTPUT OPERATIONS

%Callbacks
%--- Fit to stadium
function viewer = fitstadiums_callback(src,evnt,model,viewer)
	% TODO - Switch refresh function to controller so this can key off of
	% it
    model.CurrentAgg.Stadium = [];
    model.CurrentAgg.doGetIm('Stadium');
end

%--- Get all outputs button
function getAllOutput_callback(src,evnt,model,viewer)
    NRoutputs = [];
    Aggoutputs = [];
    % Loop over each aggregate
    for k = 1:model.Batch.len
        % Get Nanorod outputs and results
        [tmpresults] = model.Batch.Aggs{k}.getOutputs();
        tmpaggresults = model.Batch.Aggs{k}.Outputs;
        flds = fields(tmpresults);
        tmpoutput = repmat(struct('ImageNo',k),numel(tmpresults),1);
        for k2 = 1:numel(tmpresults)
            for k3 = 1:numel(flds)
            tmpoutput(k2).(flds{k3}) = tmpresults(k2).(flds{k3});
            end
        end
        NRoutputs = cat(1,NRoutputs,tmpoutput);
        Aggoutputs = cat(1,Aggoutputs,tmpaggresults);
    end
    % Display table of nanorod outputs
    T = struct2table(NRoutputs);
    tfig = figure;
    uit = uitable(tfig,'Data',T.Variables);
    uit.ColumnName = T.Properties.VariableNames;
    uit.Units = 'normalized';
    uit.Position = [0,0,1,1];
    
    % Display table of aggregate outputs
    T2 = struct2table(rmfield(Aggoutputs,'stads'));
    tfig2 = figure;
    uit2 = uitable(tfig2,'Data',table2cell(T2));
    uit2.ColumnName = T2.Properties.VariableNames;
    uit2.Units = 'normalized';
    uit2.Position = [0,0,1,1];
    
    pathhandles = guidata(src);
    [FileName, PathName] = uiputfile('*.mat','Save output data',pathhandles.output);
    if FileName
        save([PathName,FileName],'NRoutputs','Aggoutputs');
    
        % Save figures for each image.
        for k = 1:model.Batch.len()
            fig = figure('Visible','off');
            ax = gca;
            agg = model.Batch.Aggs{k};
            imagesc(ax,agg.viewIm('Stadium'));
            axis image off
            agg.numberNRs(ax);
            saveas(fig,[PathName,FileName(1:end-4),'_',num2str(k),'.png']);
            close(fig)
            
        end
        pathhandles.output = PathName;
        guidata(src,pathhandles);
    end
        
    
end

%--- Get output button callback
function viewer = getOutput_callback(src,evnt,model,viewer)
%     if model.CurrentAgg.isImLoaded('WatershedIm')
%         fig = figure;
%         imagesc(model.CurrentAgg.WatershedIm);
%         axis image off
%     else
%         msgbox('Watershed image must be calculated first')
%     end
    
    [~,T] = model.CurrentAgg.getOutputs();
    % Write the table to a text file for now
%     writetable(T,'testwrite');
    % Display the table
    fig = figure;
    fig.Position(3) = 1.25*fig.Position(3);
    fig.Position(4) = .75*fig.Position(4);
    colnames = T.Properties.VariableNames;
    data = T.Variables;
    pos = fig.InnerPosition;
    
    uit2 = uitable(fig,'Data',data);
    uit2.Tag = 'nroutputs';
    uit2.ColumnName = colnames;
    oldpos = uit2.Position;
    uit2.Position(3:4) = pos(3:4) - 2*(oldpos(1:2));
%     uit.Units = 'normalized';
    
    % Display order in the figure name for now
    figname = [ 'Output for ',model.CurrentAgg.Outputs.Filename];
    set(fig,'Name',figname);
    set(fig,'SizeChangedFcn',@outputtable_sizechangedfcn)

    % Table of aggregate parameters
    uit1 = uitable(fig);
    uit1.Tag = 'aggoutputs';
    flds = fields(model.CurrentAgg.Outputs);
    % Skip stads
    flds = setdiff(flds,'stads');
    data1 = {};
    for k = 1:numel(flds)
        data1{k} = model.CurrentAgg.Outputs.(flds{k});
    end
    uit1.Data = data1;
    uit1.ColumnName = flds;
    
    % Refresh size
    outputtable_sizechangedfcn(fig);
    % Display figure of fitting results
%     fig = figure;
    
end

function outputtable_sizechangedfcn(src, evnt)
    gapsz = 20;
    t1h = 40;
    figsz = src.Position;
    uit1 = findobj(src,'tag','aggoutputs');
    uit1.Position = [gapsz,figsz(4)-gapsz-t1h,figsz(3)-2*gapsz,t1h];
    uit2 = findobj(src,'tag','nroutputs');
    uit2.Position = [gapsz,gapsz,figsz(3)-2*gapsz,figsz(4)-t1h-3*gapsz];
    
end
