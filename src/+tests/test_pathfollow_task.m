classdef test_pathfollow_task < matlab.unittest.TestCase    
    properties (TestParameter)
        start = {[1,1],[5,2]};
        via = {[3,1],[5,1]};
        endp = {[2,3],[1,3]};        
        minsegment = {-Inf,0.1};
        maxsegment = {0.1,10,Inf};
    end
    
    methods (Test)
        function test_path_follow(testCase,start,via,endp,minsegment,maxsegment)   
            t = pathfollow_task('paths',[start;via;endp], ...
                'minsegment',minsegment,'maxsegment',maxsegment);
            numpoints = 100;
            testCase.assertFalse(t.is_completed());
            for w = linspace(0,1,numpoints)
                p = start * (1-w) + via * w;
                t.update_pos(p);
                t.update_progress();
            end
            testCase.assertFalse(t.is_completed());
            for w = linspace(0,1,numpoints)
                p = via * (1-w) + endp * w;
                t.update_pos(p);
                t.update_progress();
            end
            testCase.assertTrue(t.is_completed());
        end     
        
        function test_multi_part_finish(testCase)   
            p = [1,1;3,3];
            t = pathfollow_task('paths',{[1,1;2,2],[3,3;4,4]});
            numpoints = 100;
            testCase.assertFalse(t.is_completed());            
            function goto(target)
                p0 = p;
                for w = linspace(0,1,numpoints)
                    p = p0 * (1-w) + target * w;
                    t.update_pos(p);
                    t.update_progress();
                end
            end
            goto([2,2;3,3]);
            testCase.assertFalse(t.is_completed());
            goto([1,1;4,4]);
            testCase.assertFalse(t.is_completed());
            goto([2,2;4,4]);
            testCase.assertTrue(t.is_completed());
        end     
    end   
end