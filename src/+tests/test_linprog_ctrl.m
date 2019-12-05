classdef test_linprog_ctrl < matlab.unittest.TestCase    
    properties (TestParameter)
        dirs = {[0,-1;-1,0;1,1],[0,-1;0,0;1,1]};
        target = {[1,1],[0,-100]};
        expected_freq = {3,1}
    end
    
    methods (Test, ParameterCombination='sequential')
        function test_dir_choose(testCase,dirs,target,expected_freq)   
            model = struct(...
                'dx',@(x,y,i)dirs(i,1), ...
                'dy',@(x,y,i)dirs(i,2), ...
                'residual',@(x,y,i)1, ...
                'numfreq',size(dirs,1));
            ctrl = linprog_ctrl(model);                
            for i = 1:100
                n = ctrl([0,0],target);
                testCase.assertEqual(n,expected_freq);
            end            
        end        
    end   
end