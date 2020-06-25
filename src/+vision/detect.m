function p = detect(img,varargin) 
% Detect: Find either particles or cells from an image, depending on
% 'detector' setting    
    def_detector = 'particles'; % use particle detector by default
    
    parser = inputParser;
    parser.addRequired('img',@isnumeric);   
    parser.addParameter('detector',def_detector);        
    parser.KeepUnmatched = true;
    parse(parser,img,varargin{:});  
    
    if strcmp(parser.Results.detector,'cells')
        p = vision.detect_cells(img,varargin{:});
    else
        p = vision.detect_particles(img,varargin{:});
    end        
end