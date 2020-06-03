function varargout = nrsegGUI_v1(varargin)
% NRSEGGUI_V1 MATLAB code for nrsegGUI_v1.fig
%      NRSEGGUI_V1, by itself, creates a new NRSEGGUI_V1 or raises the existing
%      singleton*.
%
%      H = NRSEGGUI_V1 returns the handle to a new NRSEGGUI_V1 or the handle to
%      the existing singleton*.
%
%      NRSEGGUI_V1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NRSEGGUI_V1.M with the given input arguments.
%
%      NRSEGGUI_V1('Property','Value',...) creates a new NRSEGGUI_V1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nrsegGUI_v1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nrsegGUI_v1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nrsegGUI_v1

% Last Modified by GUIDE v2.5 28-Feb-2019 14:35:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @nrsegGUI_v1_OpeningFcn, ...
                   'gui_OutputFcn',  @nrsegGUI_v1_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before nrsegGUI_v1 is made visible.
function nrsegGUI_v1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nrsegGUI_v1 (see VARARGIN)

% Choose default command line output for nrsegGUI_v1
handles.output = hObject;

% Set Contstants
handles.DEFPATH = 'X:\Rashad Baiyasi\NRaggregate segmentation\Files from Qingfeng\Image for analysis to Rashad\10222018\BSA\';

% Initialize variables
    % Workspace is a structure that holds the current information about the
    % current state of the GUI
handles.Workspace = struct('LoadPath','');
handles.Workspace.FileNames = {''};
handles.Workspace.CurrentIndex = 1;
handles.Workspace.delim = '\';
    % Storestruct is a structure array that contains the relevant
    % information about each image that we are analyzing
handles.Storestruct = struct('RawIm',[]);

% Initialize axes
handles.DisplayImages.axes1.ImageHandle = imagesc([]);
handles.DisplayImages.axes1.DisplayMode = 'RawIm';
axis image off; colormap gray
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes nrsegGUI_v1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = nrsegGUI_v1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Open a file to analyze 
function uiopentool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiopentool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % This block should assign the proper values to Workspace to allow the
    % displayupdate function to work
[filename,pathname,filterindex] = uigetfile(...
    '*','Select SEM image to analyze',handles.DEFPATH);
if filterindex % If a valid file is selected
    if ~iscell(filename)
        filename = {filename};
    end
    handles.Workspace.FileNames = filename;
    handles.Workspace.LoadPath = [pathname , handles.Workspace.delim];
    
    handles = LoadImage(...
        hObject, eventdata, handles, handles.Workspace.CurrentIndex);
    UpdateDisplay(hObject, eventdata, handles);
end
guidata(hObject, handles);

% --- Load an image
function handles = LoadImage(hObject, eventdata, handles, idx)
rawim = imread(...
    [handles.Workspace.LoadPath , handles.Workspace.FileNames{idx}]);
if size(rawim,3) == 3
    rawim = rgb2gray(rawim);
end
rawim = mat2gray(rawim); % Bound intensity by [0,1];
handles.Storestruct(idx).RawIm = rawim;

% --- Update display
% Anything regarding visualizing the display should be included here. If
% you want the ability to update multiple things, it should be passed as an
% extra argument, or we can use subfunctions I guess. UpdateDisplay cannot
% effect the current state of the GUI, it just refreshes the display
function UpdateDisplay(hObject, eventdata, handles)
idx = handles.Workspace.CurrentIndex;
% Update Axes 1 image
handles.DisplayImages.axes1.ImageHandle.CData ...
    = handles.Storestruct(idx).(handles.DisplayImages.axes1.DisplayMode);
% Update Axes 1 title
handles.txtbx_axis1.String = handles.Workspace.FileNames{idx};

% --- Crop image down for processing purposes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NAVIGATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = IterateImage(hObject, eventdata, handles, iter)
k = handles.Workspace.CurrentIndex + iter;
numfiles = numel(handles.Workspace.FileNames);
if k <= 0
    handles.Workspace.CurrentIndex = numfiles + k;
elseif k > numfiles
    handles.Workspace.CurrentIndex = k - numfiles;
end

% --- Checks if there is an image loaded for a given index
% Returns a boolean, doesn't update the function
function isloaded = CheckLoaded(hObject, eventdata, handles, idx)
if isequal(size(handles.Storestruct(index).RawIm), [0, 0])
    isloaded = false;
else
    isloaded = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% BUTTON CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in pushbutton_prev.
function pushbutton_prev_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = IterateImage(hObject, eventdata, handles, -1);
% Load image if needed
if ~CheckLoaded(handles.Storestruct(handles.Workspace.CurrentIndex))
    handles = LoadImage(...
        hObject, eventdata, handles, handles.Workspace.CurrentIndex);
end
UpdateDisplay(hObject, eventdata, handles);
guidata(hObject, handles);


% --- Executes on button press in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = IterateImage(hObject, eventdata, handles, 1);


    

% --------------------------------------------------------------------
function uisavetool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uisavetool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% JUNK FROM BUTTONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txtbx_axis1_Callback(hObject, eventdata, handles)
% hObject    handle to txtbx_axis1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtbx_axis1 as text
%        str2double(get(hObject,'String')) returns contents of txtbx_axis1 as a double


% --- Executes during object creation, after setting all properties.
function txtbx_axis1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtbx_axis1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_File_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_File_Open_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
