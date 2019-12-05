function ret = ucb1(reward,num_bandits,varargin) 
    parser = inputParser;
    parser.addRequired('reward',@(x)isa(x,'function_handle'));    
    parser.addRequired('num_bandits',@isnumeric);    
    parser.addParameter('ucb_constant',1,@isnumeric);    
    parser.addParameter('ucb_decay',1,@isnumeric);    
    parser.KeepUnmatched = true;
    parse(parser,reward,num_bandits,varargin{:});           
    param = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));  
        
    played = zeros(1,param.num_bandits);  
    means = zeros(1,param.num_bandits);
    logging.log('ucb_counts',played);
    
    ret = @step;    
    
    function step()        
        a = find(~played,1); % In the beginning, choose every action once
        if isempty(a)
            s = sum(played);
            [~,a] = max(means + param.ucb_constant * sqrt(2*log(s)./played));
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