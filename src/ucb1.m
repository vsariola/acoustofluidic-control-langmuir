function ret = ucb1(reward,num_bandits,varargin) 
    default_draw = false;

    parser = inputParser;
    parser.addRequired('reward',@(x)isa(x,'function_handle'));    
    parser.addRequired('num_bandits',@isnumeric);    
    parser.addParameter('ucb_constant',1,@isnumeric);    
    parser.addParameter('ucb_decay',1,@isnumeric);    
    parser.addParameter('draw',default_draw);    
    parser.KeepUnmatched = true;
    parse(parser,reward,num_bandits,varargin{:});           
    param = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));  
        
    played = zeros(1,param.num_bandits);  
    means = zeros(1,param.num_bandits);
    logging.log('ucb_counts',played);
    
    if param.draw
       figure;           
       h_bar = bar(zeros(1,num_bandits));
       hold on;
       h_err = errorbar(zeros(1,num_bandits),zeros(1,num_bandits),'.');
       colormap hot;
    end
    
    ret = @step;    
    
    function step()        
        a = find(~played,1); % In the beginning, choose every action once                                
        if isempty(a)            
            cb = param.ucb_constant * sqrt(2*log(sum(played))./played);
            [~,a] = max(means + cb);
            if param.draw
                h_bar.YData = means;
                h_err.YData = means;
                h_err.YPositiveDelta = cb;
                h_err.YNegativeDelta = cb;
            end   
        end     
        logging.log('ucb_actions',a);
        r = param.reward(a);        
        logging.log('ucb_rewards',r);     
        % Exponentially decaying memory
        played = param.ucb_decay * played;
        played(a) = played(a) + 1;
        means(a) = (means(a)*(played(a)-1) + r)/played(a);
        logging.log('ucb_counts',played);        
    end
end