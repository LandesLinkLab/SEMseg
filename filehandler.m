classdef filehandler
    %filehandler stores path and file names and handles loading
    %   Detailed explanation goes here
    
    properties
        EmptyFlag
        PathName
        FileName
        FileExt
    end
    
    methods
        function obj = filehandler(varargin)
            % Construct an instance of this class
            switch nargin
                case 0
                    obj.EmptyFlag = true;
                case 1
                    [path,name,ext] = fileparts(varargin{1});
                    obj.PathName = path;
                    obj.FileName = name;
                    obj.FileExt = ext;
                    obj.EmptyFlag = false;
                case 3
                    obj.PathName = char(varargin{1});
                    obj.FileName = char(varargin{2});
                    obj.FileExt = char(varargin{3});
                    obj.EmptyFlag = false;
                otherwise
                    error('Improper filehandler inputs')
            end

        end
        
        function s = saveobj(obj)
            s.EmptyFlag = obj.EmptyFlag;
            s.PathName = obj.PathName;
            s.FileName = obj.FileName;
            s.FileExt = obj.FileExt;
        end
        
        function outim = loadim(obj)
            %loadim loads the current image
            if obj.EmptyFlag
                outim = false;
            else
                outim = imread(obj.getfullfile);        
            end
        end
        
        function outpath = getfullfile(obj)
            if obj.EmptyFlag
                outpath = false;
            else
                outpath = fullfile( obj.PathName,...
                                    strcat(obj.FileName,obj.FileExt));
            end
        end
        
        function outflag = checkfile(obj)
            if obj.EmptyFlag
                outflag = false;
            else
                outflag = exist(obj.getfullfile,file);
            end
        end        
       
    end
    
    methods(Static)
        function obj = loadobj(s)
            if isstruct(s)
                newObj = filehandler;
                newObj.EmptyFlag = s.EmptyFlag;
                newObj.PathName = s.PathName;
                newObj.FileName = s.FileName;
                newObj.FileExt = s.FileExt;
                obj = newObj;
            else
                obj = s;
            end
        end
    end
end

