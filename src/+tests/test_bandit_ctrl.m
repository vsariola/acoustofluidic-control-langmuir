classdef test_bandit_ctrl < matlab.unittest.TestCase    
    properties (TestParameter)
        winrate = {[.75,.25*ones(1,9)],[1,0],[0,1],[0.4,0.6,0.4]};
        plays = {300,1000};
        variant = {'eps-greedy','ucb1','ism-normal2'};       
        decay = {1,0.99};
    end
    
    methods (Test)
        function test_ucb_variants(testCase,winrate,plays,variant,decay)   
            played = zeros(1,length(winrate));
            function ret = ucb_reward(n)
                played(n) = played(n)+1;
                ret = 1.0*(rand()<winrate(n));
            end
            rng(0);
            u = bandit_ctrl(@ucb_reward,length(winrate),'bandit_variant',variant,'bandit_decay',decay);
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