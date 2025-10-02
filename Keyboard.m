%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef Keyboard < handle
    
    properties
        rect = [];
        window = [];
        
        keys = [];
        bw = [];
        markkey_color = [255 0 0];
        
        keyrects = [];
        keycenters = [];
    end
    
    methods
        function obj = Keyboard(window, winrect, centerpos, relwidth, relheight)
            obj.window = window;
            w = relwidth * winrect(3);
            h = relheight * winrect(4);
            lu = [centerpos(1) - w/2, centerpos(2) - h/2];
            obj.rect = [lu lu(1)+w lu(2)+h];
        end
        
        function setRange(obj,startkey,startoctave,endkey,endoctave)
            skn = obj.keyToNum(startkey,startoctave);
            ekn = obj.keyToNum(endkey,endoctave);
            for i = skn:ekn
                obj.keys = [obj.keys i];
                [~,~,b] = obj.numToKey(i,0);
                obj.bw = [obj.bw b];
            end
            obj.calculateKeyPositions();            
        end
        
        function [num,isblack] = keyToNum(obj,key,octave)
            strs1 = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','H'};
            strs2 = {'C','Db','D','Eb','E','F','Gb','G','Ab','A','B','H'};  
            bl = [2 4 7 9 11];
            
            relpos = -1;
            for i = 1:length(strs1)
                if (strcmp(strs1{i},key))
                    relpos = i;                    
                    break;
                end
                if (strcmp(strs2{i},key))
                    relpos = i;
                    break;
                end                
            end
            if (relpos < 0)
                num = [];
                isblack = [];
                return;
            end
            num = relpos - 1 + octave*12;
            
            if (find(bl == relpos+1))
                isblack = 1;
            else
                isblack = 0;
            end            
        end
        
        function [key,octave,isblack] = numToKey(obj,num,mode)
            strs = {};
            if (mode == 0)
            	strs = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','H'};
            else
                strs = {'C','Db','D','Eb','E','F','Gb','G','Ab','A','B','H'};  
            end
            bl = [2 4 7 9 11];
              
            relpos = mod(num,12);
            key = strs{relpos+1};
            octave = floor(num/12);      
            if (find(bl == relpos+1))
                isblack = 1;
            else
                isblack = 0;
            end
        end
        
        function calculateKeyPositions(obj)
            width = obj.rect(3)-obj.rect(1);
            height = obj.rect(4)-obj.rect(2);
            
            obj.keycenters = zeros(length(obj.bw),2);
            obj.keyrects = zeros(length(obj.bw),4);
            
            % Weiße Tasten  
            whitekeys = find(obj.bw == 0);
            n = length(whitekeys);
            wt = width / n;
            for i = 1:n
                obj.keyrects(whitekeys(i),:) = [obj.rect(1)+(i-1)*wt+3 obj.rect(2)+3 obj.rect(1)+i*wt-3 obj.rect(4)-3]; 
                obj.keycenters(whitekeys(i),:) = [mean(obj.keyrects(whitekeys(i),[1 3])) mean(obj.keyrects(whitekeys(i),[2 4]))];
            end
            
            % Schwarze Tasten
            blackkeys = find(obj.bw == 1);
            wtbl = width/(n*2);
            tempbw = obj.bw(1);
            for i = 2:length(obj.bw)
                if ((obj.bw(i-1) == 0) && (obj.bw(i) == 0))
                    tempbw = [tempbw 0];
                end
                tempbw = [tempbw obj.bw(i)];
            end
                
            c = 0;
            if (tempbw(1))
                c = 1;
            end
            pos = 1;
            for i = 1:length(tempbw)             
                if (tempbw(i))
                    obj.keyrects(blackkeys(pos),:) = [obj.rect(1)+(i-c)*wtbl-wtbl/2 obj.rect(2)+3 obj.rect(1)+(i-c)*wtbl+wtbl/2 obj.rect(4)-height/2];
                    obj.keycenters(blackkeys(pos),:) = [mean(obj.keyrects(blackkeys(pos),[1 3])) mean(obj.keyrects(blackkeys(pos),[2 4]))];                   
                    pos = pos+1;
                end
            end              
        end
        
        function draw(obj)
            Screen('FillRect',obj.window,[255 255 255],obj.rect);
            width = obj.rect(3)-obj.rect(1);
            height = obj.rect(4)-obj.rect(2);
                              
            % Weiße Tasten zeichnen    
            whitekeys = find(obj.bw == 0);
            for i = 1:length(whitekeys)
                Screen('FrameRect',obj.window,[0 0 0],obj.keyrects(whitekeys(i),:),4);
            end
            
            % Schwarze Tasten
            blackkeys = find(obj.bw == 1);
            for i = 1:length(blackkeys)        
                Screen('FillRect',obj.window,[0 0 0],obj.keyrects(blackkeys(i),:));
            end               
        end
        
        function markKey(obj,key,octave,f)
            num = [];
            if (~isnumeric(key))
                num = obj.keyToNum(key,octave);
            else
                num = key;
            end
            if ((obj.keys(1) > num) || (obj.keys(end) < num))
                return;
            end
            idx = find(obj.keys == num);
            width = f*(obj.rect(3)-obj.rect(1))/length(obj.keys);
            lu = obj.keycenters(idx,:)-[width/2 width/2]+[0 (obj.keyrects(idx,4)-obj.keyrects(idx,2))/4];
            r = [lu lu(1)+width lu(2)+width];
            Screen('FillOval',obj.window,obj.markkey_color,r);            
        end
    end
end

