%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef MIDIData < handle
    
    properties
        data = {};
        savefolder = '';
    end
    
    methods
        function obj = MIDIData(savefolder)
            obj.savefolder = savefolder;
        end
        
        function addData(obj,sampler,autosave)
            pos = size(obj.data,1)+1;
            obj.data{pos,1} = sysTime();
            obj.data{pos,2} = sampler.sampledData;
            obj.data{pos,3} = obj.process(sampler.sampledData);
            obj.data{pos,4} = sampler.notePlayed;
            if (autosave)
                obj.save(sprintf('mididata_%.0f.mat',sysTime()));
            end
        end
                       
        function save(obj,filename)
            data = obj.data;
            save(fullfile(obj.savefolder,filename),'data');
        end
        
        function load(obj,filename)
            d = load(fullfile(obj.savefolder,filename));            
            obj.data = d.data;            
        end
        
        function pd = process(obj,d)
            pd = [];
            for i = 1:length(d)
                if (d(i).Type == 1)                 
                    for k = i+1:length(d)
                        if (d(k).Type == 2)
                            if (d(k).Note == d(i).Note)                           
                                pd = [pd; d(i).Note d(i).Velocity d(i).Timestamp d(k).Timestamp - d(i).Timestamp];
                                break;
                            end
                        end
                    end                        
                end
            end
        end        
    end
end

