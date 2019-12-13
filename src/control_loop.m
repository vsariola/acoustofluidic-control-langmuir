function control_loop(varargin)
    default_model = 'lut';    
    default_chip = 'real';
	default_controller = 'linprog';    
    default_task = 'pathfollow';    
    default_grad_eps = 1e-6;
    default_draw = false;  
    default_close_all = true;
    
    expected_model = {'lut'};
    expected_chip = {'real','simulated'};  
    expected_controller = {'linprog','bandit'};      
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
    parser.addParameter('close_all',default_close_all);    
    parser.KeepUnmatched = true;
    parse(parser,varargin{:});
            
    logging.init(varargin{:});
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));
       
    if parser.Results.draw            
        if parser.Results.close_all
            close all;
        end
    end
    
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
                    'chipwidth',model.chipwidth,'chipheight',model.chipheight,...
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
            case 'bandit'                
                step = bandit_ctrl(@bandit_reward,chip.numfreq,varargin{:});
            otherwise
                error('Unknown controller name');
        end
    else
        step = parser.Results.controller;                    
    end   
        
    logging.message('Control starting at %s.',datestr(datetime('now')));    
    
    uifig = uifigure('Position',[100 100 200 100]);        
    btn = uibutton(uifig,'push',...
               'Text','Emergency stop', ...
               'Position',[0,0,200,100],...
               'ButtonPushedFcn', @(btn,event) set_stopped());    
    stopped = false;
    
    tstart = tic;
    t_since = tic;    
    total_steps = 0;
    total_steps_since = 0;
    while ~task.is_completed() && ~stopped
        step();        
        drawnow;     
        total_steps = total_steps + 1;
        total_steps_since = total_steps_since + 1;
        time_since = toc(t_since);
        if time_since > 3
            uifig.Name = sprintf('%.2g steps per second',total_steps_since / time_since);
            total_steps_since = 0;
            t_since = tic;
        end
    end    
    total_time = toc(tstart);
    
    logging.message('Control completed in %d steps / %f seconds.',total_steps,total_time);    
    
    close(uifig);
    chip.output(0);
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

    function set_stopped()
        logging.message('Emergency stop hit!');    
        stopped = true;
    end
end
    
    
    
    
    
    
    
    