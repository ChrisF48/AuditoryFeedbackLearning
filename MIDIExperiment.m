%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef MIDIExperiment < handle
    
    properties
        midisampler = [];
        mididata = [];
        
        % Screen data
        screens = [];
        screenNumber = [];
        white = -1;
        black = -1;
        window = [];
        windowrect = [];
        
        % Exp setup
        mode = 2; % learning = 1, training = 2
        currentsequpos = 1;
        learning_completed = 0;
        settings = [];       
        
        finished = 1;
        
        keyboard = [];
    end
    
    methods
        function obj = MIDIExperiment(settings,sampler)
            PsychDefaultSetup(0);
            obj.settings = settings;
            obj.midisampler = sampler;
            obj.midisampler.listener = obj;
            obj.mididata = MIDIData('');
        end
        
        % Service Methoden
        function initScreen(obj)
            Screen('Preference','SkipSyncTests',1);            
            Screen('Preference','VisualDebugLevel',0);
            obj.screens = Screen('Screens');
            obj.screenNumber = max(obj.screens);
            obj.white = WhiteIndex(obj.screenNumber);
            obj.black = BlackIndex(obj.screenNumber);
            if (~obj.settings.fullscreen)
                [obj.window, obj.windowrect] = Screen('OpenWindow',obj.screenNumber,...
                    obj.black,...
                    obj.settings.screensize);
            else
                [obj.window, obj.windowrect] = Screen('OpenWindow',obj.screenNumber,...
                    obj.black,...
                    obj.settings.fullscreensize);               
            end
            HideCursor(obj.screenNumber);
        end
        
        function closeScreen(obj)
            Screen('CloseAll');
        end
        
        function save(obj)
            obj.mididata.addData(obj.midisampler,1);
            obj.mididata.save(obj.settings.name);
        end
        
        % Draw Methoden/virtual Keyboard setup
        function drawCross(obj,centerpos,width,barwidth,color)
            r1 = [centerpos(1)-width/2 centerpos(2)-barwidth/2 centerpos(1)+width/2 centerpos(2)+barwidth/2];
            r2 = [centerpos(1)-barwidth/2 centerpos(2)-width/2 centerpos(1)+barwidth/2 centerpos(2)+width/2];
            Screen('FillRect',obj.window,color,r1);
            Screen('FillRect',obj.window,color,r2);            
        end      
        
        function drawColorCircles(obj, centerpos, relwidth, circlewidth, single)
            n = length(obj.settings.numeric_sequence);
            width = obj.windowrect(3)*relwidth;
            cw = obj.windowrect(3)*circlewidth;
            [~,~,si] = unique(obj.settings.numeric_sequence);
            
            if (single)
                color = obj.settings.finger_colors(si(obj.currentsequpos),:);
                cp = [(centerpos - [cw/2 cw/2]) (centerpos + [cw/2 cw/2])];
                Screen('FillOval',obj.window,color,cp);      
            else                  
                left = centerpos(1)-width/2;
                pos = (left:width/(n-1):left+width)';
                pos = [pos repmat(centerpos(2),n,1)];                       

                for i = obj.currentsequpos:n
                    % Position
                    cp = pos(i,:);
                    cp = [(cp - [cw/2 cw/2]) (cp + [cw/2 cw/2])];
                    % Farbe
                    color = obj.settings.finger_colors(si(i),:);
                    Screen('FillOval',obj.window,color,cp);            
                end
            end
        end
        
        function setupVisualKeyboard(obj)
            obj.keyboard = Keyboard(obj.window,obj.windowrect,...
                [obj.windowrect(3)/2 3*obj.windowrect(4)/4],0.8,0.4);
            obj.keyboard.setRange(obj.settings.keyboard_range{1},...
                obj.settings.keyboard_range{2},...
                obj.settings.keyboard_range{3},...
                obj.settings.keyboard_range{4});
        end
        
        function setupNumericSequence(obj)
            if (iscell(obj.settings.target_sequence))
                obj.settings.numeric_sequence = [];
                for i = 1:2:length(obj.settings.target_sequence)
                    n = obj.keyboard.keyToNum(obj.settings.target_sequence{i},...
                        obj.settings.target_sequence{i+1});
                    obj.settings.numeric_sequence = [obj.settings.numeric_sequence n];
                end
            else
                obj.settings.numeric_sequence = obj.settings.target_sequence;
            end
        end
        
        % Experiment
        function showPause(obj,t)
            obj.drawCross(obj.windowrect(3:4)/2,...
                obj.windowrect(3)/10,obj.windowrect(3)/50,...
                [255 0 0]);
            Screen('Flip',obj.window,0,0,1);        
            pause(t);                        
        end
        
        function showActive(obj)
            modesel = 0;
            if (obj.mode == 1)
                modesel = obj.settings.learning_visualization_mode;
            elseif (obj.mode == 2)
                modesel = obj.settings.training_visualization_mode;
            end
            switch modesel
                case 0
                    obj.drawCross(obj.windowrect(3:4)/2,...
                        obj.windowrect(3)/10,obj.windowrect(3)/50,...
                        [0 255 0]);                
                    Screen('Flip',obj.window,0,0,1);   
                case 1                  
                    [~,~,si] = unique(obj.settings.numeric_sequence);
                    color = obj.settings.finger_colors(si(obj.currentsequpos),:);
                    markkey = obj.settings.numeric_sequence(obj.currentsequpos);                    
                    
                    obj.drawColorCircles([obj.windowrect(3)/2 obj.windowrect(4)/4], 0.7, obj.settings.circle_width, obj.settings.circle_mode);                    
                    obj.keyboard.draw();
                    obj.keyboard.markkey_color = color;
                    obj.keyboard.markKey(markkey,[],0.75);
                    Screen('Flip',obj.window,0,0,1);  
                case 2
                    obj.drawColorCircles(obj.windowrect(3:4)/2, 0.7, obj.settings.circle_width, obj.settings.circle_mode);
                    Screen('Flip',obj.window,0,0,1);    
                case 3                  
                    [~,~,si] = unique(obj.settings.numeric_sequence);
                    color = obj.settings.finger_colors(si(obj.currentsequpos),:);
                    markkey = obj.settings.numeric_sequence(obj.currentsequpos);                    
                    
                    obj.keyboard.draw();
                    obj.keyboard.markkey_color = color;
                    obj.keyboard.markKey(markkey,[],0.75);
                    Screen('Flip',obj.window,0,0,1);                      
            end
        end    
        
        function showInstructions(obj)
            txt = {};            
            if (obj.mode == 1)
                txt{end+1} = 'Sie sollen lernen, eine Notenfolge in der korrekten Reihenfolge';
                txt{end+1} = 'zu spielen. Die Tasten sind auf der Tastatur farbig markiert. Während der Übung';
                txt{end+1} = 'erscheinen farbige Kreise auf dem Bildschirm, welche Ihnen anzeigen, welche Tasten als ';
                txt{end+1} = 'nächstes gedrückt werden sollen.';
                txt{end+1} = 'Im Lernmodus wird Ihnen zusätzlich die Tastatur mit der nächsten Taste gezeigt.';
                txt{end+1} = 'Bitte drücken Sie die Tasten in der dargestellten Reihenfolge zunächst langsam aber korrekt.';
                txt{end+1} = 'Bei Fehlern beginnt die Folge von vorn.';
                txt{end+1} = '';
                txt{end+1} = 'Bitte drücken Sie eine beliebige Taste zum Starten';
            elseif (obj.mode == 2)
                txt{end+1} = 'Sie sollen nun üben, die gerade gelernte Tastenfolge so schnell wie möglich zu spielen.';
                txt{end+1} = 'Auf dem Bildschirm erscheint wieder eine Folge farbiger Kreise, welche Ihnen anzeigt,';
                txt{end+1} = 'welche Tasten als nächstes zu drücken sind, die Tastatur wird nicht mehr angezeigt.'; 
                txt{end+1} = 'Die Folge ist immer identisch.';
                txt{end+1} = 'Bitte drücken Sie die Tasten in der dargestellten Reihenfolge nun so schnell wie Ihnen';
                txt{end+1} = 'ohne Fehler dabei zu machen möglich ist.'; 
                txt{end+1} = 'Bei Fehlern beginnen Sie bitte mit der Tastenfolge von vorn.';
                txt{end+1} = '';
                txt{end+1} = 'Bitte drücken Sie eine beliebige Taste zum Starten';                
            end
            for i = 1:length(txt)
                Screen('DrawText',obj.window,txt{i},10,i*50,[255 255 255]);                
            end
            Screen('Flip',obj.window,0,0,1);
            KbWait([],2);
        end
        
        function notify(obj,key)
            % bei Fehler zurück auf Start
            if (key ~= obj.settings.numeric_sequence(obj.currentsequpos))
                obj.currentsequpos = 1;
            else
                obj.currentsequpos = obj.currentsequpos + 1;
            end            
            
            if (obj.currentsequpos > length(obj.settings.numeric_sequence))
                obj.currentsequpos = 1;
                % im Lernmodus Counter erhöhen für jede kompl. Sequenz und
                % cancel-Flag setzen wenn fertig
                if (obj.mode == 1)
                    obj.learning_completed = obj.learning_completed+1;
                    if (obj.learning_completed >= obj.settings.learning_reps)
                        obj.midisampler.cancel = 1;
                    end
                end
            end

            obj.showActive();
        end      
        
        function runLearning(obj)
            obj.finished = 0;
            obj.midisampler.setInputDevice(obj.settings.MIDIinputDeviceID);
            obj.midisampler.setOutputDevice(obj.settings.MIDIoutputDeviceID);            
            
            obj.mode = 1;
            obj.initScreen();
            obj.setupVisualKeyboard();     
            obj.setupNumericSequence();            
            obj.learning_completed = 0;
            
            obj.showInstructions();
                                  
            obj.showPause(obj.settings.training_block_interval);
            while (obj.learning_completed < obj.settings.learning_reps)
                obj.currentsequpos = 1;
                obj.showActive();
                % Sample Midi
                obj.midisampler.sampleNKeysPlayCondVar(...
                    obj.settings.learning_maxkeys,0.001,0,...
                    1,...
                    unique(obj.settings.numeric_sequence),...
                    1); 
            end
            obj.showPause(obj.settings.training_block_interval);
            obj.closeScreen();
            obj.finished = 1;            
        end
        
        function runTraining(obj)
            obj.finished = 0;            
            % MIDI Setup und Speicherung
            obj.midisampler.setInputDevice(obj.settings.MIDIinputDeviceID);
            obj.midisampler.setOutputDevice(obj.settings.MIDIoutputDeviceID);
            mkdir(obj.settings.targetfolder,obj.settings.name);
            obj.mididata.data = {};
            obj.mididata.savefolder = fullfile(obj.settings.targetfolder,obj.settings.name);
            
            % Training
            obj.mode = 2;
            obj.initScreen();   
            % Setup Keyboard und Sequenz
            obj.setupVisualKeyboard();         
            obj.setupNumericSequence();
            
            obj.showInstructions();      
            
            selnote = 1; %randi(length(unique(obj.settings.numeric_sequence)));
            
            % Loop
            td = 0;
            for i = 1:obj.settings.training_block_num
                obj.currentsequpos = 1;
                obj.showPause(obj.settings.training_block_interval-td); % Zeit zum speichern berücksichtigen
                obj.showActive();
                 % Sample Midi
                obj.midisampler.sampleNKeysPlayCondVar(...
                    obj.settings.training_block_len,0.001,0,...
                    obj.settings.condition,...
                    unique(obj.settings.numeric_sequence),...
                    selnote);
                obj.showPause(0.01); % Kurz einblenden und in Pause speichern
                tic;
                obj.save();                
                td = toc; % Zeit zum speichern messen
            end
            obj.showPause(obj.settings.training_block_interval-td);
            obj.closeScreen();
            obj.finished = 1;
        end
    end
end

