function varargout = PopupDialog(varargin)
% POPUPDIALOG MATLAB code for PopupDialog.fig
%      POPUPDIALOG, by itself, creates a new POPUPDIALOG or raises the existing
%      singleton*.
%
%      H = POPUPDIALOG returns the handle to a new POPUPDIALOG or the handle to
%      the existing singleton*.
%
%      POPUPDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POPUPDIALOG.M with the given input arguments.
%
%      POPUPDIALOG('Property','Value',...) creates a new POPUPDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PopupDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PopupDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PopupDialog

% Last Modified by GUIDE v2.5 09-Jun-2011 16:03:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PopupDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @PopupDialog_OutputFcn, ...
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


% --- Executes just before PopupDialog is made visible.
function PopupDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PopupDialog (see VARARGIN)

% Choose default command line output for PopupDialog
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PopupDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PopupDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
global RHCount TOCount
varargout = {RHCount,TOCount};
clear global RHCount TOCount

% --- Executes on selection change in popupmenuRH.
function popupmenuRH_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuRH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuRH contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuRH

contents = cellstr(get(handles.popupmenuRH,'String'));
RHCount = str2double(contents{get(handles.popupmenuRH,'Value')});
contents = cellstr(get(handles.popupmenuTO,'String'));
TOCount = str2double(contents{get(handles.popupmenuTO,'Value')});
if RHCount == 0 && TOCount == 0
    set(handles.pushbuttonOK,'Enable','off');
else
    set(handles.pushbuttonOK,'Enable','on');
end


% --- Executes during object creation, after setting all properties.
function popupmenuRH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuRH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popupmenuTO.
function popupmenuTO_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTO contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTO

contents = cellstr(get(handles.popupmenuRH,'String'));
RHCount = str2double(contents{get(handles.popupmenuRH,'Value')});
contents = cellstr(get(handles.popupmenuTO,'String'));
TOCount = str2double(contents{get(handles.popupmenuTO,'Value')});
if RHCount == 0 && TOCount == 0
    set(handles.pushbuttonOK,'Enable','off');
else
    set(handles.pushbuttonOK,'Enable','on');
end


% --- Executes during object creation, after setting all properties.
function popupmenuTO_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonOK.
function pushbuttonOK_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RHCount TOCount
contents = cellstr(get(handles.popupmenuRH,'String'));
RHCount = str2double(contents{get(handles.popupmenuRH,'Value')});
contents = cellstr(get(handles.popupmenuTO,'String'));
TOCount = str2double(contents{get(handles.popupmenuTO,'Value')});
close(handles.figure1);

% --- Executes on button press in pushbuttonCANCEL.
function pushbuttonCANCEL_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCANCEL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global RHCount TOCount
RHCount = [];
TOCount = [];
close(handles.figure1);
