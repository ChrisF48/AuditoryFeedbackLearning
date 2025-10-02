%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef MIDISampler < handle
   
    properties
        devices = [];
        inputDeviceID = -1;
        outputDeviceID = -1;
        
        sampledData = [];
        notePlayed = [];
        
        listener = [];
        cancel = 0;
    end
    
    methods
        function obj = MIDISampler()
            obj.devices = mididevinfo();
        end
        
        function setInputDevice(obj,num)
            obj.inputDeviceID = obj.devices.input(num).ID; 
        end
        
        function setOutputDevice(obj,num)
            obj.outputDeviceID = obj.devices.output(num).ID; %mididevice(obj.devices.output(num).ID);
        end    
        
        function replay(obj,mididata,idx,dynamic)
            dev = mididevice(obj.outputDeviceID);
            d = mididata.data{idx,2};
            if (~dynamic)
                for i = 1:size(d,1)
                    if ((d(i).Type == 1) || (d(i).Type == 2))
                        if (d(i).Velocity > 0)
                            d(i).Velocity = 100;
                        end
                    end
                end
            end
            midisend(dev,d);
            pause(mididata.data{idx,2}(end).Timestamp);
        end
        
        % cond = 1: play note directly
        % cond = 2: play same note
        % cond = 3: play random note            
        
        function sampleNKeysPlayCondVar(obj,n,interv,dynamic,cond,notepool,selnote)
            dev = mididevice('Input',obj.inputDeviceID,'Output',obj.outputDeviceID);
            midisend(dev,midimsg('SystemReset',0));  
        
            obj.cancel = 0;
            obj.sampledData = [];
            obj.notePlayed = [];
            
            done = 0;
            msg = {};
            numplayed = 0;
            td = 0;        
            notemap = []; 

            while ((numplayed < n) && ~obj.cancel)
                pause(max(interv-td,0));
                tic;
                msg = midireceive(dev);
                for i = 1:length(msg)
                    if (msg(i).Type == 1)
                        % Note on
                        if (msg(i).Velocity > 0)
                            if (cond == 1)
                                notemap = [notemap; [msg(i).Note msg(i).Note]];
                            elseif (cond == 2)
                                notemap = [notemap; [msg(i).Note notepool(selnote)]];
                            else
                                notemap = [notemap; [msg(i).Note notepool(randi(length(notepool)))]];
                            end
                            m = msg(i);  
                            if (isempty(find(notepool == msg(i).Note)))
                                continue;
                            end
                            
                            obj.sampledData = [obj.sampledData; m];                             
                            m.Note = notemap(end,2);
                            obj.notePlayed = [obj.notePlayed m.Note];
                            m.Timestamp = 0;     
                            if (~dynamic)
                                m.Velocity = 100;
                            end                               
                            midisend(dev,m);                                                           
                            numplayed = numplayed + 1;
                            
                            if (~isempty(obj.listener))
                                obj.listener.notify(msg(i).Note);
                            end                               
                        else
                            m = midimsg('NoteOff',msg(i).Channel,msg(i).Note,0,msg(i).Timestamp);                                                        
                            obj.sampledData = [obj.sampledData; m];                             
                            m.Timestamp = 0; 
                            if (~isempty(notemap))
                                idx = find(notemap(:,1) == m.Note);
                                if (~isempty(idx))
                                    m.Note = notemap(idx(1),2);
                                    notemap(idx,:) = [];
                                end
                            end
                            midisend(dev,m);      
                        end
                    end
                end                                            
                td = toc;   
            end             
            msg = obj.sampledData(end);   
            pause(0.3);            
            for i = 1:size(notemap,1)        
                m = midimsg('NoteOff',msg.Channel,notemap(i,1),0,msg.Timestamp+0.3);
                obj.sampledData = [obj.sampledData; m];   
                m.Note = notemap(i,2);
                m.Timestamp = 0;
                midisend(dev,m);            
            end
        end     
    end
end

