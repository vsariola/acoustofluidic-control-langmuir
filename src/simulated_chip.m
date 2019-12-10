function ret = simulated_chip(model,varargin)	
    default_numparticles = 1;
    default_errorprob = 0;
    default_startpos = [];
    default_randomness = 1;
    default_draw = false;
        
    parser = inputParser;    
    parser.addRequired('model',@isstruct);        
    parser.addParameter('numparticles',default_numparticles,@isnumeric);        
    parser.addParameter('errorprob',default_errorprob);   
    parser.addParameter('startpos',default_startpos);
    parser.addParameter('randomness',default_randomness);
    parser.addParameter('draw',default_draw);    
    parser.KeepUnmatched = true;
    parse(parser,model,varargin{:});    
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));    
    
    r = parser.Results;     
        
    if isempty(r.startpos)
        angles = linspace(0,2*pi,r.numparticles+1);
        angles = angles(1:(end-1))';
        pos = ([cos(angles),sin(angles)]/4+.5) .* [model.chipwidth,model.chipheight];
    else
        pos = r.startpos;
    end
    logging.log('chip_pos',pos);
    
    if r.draw
        figure;
        ax = axes;
        draw();
    end
    
    function ret = get_pos()
        % Randomly permutate and drop particle positions, to simulate
        % a real situation that the machine vision does not always return
        % the particles in same order and might not detect them
        ind = rand(1,r.numparticles) >= r.errorprob;
        ret = pos(ind,:);
        ret = ret(randperm(size(ret,1)),:);
        logging.log('chip_getpos',ret,'cell');
        if r.draw
            draw();
        end
    end

    function output(n)
        dx = model.dx(pos(:,1),pos(:,2),n);
        dy = model.dy(pos(:,1),pos(:,2),n);        
        residual = model.residual(pos(:,1),pos(:,2),n);
        logging.log('chip_output',n);
        logging.log('chip_dx',dx);
        logging.log('chip_dy',dx);
        logging.log('chip_residual',dx);
        pos = pos + [dx,dy] + r.randomness * randn(r.numparticles,2) .* residual;
        pos = max(min(pos,[model.chipwidth,model.chipheight]),[0,0]);                        
        logging.log('chip_pos',pos);
    end

    function draw()
        plot(ax,pos(:,1),pos(:,2),'ko');        
        xlim(ax,[0,model.chipwidth]);
        ylim(ax,[0,model.chipheight]);     
        set(ax,'YDir','reverse');
    end

    ret = struct('get_pos',@get_pos,'output',@output,'numfreq',model.numfreq);
end