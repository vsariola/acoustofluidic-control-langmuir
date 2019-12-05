function control_loop(varargin)
    default_model = 'lut';    
    default_chip = 'real';
	default_controller = 'linprog';    
    default_task = 'pathfollow';    
    default_grad_eps = 1e-6;
    default_draw = false;    
    
    expected_model = {'lut'};
    expected_chip = {'real','simulated'};  
    expected_controller = {'linprog','ucb1'};      
    expected_task = {'pathfollow'};  

    parser = inputParser;
    parser.addParameter('model',default_model, ... 
        @(x) isstruct(x) || any(validatestring(x,expected_model)));    
    parser.addParameter('chip',default_chip, ... 
        @(x) isstruct(x) || any(validatestring(x,expected_chip)));    
    parser.addParameter('controller',default_controller, ... 
        @(x) isstruct(x) || any(validatestring(x,expected_controller)));    
    parser.addParameter('task',default_task, ... 
        @(x) isstruct(x) || any(validatestring(x,expected_task)));      
    parser.addParameter('draw',default_draw);
    parser.addParameter('grad_eps',default_grad_eps);
    parser.KeepUnmatched = true;
    parse(parser,varargin{:});
            
    logging.init(varargin{:});
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));
    
    if ischar(parser.Results.model)
        switch(parser.Results.model)         
            case 'lut'
                model = lut_model(varargin{:});                   
            otherwise % Customer controller supplied by the user
                error('Unknown model name');
        end
    else
        model = parser.Results.model;            
    end
    
    if ischar(parser.Results.chip)    
        switch parser.Results.chip
            case 'real'            
                chip = real_chip(model,varargin{:});            
            case 'simulated'
                chip = simulated_chip(model,varargin{:});        
            otherwise % Customer chip supplied by the user
                error('Unknown chip name');
        end
    else
        chip = parser.Results.chip;            
    end
    
    if ischar(parser.Results.task)
        switch parser.Results.task
            case 'pathfollow'
                first_detection = chip.get_pos();
                task = pathfollow_task('first_detection',first_detection, ...
                    varargin{:});                    
            otherwise % Customer task supplied by the user
                error('Unknown task name');        
        end
    else
        task = parser.Results.task;                    
    end           
    
    if ischar(parser.Results.controller)
        switch parser.Results.controller
            case 'linprog'
                my_linprog_ctrl = linprog_ctrl(model,varargin{:});
                step = @linprog_step;
            case 'ucb1'                
                step = ucb1(@bandit_reward,chip.numfreq,varargin{:});
            otherwise
                error('Unknown controller name');
        end
    else
        step = parser.Results.controller;                    
    end   
        
    logging.message('Control starting at %s.',datestr(datetime('now')));    
        
    tic;
    total_steps = 0;
    while ~task.is_completed()
        step();
        if parser.Results.draw            
            drawnow;
        end
        total_steps = total_steps + 1;
    end
    total_time = toc;
        
    logging.message('Control completed in %d steps / %f seconds.',total_steps,total_time);    
    
    logging.flush();
    
    %----------------
    % Inner functions
    %----------------
    function linprog_step                                       
        h = parser.Results.grad_eps;
        pos = task.get_pos();
        dir = zeros(size(pos));
        for i = 1:length(pos(:))
            p1 = pos;
            p1(i) = p1(i) - h;
            p2 = pos;
            p2(i) = p2(i) + h;
            % dir is the central difference gradient of the cost
            % pointing towards decreasing cost i.e.
            % dir = - grad cost(x1,y1,x2,y2,...)
            dir(i) = (task.get_cost(p1) - task.get_cost(p2)) / (2*h);
        end    
        n = my_linprog_ctrl(pos,dir);
        chip.output(n);        
        task.update_pos(chip.get_pos());
        task.update_progress();
    end

    function ret = bandit_reward(n)
        before = task.get_cost(task.get_pos());
        chip.output(n);
        task.update_pos(chip.get_pos());
        after = task.get_cost(task.get_pos());                
        task.update_progress();
        ret = before - after; % When the cost goes down, reward should be positive
    end
end
    
    
    
    
    
    
    
    