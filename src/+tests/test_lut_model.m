classdef test_lut_model < matlab.unittest.TestCase    
    properties (TestParameter)
        point = {[.25,.25],[.5,.5],[.75,.75],[.25,.75]};
        freq = {1,2,50};
    end
    
    methods (Test)
        function test_properties(testCase)      
            m = lut_model();
            testCase.verifyEqual(length(m.freq),m.numfreq);
            testCase.verifyEqual(length(m.amp),m.numfreq);
            testCase.verifyGreaterThan(m.chipwidth,0);
            testCase.verifyGreaterThan(m.chipheight,0);            
            testCase.verifyGreaterThan(m.numfreq,0);         
        end
        
        function test_model(testCase,point,freq)      
            m = lut_model();
            testCase.assertGreaterThan(m.numfreq,0); 
            p = point .* [m.chipwidth,m.chipheight];
            testCase.verifyEqual(size(m.dx(p(1),p(2),freq)),[1,1]);            
            testCase.verifyNotEqual(m.dx(p(1),p(2),freq),0);
            testCase.verifyEqual(size(m.dy(p(1),p(2),freq)),[1,1]);            
            testCase.verifyNotEqual(m.dy(p(1),p(2),freq),0);
            testCase.verifyEqual(size(m.residual(p(1),p(2),freq)),[1,1]);            
            testCase.verifyGreaterThan(m.residual(p(1),p(2),freq),0);            
        end       
    end   
end