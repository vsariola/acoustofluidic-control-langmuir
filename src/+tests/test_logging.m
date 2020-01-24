classdef test_logging < matlab.unittest.TestCase                
    methods(TestMethodSetup)
        function initLogger(testCase)
            logging.init('verbosity',false);
        end
    end
    
    methods(TestMethodTeardown)
        function deleteLogger(testCase)
            file = logging.get_filename();
            logging.finish();
            delete(file);
        end
    end
    
    methods (Test)
        function testFileCreation(testCase)
            testCase.verifyEqual(exist(logging.get_filename(),'file'),2);
        end
        
        function testMessage(testCase)
            testMsg = 'Testing!';
            logging.message(testMsg);
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(D.messages{1},testMsg);
        end
        
        function testFormatMessage(testCase)
            testFormat = 'Test %d %s!';
            logging.message(testFormat,1,'2');
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(D.messages{1},'Test 1 2!');
        end
        
        function testCell(testCase)
            testvalue = [1,2,3];
            logging.log('testdata',testvalue,'cell');
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(D.testdata{1},testvalue);
        end
                
        function testManyCells(testCase)
            testvalue = [1,2,3];
            numvalues = 1000;
            for i = 1:numvalues
                logging.log('testdata',testvalue,'cell');
            end
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(length(D.testdata),numvalues);
            for i = 1:numvalues
                testCase.assertEqual(D.testdata{i},testvalue);
            end            
        end
        
        function testStruct(testCase)
            testvalue = struct('a',5,'b',[1 2],'c','hello');
            logging.log('testdata',testvalue);
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(D.testdata(1),testvalue);
        end
                
        function testManyStructs(testCase)
            testvalue = struct('a',5,'b',[1 2],'c','hello');
            numvalues = 1000;
            for i = 1:numvalues
                logging.log('testdata',testvalue);
            end
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(length(D.testdata),numvalues);
            for i = 1:numvalues
                testCase.assertEqual(D.testdata(i),testvalue);
            end
        end
        
        function testDouble(testCase)
            testvalue = [1,2,3];
            logging.log('testdata',testvalue);
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(D.testdata(1,:),testvalue);
        end
        
        function testDoubleReshaping(testCase)
            testvalue = [1,2;3,4;5,6]; % Data should flatten into 1 x 6 row
            logging.log('testdata',testvalue);
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(D.testdata(1,:),reshape(testvalue,1,[]));
        end
               
        function testManyDoubles(testCase)
            testvalue = [1,2,3];
            numvalues = 1000;
            for i = 1:numvalues
                logging.log('testdata',testvalue);
            end
            logging.flush();
            D = load(logging.get_filename());
            testCase.assertEqual(length(D.testdata),numvalues);
            for i = 1:numvalues
                testCase.assertEqual(D.testdata(i,:),testvalue);
            end
        end    
    end   
end