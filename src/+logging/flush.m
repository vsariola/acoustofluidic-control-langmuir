function flush(varargin)
    global global_logger;
    if ~isempty(global_logger)    
        global_logger.flush(varargin{:});
    end
end