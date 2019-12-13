function ret = bandit_ctrl(reward,num_bandits,varargin) 
    default_draw = false;
    default_ucb_constant = 1;
    default_epsilon = 0.1;
    default_bandit_decay = 1;
    default_bandit_variant = 'ucb1';
    expected_variants = {'eps-greedy','ucb1','ism-normal2'};

    parser = inputParser;
    parser.addRequired('reward',@(x)isa(x,'function_handle'));    
    parser.addRequired('num_bandits',@isnumeric);    
    parser.addParameter('ucb1_constant',default_ucb_constant,@isnumeric);    
    parser.addParameter('epsilon',default_epsilon,@isnumeric);    
    parser.addParameter('bandit_decay',default_bandit_decay,@isnumeric);    
    parser.addParameter('bandit_variant',default_bandit_variant,...
        @(x) any(validatestring(x,expected_variants)));    
    parser.addParameter('draw',default_draw);    
    parser.KeepUnmatched = true;
    parse(parser,reward,num_bandits,varargin{:});           
    param = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));  
        
    played = zeros(1,param.num_bandits);  
    means = zeros(1,param.num_bandits);
    vars = zeros(1,param.num_bandits);
    logging.log('bandit_counts',played);
    
    
    
    if param.draw
        figure;           
        h_bar = bar(zeros(1,num_bandits));
        drawerrors = strcmp(param.bandit_variant,'ucb1') || ...
            strcmp(param.bandit_variant,'ism-normal2');        
        if drawerrors
            hold on;
            h_err = errorbar(zeros(1,num_bandits),zeros(1,num_bandits),'.');
        end
        colormap hot;       
    end
    
    ret = @step;    
    
    function step()        
        n = sum(played) + 1; % time indices go from 1
        stdev = sqrt(vars);
        switch(param.bandit_variant)
            case 'eps-greedy'                
                a = find(~played,1); % Play all bandits at least once                
                if isempty(a) && rand() < param.epsilon
                    a = randi([1,num_bandits],1);                
                end
                cb = 0;                    
            case 'ucb1'
                a = find(~played,1); % Play all bandits at least once                
                cb = param.ucb1_constant * sqrt(2*log(n)./played);                           
            case 'ism-normal2' % Ref. Cowan et al. J. Mach. Learn. Res. 18 (2018) 1-28
                % Notice that UCB1-normal and ISM-normal0 were tested
                % and did not seem to work...
                ind = played < 3;
                k = 1:length(played);
                k = k(ind);
                [~,minind] = min(played(ind));
                a = k(minind);
                cb = stdev .* sqrt(max(n .^ (2 ./ (played - 2)) - 1,0));   
        end
        
        if isempty(a)                    
            [~,a] = max(means + cb);
        end
        
        if param.draw
            h_bar.YData = means;
            if drawerrors
                h_err.YData = means;            
                h_err.YPositiveDelta = cb;                
            end
        end   
        
        logging.log('bandit_actions',a);
        r = param.reward(a);        
        logging.log('bandit_rewards',r);     
        % Exponentially decaying memory
        played = param.bandit_decay * played;
        played(a) = played(a) + 1;
        deltamean = r - means(a);
        % Updating means, in recursive form
        means(a) = means(a) + deltamean / played(a);
        deltavar = deltamean * (r - means(a)) - vars(a);
        % Updating variances, in recursive form. Notice r - means(a) is
        % computed before and after updating means(a)
        vars(a) = vars(a) + deltavar / played(a); % biased estimator        
        logging.log('bandit_played',played);        
        logging.log('bandit_means',means);        
        logging.log('bandit_vars',vars);        
    end
end