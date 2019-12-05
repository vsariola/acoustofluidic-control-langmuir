function message(varargin)
    global global_logger;
    if ~isempty(global_logger)            
        global_logger.message(varargin{:});
    end
end