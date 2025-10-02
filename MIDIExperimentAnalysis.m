%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef MIDIExperimentAnalysis < handle
    
    properties
        datafolder = '';
        results = {};
        resultparamnum = [];
        condnum = 0;
        
        condranges = [];
        condlabels = [];
    end
    
    methods
        function obj = MIDIExperimentAnalysis(datafolder)
            obj.datafolder = datafolder;
        end
        
        function saveToExcel(obj,fn,basestats)
            disp('Schreibe Excel-Datei');

            sheetnames = {'n','n_Anteil','Gesamtdauer','Mittlere_Dauer','Mittlere_Kraft','Dauer_ErsterBlock','Dauer_LetzterBlock'};
            numformat = {'0','0.00','0.00','0.00','0.00','0.00','0.00'};
            resformat = '0.000';
            
            e = ExcelInterface();
            for i = 1:length(obj.results)
                tres = obj.results{i};                                
                pos = size(tres,1);
                % Mittelwertstatistik erstellen
                if (basestats)
                    % Deskriptiv
                    for k = 1:obj.condnum
                        tres{(k-1)*5+pos+2,1} = sprintf('n_%i',obj.condlabels(k));
                        tres{(k-1)*5+pos+3,1} = sprintf('MW_%i',obj.condlabels(k));
                        tres{(k-1)*5+pos+4,1} = sprintf('STD_%i',obj.condlabels(k));
                        tres{(k-1)*5+pos+5,1} = sprintf('STE_%i',obj.condlabels(k));
                        
                        for j = 3:size(tres,2)
                            rs = '0';
                            if (~isnan(obj.condranges(k,1)))                                
                                rs = sprintf('%s:%s',...
                                    e.coordToExcel([obj.condranges(k,1) j]),...
                                    e.coordToExcel([obj.condranges(k,2) j]));
                            end
                            if (strcmp(rs,'0'))
                                tres{(k-1)*5+pos+2,j} = 0; 
                            else
                                tres{(k-1)*5+pos+2,j} = sprintf('=ANZAHL(%s)',rs); 
                            end
                            tres{(k-1)*5+pos+3,j} = sprintf('=MITTELWERT(%s)',rs);
                            tres{(k-1)*5+pos+4,j} = sprintf('=STABW(%s)',rs);                    
                            tres{(k-1)*5+pos+5,j} = sprintf('=STABW(%s)/WURZEL(ANZAHL(%s))',rs,rs);   
                        end                        
                    end
                    % Inferenz
                    spos = size(tres,1);
                    cpos = 1;
                    for k = 1:obj.condnum
                        for l = k+1:obj.condnum
                            tres{spos+cpos+1,1} = sprintf('t-Test Bed. %i vs. %i',obj.condlabels(k),obj.condlabels(l));
                            cpos = cpos+1;
                        end
                    end
                    for j = 3:size(tres,2) 
                        cpos = 1;
                        for k = 1:obj.condnum
                            for l = k+1:obj.condnum
                                rs1 = '0';
                                if (~isnan(obj.condranges(k,1)))                                
                                    rs1 = sprintf('%s:%s',...
                                        e.coordToExcel([obj.condranges(k,1) j]),...
                                        e.coordToExcel([obj.condranges(k,2) j]));
                                end 
                                rs2 = '0';
                                if (~isnan(obj.condranges(l,1)))                                
                                    rs2 = sprintf('%s:%s',...
                                        e.coordToExcel([obj.condranges(l,1) j]),...
                                        e.coordToExcel([obj.condranges(l,2) j]));
                                end  
                                tres{spos+cpos+1,j} = sprintf('=TTEST(%s;%s;2;3)',rs1,rs2);   
                                cpos = cpos+1;
                            end
                        end
                    end
                end                
               
                e.addSheet(sheetnames{i},tres,[]);
                
                % Formatierung
                e.setFormat(i,[1 1],'font{style=b}');
                for j = 1:size(tres,2)
                    e.setFormat(i,[3 j],'font{style=i}');
                end
                for j = 2:size(tres,2)
                    for k = 4:pos
                        e.setFormat(i,[k j],sprintf('number{%s}',numformat{i}));
                    end
                    if (basestats)
                        for k = pos+2:size(tres,1)
                            e.setFormat(i,[k j],sprintf('number{%s}',resformat));
                        end           
                    end
                end  
                if (basestats)
                    for k = pos+2:size(tres,1)
                        e.setFormat(i,[k 1],'font{style=i}');
                    end           
                end                
            end
            
            % alles in Exceldatei schreiben
            e.flushToExcel();
            e.save(fullfile(obj.datafolder,fn));
            e.delete();
        end
        
        function sortConditions(obj)
            for i = 1:length(obj.results)
                conds = cell2mat(obj.results{i}(4:end,2));
                [~,si] = sort(conds);
                obj.condnum = length(unique(conds));
                obj.condlabels = unique(sort(conds));
                obj.results{i}(4:end,:) = obj.results{i}(3+si,:);
            end
            obj.condranges = [];
            for i = 1:obj.condnum
                idx = find(cell2mat(obj.results{1}(4:end,2)) == i);
                if (~isempty(idx))
                    obj.condranges = [obj.condranges; [idx(1)+3 idx(end)+3]];
                else
                    obj.condranges = [obj.condranges; [NaN NaN]];
                end
            end
        end
        
        function parse(obj,expalldata)
            obj.results = {};
            obj.resultparamnum = 7;
            if (expalldata)
                obj.resultparamnum = 8;
            end
            for i = 1:obj.resultparamnum
                obj.results{i} = {};
                obj.results{i}{3,1} = 'Name';
                obj.results{i}{3,2} = 'Bedingung';                
            end
            obj.results{1}{1,1} = 'Anzahl korrekter Sequenzen';
            obj.results{2}{1,1} = 'Prozentanteil korrekter Sequenzen';
            obj.results{3}{1,1} = 'Gesamtdauer Block';
            obj.results{4}{1,1} = 'Mittlere Dauer korrekte Sequenz';            
            obj.results{5}{1,1} = 'Mittlere Tastendruckstärke während korrekter Sequenz';            
            obj.results{6}{1,1} = 'Dauer erster korrekter Block';
            obj.results{7}{1,1} = 'Dauer letzter korrekter Block';
            if (expalldata)
                obj.results{8}{1,1} = 'Alle Daten';
            end
            
            disp('Auswertung...');
            d = dir(obj.datafolder);
            for i = 3:length(d)
                if ((d(i).isdir) && (d(i).name(1) ~= 'x'))
                    disp(d(i).name);
                    f = fullfile(obj.datafolder,d(i).name,sprintf('%s.mat',d(i).name));
                    data = load(f);
                    f = fullfile(obj.datafolder,d(i).name,sprintf('settings.mat'));
                    settings = load(f);
                    obj.analyze(d(i).name,data.data,settings.settings_obj,expalldata);
                end
            end
            for i = 1:obj.resultparamnum
                for j = 1:size(obj.results{i},2)-2
                    obj.results{i}{3,j+2} = sprintf('Block %i',j);
                end
            end            
        end

        function [widetable] = generateLongTable(obj)
            disp('Tabelle erzeugen');
            widetablec = {};
            for i = 4:size(obj.results{8},1)
                for j = 3:size(obj.results{8},2)
                    for k = 1:length(obj.results{8}{i,j})
                        widetablec{end+1,1} = obj.results{8}{i,1};
                        widetablec{end,2} = obj.results{8}{i,2};
                        widetablec{end,3} = i-3;                       
                        widetablec{end,4} = j-2;                           
                        widetablec{end,5} = k;
                        widetablec{end,6} = obj.results{8}{i,j}(k);
                    end
                end
            end
            widetable = cell2table(widetablec);
            widetable.Properties.VariableNames = {'snName','condition','fileId','block','correctsequn','duration'};
        end
        
        function analyze(obj,name,data,settings,expalldata)            
            ypos = size(obj.results{1},1)+1;
            for i = 1:obj.resultparamnum
                obj.results{i}{ypos,1} = name;
                obj.results{i}{ypos,2} = settings.condition;                
            end
            sequ = settings.numeric_sequence;
            for i = 1:size(data,1)
                n = NaN;
                perc = NaN;
                meandur = NaN;
                meanvelo = NaN;
                totaldur = data{i,3}(end,3)-data{i,3}(1,3);
                idx = strfind(data{i,3}(:,1)',sequ);
                if (isempty(idx))
                    continue;
                end
                n = length(idx);     
                perc = n*length(sequ)/size(data{i,3},1);
                velo = [];
                for j = 1:length(idx)
                    velo = [velo; data{i,3}(idx(j):idx(j)+length(sequ)-1,2)];
                end
                meanvelo = mean(velo); 
                
                idx = [idx'; idx'+length(sequ)-1];
                times = data{i,3}(idx,3);
                times = [times(1:n) times(n+1:end)];
                meandur = mean(times(:,2)-times(:,1));    
                
                obj.results{1}{ypos,2+i} = n;
                obj.results{2}{ypos,2+i} = perc;
                obj.results{3}{ypos,2+i} = totaldur;
                obj.results{4}{ypos,2+i} = meandur; 
                obj.results{5}{ypos,2+i} = meanvelo;
                obj.results{6}{ypos,2+i} = times(1,2)-times(1,1);
                obj.results{7}{ypos,2+i} = times(end,2)-times(end,1);   
                if (expalldata)
                    obj.results{8}{ypos,2+i} = times(:,2)-times(:,1);
                end
            end
        end
    end
end

