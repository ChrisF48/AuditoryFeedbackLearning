%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef MIDIExperimentSettings < handle
    
    properties
        targetfolder = 'data';
        name = 'P01';
        
        MIDIinputDeviceID = 1;
        MIDIoutputDeviceID = 3;   
        
        keyboard_range = {'A#',4,'F#',6};
        
        fullscreen = 1;
        screensize = [20 50 860 530];  
        fullscreensize = [0 0 1280 1024];

        target_sequence = {'Db',6,'Ab',5,'Gb',5,'B',5,'Ab',5,'Eb',5,'B',5,'Db',6,'Ab',5,'Eb',5,'Gb',5};
        numeric_sequence = [];
        
        finger_colors = [[255 0 0]; [0 255 0]; [0 0 255]; [255 255 0]; [255 0 255]];
      
        learning_reps = 3;
        learning_maxkeys = 100;
        training_block_len = 66;
        training_block_num = 14;
        training_block_interval = 10;
        condition = 1;
        
        learning_visualization_mode = 3;         
        training_visualization_mode = 3; 
        % 0... Kreuz (grün/rot), 1 ... Piano + Kreise, 2 ...
        % verschiedene Kreise, 3... Piano ohne Kreise
        circle_width = 0.05;
        circle_mode = 0;
        
        version = '0.91';
    end
    
    methods
        function obj = MIDIExperimentSettings()
        end
        
        function save(obj)
            mkdir(fullfile(obj.targetfolder,obj.name));            
            fn = fullfile(obj.targetfolder,obj.name,'settings.mat');
            obj.saveTo(fn);
        end
        
        function saveTo(obj,fn)
            settings_obj = [];
            props = properties(obj);
            for i = 1:length(props)
                settings_obj.(props{i}) = obj.(props{i});
            end
            save(fn,'settings_obj');
        end
        
        function load(obj)
            fn = fullfile(obj.targetfolder,obj.name,'settings.mat');
            obj.loadFrom(fn);
        end
        
        function loadFrom(obj,fn)
            so = load(fn,'settings_obj'); 
            settings_obj = so.settings_obj;
            props = fieldnames(settings_obj);
            for i = 1:length(props)
                obj.(props{i}) = settings_obj.(props{i});
            end                       
        end         
    end
end

