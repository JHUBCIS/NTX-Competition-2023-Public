classdef EmgJacksonPollock < Scenarios.ScenarioBase
    % Scenario that involves a user interface for painting with EMG
    %
    % 01-Sept-2010 Armiger: Created
    
    properties
    end
    methods
        function obj = EmgJacksonPollock
            % Creator
        end
        
        function initialize(obj)
            assert(~isempty(obj.SignalSource));
            assert(~isempty(obj.SignalClassifier));
%             assert(~isempty(obj.TrainingInterface));
        end
        
        function begin_training(obj)
            
%             [features3D classLabelId] = obj.TrainingInterface.collectdata(obj.SignalSource,obj.SignalClassifier);
%             %save('test3.dat','features3D','classLabelId')
%             %load('test3.dat','-mat')
%             
%             obj.SignalClassifier.TrainingData = features3D;
%             obj.SignalClassifier.TrainingDataLabels = classLabelId;
%             obj.SignalClassifier.train();
%             obj.SignalClassifier.computeError();
        end
        function run(obj)
            a = Presentation.Pollock;
            %a.initialize;
            cursorPosition = [50 50];
            lastCursorPosition = cursorPosition;
            timeoutCount = 0;
            
            screenSize = get(0, 'screensize');
            limits = [ 50 150 screenSize(3)-750 screenSize(4)-150];
            
            dX = 0;
            dY = 0;
            
            obj.SignalSource.NumSamples = obj.SignalClassifier.NumSamplesPerWindow;
            
            tic
            while toc < 120
                disp('Running')
                drawnow
                windowData = obj.SignalSource.getFilteredData();
                features2D = obj.SignalClassifier.extractfeatures(windowData);
                activeChannelFeatures = features2D(obj.SignalClassifier.getActiveChannels,:);
                [classOut, voteDecision] = obj.SignalClassifier.classify(reshape(activeChannelFeatures',[],1));
                
                if obj.SignalClassifier.NumMajorityVotes > 1
                    cursorMoveClass = voteDecision;
                else
                    cursorMoveClass = classOut;
                end
                
                virtualChannels = obj.SignalClassifier.virtual_channels(features2D,cursorMoveClass);
                
                speed = max(virtualChannels);
                
                classNames = obj.SignalClassifier.getClassNames;
                
                switch classNames{cursorMoveClass}
                    case 'No Movement'
                        dX = 0;
                        dY = 0;
                    case'Right'
                        dX = 50*speed*rand;
                    case 'Left'
                        dX = -50*speed*rand;
                    case 'Down'
                        dY = 50*speed*rand;
                    case 'Up'
                        dY = -50*speed*rand;
                    otherwise
                end
                
                cursorPosition = cursorPosition + [dX dY];
                
                cursorPosition(1) = max(limits(1),min(cursorPosition(1),limits(3)));
                cursorPosition(2) = max(limits(2),min(cursorPosition(2),limits(4)));
                
                if isequal(lastCursorPosition,cursorPosition)
                    timeoutCount = timeoutCount + 1;
                else
                    timeoutCount = 0;
                end
                
                if timeoutCount == 50
                    %a.click;
                    %beep;
                end
                
                if timeoutCount > 500
                    break;
                end
                
                Presentation.Pollock.update_cursor(cursorPosition(1),cursorPosition(2));
                lastCursorPosition = cursorPosition;
            end
            a.minimize_window;
        end
    end
    methods (Static = true)
        function obj = Default
            %%
            

            
            %%
            
            % obj.SignalSource = Inputs.DaqHwDevice('mcc',0);
            % obj.SignalSource.initialize();
            % obj.SignalSource.addfilter(Inputs.HighPass());
            % obj.SignalSource.addfilter(Inputs.LowPass());
            % obj.SignalSource.addfilter(Inputs.Notch());
            
            % Get Inptu Source
            SignalSource = Inputs.MyoUdp.getInstance();
            SignalSource.initialize();
            
            % Setup trainig data container
            TrainingData = PatternRecognition.TrainingData();
            
            % Setup classifier
            SignalClassifier = SignalAnalysis.Lda();
            SignalClassifier.initialize(TrainingData);
            SignalClassifier.setClassNames({'No Movement' 'Up' 'Down' 'Left' 'Right'});
            SignalClassifier.setActiveChannels(1:8);
            SignalClassifier.NumMajorityVotes = 7;
            
            % Train            
            TrainingInterface = PatternRecognition.SimpleTrainer();
            if 0
                %%
                TrainingInterface.NumRepetitions = 2;  % <-- Adjust (2 to 3 typical)
                TrainingInterface.ContractionLengthSeconds = 2; % <-- Time to hold contraction (avoid muscle fatigue)
                TrainingInterface.DelayLengthSeconds = 3; % <-- Recovery Time in seconds between contractions
                TrainingInterface.initialize(SignalSource,SignalClassifier,TrainingData);
                TrainingInterface.collectdata();
            end
            %TrainingData.loadTrainingData('*.trainingData');
            TrainingData.loadTrainingData('myo_mouse.trainingData');
            
            SignalClassifier.train();
            SignalClassifier.computeError();
            
            %%
            obj = Scenarios.EmgJacksonPollock();
            obj.SignalSource = SignalSource;
            obj.SignalClassifier = SignalClassifier;
            obj.initialize()
            obj.launch
            %%
            obj.run()

        end
    end
end
