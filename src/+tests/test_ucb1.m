classdef test_ucb1 < matlab.unittest.TestCase    
    properties (TestParameter)
        winrate = {[.75,.25*ones(1,9)],[1,0],[0,1],[0.4,0.6,0.4]};
        plays = {100,1000};
    end
    
    methods (Test)
        function test_ucb(testCase,winrate,plays)   
            played = zeros(1,length(winrate));
            function ret = ucb_reward(n)
                played(n) = played(n)+1;
                ret = 1.0*(rand()<winrate(n));
            end
            rng(0);
            u = ucb1(@ucb_reward,length(winrate));
            for i = 1:plays
                u();
            end
            [~,best] = max(winrate);
            [~,mostplayed] = max(played);
            testCase.verifyEqual(mostplayed,best);       
            testCase.verifyGreaterThan(played,0);       
        end        
    end   
end