function finish()
    global global_logger;
    if ~isempty(global_logger)
        global_logger.flush(); % flush the logger before creating a new one
    end
    global_logger = [];
end