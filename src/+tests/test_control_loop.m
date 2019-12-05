classdef test_control_loop < matlab.unittest.TestCase    
    properties (TestParameter)
        controller = {'linprog','ucb1'};        
    end
    
    methods (Test)
        function test_ctrl(testCase,controller)               
            chip = simulated_chip(lut_model(),'startpos',[1,1],'randomness',0);
            control_loop('chip',chip,'paths',[1,1;3,3], ...
                'flushinterval',Inf,'controller',controller, ...
                'ucb_constant',0.001,'ucb_decay',0.999, ...
                'first_detection',[]);
            fname = logging.get_filename();
            logging.finish();
            delete(fname);
            curpos = chip.get_pos();
            testCase.verifyLessThan(sqrt(sum((curpos - [3,3]) .^ 2,2)),0.1);            
        end                  
    end   
end