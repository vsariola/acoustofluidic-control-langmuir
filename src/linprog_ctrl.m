function ret = linprog_ctrl(model,varargin)
    default_var_weight = 0.5;
    default_draw = false;

    parser = inputParser;    
    parser.addRequired('model');        
    parser.addParameter('var_weight',default_var_weight,@isnumeric);    
    parser.addParameter('draw',default_draw);           
    parser.KeepUnmatched = true;    
    parse(parser,model,varargin{:});           
    param = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));     
    
    totals = zeros(param.model.numfreq,1);    
    options = optimset('Display', 'off');
   
    if param.draw
       figure;
       h_bar = bar(zeros(1,model.numfreq));
       ylim([0,1]);
       colormap hot;
    end
    
    ret = @step;       
    
    function n = step(p,delta)        
        numobj = size(delta,1);        
        logging.log('linprog_positions',p);       
        logging.log('linprog_directions',delta);        
        Aeq = zeros(numobj*2,param.model.numfreq);    
        residuals = zeros(1,param.model.numfreq);
        for i = 1:param.model.numfreq
            dx = param.model.dx(p(:,1),p(:,2),i);
            dy = param.model.dy(p(:,1),p(:,2),i);
            Aeq(:,i) = [dx;dy];    
            residuals(i) = sqrt(sum(param.model.residual(p(:,1),p(:,2),i).^2));
        end
        beq = reshape(delta,[],1);
        lowerbounds = zeros(param.model.numfreq,1);
        x = linprog(param.var_weight*residuals+(1-param.var_weight),[],[], ...
            Aeq,beq,lowerbounds,[],[],options);                
        if (isempty(x) || all(abs(x)<1e-12))
            x = ones(param.model.numfreq,1);
            logging.message('Warning: could not solve linear programming problem');
        end
        logging.log('linprog_freqweights',x);
        r = 1 - totals;        
        alpha = r ./ x;
        [minalpha,n] = min(alpha);
        totals = totals + minalpha * x;
        if param.draw
            cdata = zeros(size(totals));
            cdata(n) = 64;
            h_bar.YData = totals;
            h_bar.CData = cdata;
        end
    
        totals(n) = 0;        
        logging.log('linprog_totals',totals);        
    end
end