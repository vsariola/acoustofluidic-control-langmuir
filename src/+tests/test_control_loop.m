classdef test_control_loop < matlab.unittest.TestCase    
    properties (TestParameter)        
        bandit_variant = {'ucb1','ism-normal2'};
        bandit_decay = {0.99,0.99999};
        epsilon = {0.1,0.01};
        eps_decay = {0.9,0.99,0.999};
    end
    
    methods (Test)
        function test_linprog(testCase)               
            chip = simulated_chip(lut_model(),'startpos',[1,1],'randomness',0);
            control_loop('chip',chip,'paths',[1,1;3,3], ...
                'flushinterval',Inf,'controller','linprog', ...                
                'first_detection',[]);
            fname = logging.get_filename();
            logging.finish();
            delete(fname);
            curpos = chip.get_pos();
            testCase.verifyLessThan(sqrt(sum((curpos - [3,3]) .^ 2,2)),0.1);            
        end                  
    end
    
    methods (Test, ParameterCombination='sequential')
        function test_bandit(testCase,bandit_variant,bandit_decay)               
            chip = simulated_chip(lut_model(),'startpos',[1,1],'randomness',0);
            control_loop('chip',chip,'paths',[1,1;3,3], ...
                'flushinterval',Inf,'controller','bandit', ...
                'ucb1_constant',0.001,'bandit_decay',bandit_decay, ...
                'first_detection',[],'bandit_variant',bandit_variant);
            fname = logging.get_filename();
            logging.finish();
            delete(fname);
            curpos = chip.get_pos();
            testCase.verifyLessThan(sqrt(sum((curpos - [3,3]) .^ 2,2)),0.1);            
        end                  
    end

     methods (Test)
        function test_eps_greedy(testCase,epsilon,eps_decay)               
            chip = simulated_chip(lut_model(),'startpos',[1,1],'randomness',0);
            control_loop('chip',chip,'paths',[1,1;3,3], ...
                'flushinterval',Inf,'controller','bandit', ...
                'bandit_decay',eps_decay,'epsilon',epsilon, ...
                'first_detection',[],'bandit_variant','eps-greedy');
            fname = logging.get_filename();
            logging.finish();
            delete(fname);
            curpos = chip.get_pos();
            testCase.verifyLessThan(sqrt(sum((curpos - [3,3]) .^ 2,2)),0.1);            
        end                  
    end   
end