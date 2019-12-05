classdef test_simulated_chip < matlab.unittest.TestCase    
    properties (TestParameter)
        numparticles = {1,2,10};
        freq = {1,2,50};
    end
    
    properties
        model
    end
    
    methods(TestMethodSetup)
        function init_model(testCase)
            testCase.model = lut_model();
        end
    end

    methods (Test)
        function testParticles(testCase,numparticles)
            chip = simulated_chip(testCase.model,'numparticles',numparticles);
            p = chip.get_pos();
            testCase.verifyTrue(all(all(p>0)));
            testCase.verifyEqual(size(p),[numparticles,2]);
        end
        
        function testParticleMotion(testCase,freq,numparticles)
            chip = simulated_chip(testCase.model,'numparticles',numparticles);
            p1 = chip.get_pos();
            chip.output(freq);
            p2 = chip.get_pos();
            testCase.verifyNotEqual(p1,p2);
        end
    end   
end