function ret = get_filename()
    global global_logger;
    if ~isempty(global_logger)    
        ret = global_logger.get_filename();
    else
        ret = [];
    end
end