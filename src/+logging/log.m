function log(varargin)
    global global_logger;
    if ~isempty(global_logger)       
        global_logger.log(varargin{:});
    end
end