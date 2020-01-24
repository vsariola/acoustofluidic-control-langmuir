function ret = file_logger(varargin)
    default_logpath = '../results/';
    default_logname = 'log';
    default_timestamp = true;
    default_randstring = true;
    default_flushinterval = 1000;
    default_blocksize = 200;
    
    INDEX_POSTFIX = '__index';
        
    parser = inputParser;
    parser.addParameter('logpath',default_logpath,@ischar);            
    parser.addParameter('logname',default_logname,@ischar);            
    parser.addParameter('timestamp',default_timestamp);
    parser.addParameter('randstring',default_randstring);    
    parser.addParameter('flushinterval',default_flushinterval,@isnumeric);
    parser.addParameter('blocksize',default_blocksize,@isnumeric);
    parser.addParameter('verbosity',true);    
    parser.KeepUnmatched = true;
    parse(parser,varargin{:});       
    
    filename = fullfile(parser.Results.logpath,parser.Results.logname);
    
    if parser.Results.timestamp
        filename = [filename '-' datestr(datetime('now'),'yyyy-mm-dd--HH-MM-SS')];
    end
    
    if parser.Results.randstring        
        symbols = ['a':'z' 'A':'Z'];
        randstring = symbols(randi(numel(symbols),[1 8]));
        filename = [filename '-' randstring];          
    end
    
    imgdir = [filename '_images/'];
    filename = [filename '.mat'];

    imgdir = char(get_absolute_path(imgdir));
    fullpath = char(get_absolute_path(filename));
        
    data = struct();
    sinceflush = 0;
    [s,git_hash_string] = system('git rev-parse HEAD');
    if s ~= 0
        git_hash_string = '';
    end
    data.git_hash = git_hash_string;
    flush();

    function log(var,value,type)
        if nargin < 3
            if isfield(data,var)
                type = class(data.(var));
            elseif isstruct(value)
                type = 'struct';
            elseif ischar(value)
                type = 'cell';
            else
                type = 'double';
            end
        end
        ind = [var INDEX_POSTFIX];
            
        if ~isfield(data,var) 
            if strcmp(type,'struct')
                fields_vals = cellfun(@(x){x,{}}',fieldnames(value),'UniformOutput',false);
                flattened = vertcat(fields_vals{:});
                data.(var) = struct(flattened{:});
            elseif strcmp(type,'image') || strcmp(type,'cell')                
                data.(var) = {};                
            else
                data.(var) = [];                
            end
            data.(ind) = 0;
        end
        
        data.(ind) = data.(ind) + 1;
        
        if strcmp(type,'struct')
            data.(var)(data.(ind)) = value;         
        elseif strcmp(type,'image') || strcmp(type,'cell')
            if strcmp(type,'image')
                if ~exist(imgdir,'dir')
                    mkdir(imgdir);
                end
                imgfilename = sprintf('%s-%d.jpg',var,data.(ind));
                imwrite(value,fullfile(imgdir,imgfilename));
                value = imgfilename;
            end
            if length(data.(var)) < data.(ind)
                data.(var) = [data.(var);cell(data.(ind)+parser.Results.blocksize,1)];
            end
            data.(var){data.(ind)} = value;        
        else            
            vecvalue = reshape(value,1,[]);
            if length(data.(var)) < data.(ind)
                data.(var) = [data.(var);nan(data.(ind)+parser.Results.blocksize,length(vecvalue))];
            end
            data.(var)(data.(ind),:) = vecvalue;
        end
        checkflush();
    end

    function message(format,varargin)
        msg = sprintf(format,varargin{:});
        log('messages',msg);
        if parser.Results.verbosity
            disp(msg);
        end
    end

    function checkflush()
        sinceflush = sinceflush + 1;
        if sinceflush >= parser.Results.flushinterval
            flush();
        end
    end

    function flush()
        sinceflush = 0;
        path = fileparts(fullpath);
        if ~exist(path,'dir')
            mkdir(path);           
        end  
        expdata = exported_data();
        save(fullpath,'-struct','expdata');
    end

    function ret = exported_data()
        ret = data;
        fnames = fieldnames(data);
        for i = 1:length(fnames)
           name = fnames{i};
           postfix = name(max(end-length(INDEX_POSTFIX)+1,1):end);
           if strcmp(postfix,INDEX_POSTFIX)
               var = name(1:(end-length(INDEX_POSTFIX)));
               val = ret.(var);
               ind = ret.(name);
               if iscell(val) || isstruct(val)
                   ret.(var) = val(1:ind);
               else
                   ret.(var) = val(1:ind,:);
               end
               ret = rmfield(ret,name);
           end
        end
    end

    function ret = get_absolute_path(path)
        file = java.io.File(path);
        if ~file.isAbsolute()
            file = java.io.File(fullfile(cd,path));
        end
        ret = file.getAbsolutePath();    
    end

    ret = struct('log',@log,'flush',@flush,'message',@message,'get_filename',@()fullpath);
end    
    