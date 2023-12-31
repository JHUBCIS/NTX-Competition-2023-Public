classdef UserConfig < handle
    % Class to hold user config variables.  This is setup to prompt the
    % user the first time it is accessed, and then rely on that file for
    % the remaining parameter calls
    %
    % Example: obj = UserConfig.getInstance(userConfigFile)
    %
    % Arguments: userConfigFile - full path to user config .xml
    % file
    % Revisions
    % 23APR2015 Armiger: Created
    properties (SetAccess = 'private')
        userConfigFile = 'user_config.xml';
        userRocFile = '';
        domNode  % Stores the Document Object Model node for parsing
    end
    methods (Access = private)
        function obj = UserConfig
            % Creator is private to force singleton
        end
    end
    
    methods (Static)
        function singleObj = getInstance(userConfigFile)
            % Static creator method.  this will provide a singleton handle
            % to the class file
            %
            % Usage: obj = getInstance(userConfigFile)
            %
            % Reset: UserConfig.getInstance('')
            %
            % Arguments: userConfigFile - full path to user config .xml
            % file
            persistent localObj
            
            if nargin > 0 && isempty(userConfigFile)
                localObj = [];
                fprintf('Resetting Object\n');
                return
            end
            
            if isempty(localObj) || ~isvalid(localObj)
                if nargin < 1
                    %userConfigFile = 'user_config.xml';
                    
                    [FileName,PathName,FilterIndex] = uigetfile('user_config.xml','Select User Configuration XML File to Open');
                    if FilterIndex == 0
                        % User Cancelled
                        userConfigFile = '';
                    else
                        userConfigFile = fullfile(PathName,FileName);
                    end
                end
                
                % ensure full path is resolved
                %userConfigFile = which(userConfigFile);
                fprintf('[%s.m] Calling constructor with config file %s\n',mfilename,userConfigFile);
                
                localObj = UserConfig;
                localObj.userConfigFile = userConfigFile;
                
                % read the file
                if ~isempty(userConfigFile)
                    
                    try 
                        localObj.domNode = xmlread(userConfigFile);
                    catch ME
                        fprintf(2,'**********\n')
                        fprintf(2,'Error parsing xml file: %s\n',userConfigFile);
                        fprintf(2,'Note: Typical start of an XML doc (with no leading whitespace) is: <?xml version=''1.0''?>\n');
                        fprintf(2,'**********\n')
                        
                        rethrow(ME)
                    end
                    
                    
                end
                
            else
                %fprintf('[%s] Returning existing object\n',mfilename);
            end
            singleObj = localObj;
            
            % read the roc table on startup to store path
            %UserConfig.getUserConfigVar('rocTable','WrRocDefaults.xml');
        end
        function success = reload
            % Reload the specified xml file
            obj = UserConfig.getInstance;
            userFile = obj.userConfigFile;
            
            % read the file
            obj.domNode = xmlread(userFile);
            
            success = true;
        end
        
        
        function result = getUserConfigVar(tagName,defaultValue)
            %result = UserConfig.getUserConfigVar(tagName,defaultValue)
            % Read tag from user config xml file
            %
            % the class of the output is determined by the default value
            % provided [required]
            %
            
            obj = UserConfig.getInstance;
            userFile = obj.userConfigFile;
            
            % default output
            result = defaultValue;
            
            a = obj.domNode;
            
            if isempty(a)
                fprintf('[%s.m] No file %s found\n',mfilename,userFile);
                return
            end
            
            
            % Because we are reading from xml, the xmlResult will
            % always be a char.
            xmlResult = '';
            v = a.getElementsByTagName('add');
            for i = 1:v.getLength
                t = v.item(i-1);
                key = char(t.getAttribute('key'));
                if strcmp(key,tagName)
                    xmlResult = char(t.getAttribute('value'));
                    break;
                end
            end
            
            if isempty(xmlResult)
                %Not found
                % display warning
                if ischar(defaultValue)
                    fprintf('[%s.m] %s not found. Default=%s\n',mfilename,tagName,defaultValue);
                else
                    fprintf('[%s.m] %s not found. Default=%s\n',mfilename,tagName,num2str(defaultValue));
                end
                result = defaultValue;
            else
                % Echo the xml value found display 
                fprintf('[%s.m] %s=%s\n',mfilename,tagName,xmlResult);
                result = xmlResult;
            end
            
            % convert value to the class of the default parameter.
            % If the default value isn't a character, then it needs to be
            % converted
            if ~ischar(defaultValue) && ischar(result)
                % example '[1 3]'  --> 1 3
                [x, status] = str2num(result); %#ok<ST2NM>
                if status
                    result = x;
                else
                    warning('Failed to cast xml key-value');
                end
            end
            
            
            
            % Add a check for file references to add the full path if
            % omitted.  THis is a special case for roc tables
            
            %             switch tagName
            %                 case 'rocTable'
            %
            %                     % check if the rocTable has path info
            %                     missingPath = isempty(fileparts(result));
            %                     noStoredPath = isempty(obj.userRocFile);
            %
            %                     if missingPath && noStoredPath
            %                         % store the table with path
            %                         %obj.userRocFile = which(result);
            %                         result = obj.userRocFile;
            %                         fprintf('[%s.m] Storing full path tag "%s": "%s"\n',mfilename,tagName,result);
            %                     elseif missingPath && ~noStoredPath
            %                         % use the stored path and file
            %                         result = obj.userRocFile;
            %                     else
            %                         % Path exists in xml so use it
            %                     end
            %
            %                     assert(exist(result,'file') > 0,'XML Roc file %s not found %s',result);
            %
            %             end
        end
    end
end
