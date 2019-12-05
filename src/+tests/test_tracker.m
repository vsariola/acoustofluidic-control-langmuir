classdef test_tracker < matlab.unittest.TestCase    
    methods (Test)
        function test_init(testCase)      
            init_pos = [0,0];
            t = tracker(init_pos);
            p = t.get_pos();
            testCase.verifyEqual(p,init_pos);
        end
        
        function test_init_multiple(testCase)      
            init_pos = [0,0;1,1];
            t = tracker(init_pos);
            p = t.get_pos();
            testCase.verifyEqual(p,init_pos);
        end
        
        function test_match(testCase)      
            init_pos = [5,2];
            t = tracker(init_pos);
            p1 = t.get_pos();  
            testCase.verifyEqual(p1,init_pos);            
            next_pos = [5.1,2.1];
            t.update_pos(next_pos);
            p2 = t.get_pos();
            testCase.verifyEqual(p2,next_pos);
        end
        
        function test_match_multiple(testCase)      
            init_pos = [5,2;7,3];
            t = tracker(init_pos);
            p1 = t.get_pos();  
            testCase.verifyEqual(p1,init_pos);            
            next_pos = [7.1,2.9;5.1,2.1];
            t.update_pos(next_pos);
            p2 = t.get_pos();
            expected = [5.1,2.1;7.1,2.9];
            testCase.verifyEqual(p2,expected);
        end
    end   
end