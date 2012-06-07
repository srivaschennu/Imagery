function varargout = uiimport(varargin)

%HACK to prevent uiimport popup

varargout{1} = load('-mat',varargin{1});