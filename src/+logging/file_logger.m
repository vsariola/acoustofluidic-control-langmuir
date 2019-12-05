function ret = file_logger(varargin)
    default_logname = '../results/log';
    default_logfilename = 'timestamp';
    default_flushinterval = 1000;
    default_blocksize = 200;
        
    parser = inputParser;
    parser.addParameter('logname',default_logname,@ischar);            
    parser.addParameter('logfilename',default_logfilename,@ischar);
    parser.addParameter('flushinterval',default_flushinterval,@isnumeric);
    parser.addParameter('blocksize',default_blocksize,@isnumeric);
    parser.addParameter('verbosity',true);    
    parser.KeepUnmatched = true;
    parse(parser,varargin{:});       
    
    if strcmp(parser.Results.logfilename,'timestamp')
        symbols = ['a':'z' 'A':'Z'];
        randstring = symbols(randi(numel(symbols),[1 8]));
        filename = sprintf('%s-%s-%s.mat',...
            parser.Results.logname,...
            datestr(datetime('now'),'yyyy-mm-dd--HH-MM-SS'),...
            randstring);     
    else
        filename = parser.Results.logfilename;
    end

    if java.io.File(filename).isAbsolute()
        fullpath = filename;
    else
        fullpath = fullfile(cd,filename);
    end
        
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
            elseif ischar(value)
                type = 'cell';
            else
                type = 'double';
            end
        end
        ind = [var '_index'];
            
        if strcmp(type,'cell')
            if ~isfield(data,var) 
                data.(var) = {};
                data.([var '_index']) = 0;
            end
            data.(ind) = data.(ind) + 1;
            if length(data.(var)) < data.(ind)
                data.(var) = [data.(var);cell(data.(ind)+parser.Results.blocksize,1)];
            end
            data.(var){data.(ind)} = value;
        else
            if ~isfield(data,var) 
                data.(var) = [];
                data.([var '_index']) = 0;
            end
            data.(ind) = data.(ind) + 1;
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
        save(filename,'-struct','data');
    end

    ret = struct('log',@log,'flush',@flush,'message',@message,'get_filename',@()fullpath);
end    
    