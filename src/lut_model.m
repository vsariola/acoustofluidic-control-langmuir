function ret = lut_model(varargin)	
    import logging.*;
    
    parser = inputParser;
    parser.addParameter('lutfile',[],@ischar);    
    parser.KeepUnmatched = true;
    parse(parser,varargin{:});    
    r = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(r));     
    
    if isempty(r.lutfile)
        path = fileparts(mfilename('fullpath'));
        lutfile = fullfile(path,'..','data','example_lut.mat');   
    else
        lutfile = r.lutfile;
    end
    
    message('Initializing LUT model: lutfile = ''%s''',lutfile);

    data = load(lutfile);            
    xx = linspace(0,data.chipwidth,size(data.dx,2));
    yy = linspace(0,data.chipheight,size(data.dx,1));
    intrp = @(xq,yq,v)interp2(xx,yy,squeeze(v),xq,yq,'linear',0);
    
    message('LUT model: numfreq = %d, chipwidth = %g, chipheight = %g',size(data.dx,3),data.chipwidth,data.chipheight);
        
    ret = struct('dx',@(x,y,i)intrp(x,y,data.dx(:,:,i)), ...
        'dy',@(x,y,i)intrp(x,y,data.dy(:,:,i)), ...
        'residual',@(x,y,i)intrp(x,y,data.residual(:,:,i)), ...
        'chipwidth',data.chipwidth, ...
        'chipheight',data.chipheight, ...
        'numfreq',size(data.dx,3), ...
        'freq',data.freq, ...
        'amp',data.amp);
end
    
    