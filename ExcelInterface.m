%%----------------------------------
%% Copyright Klinik und Poliklinik für Neurologie, Universitätsklinikum Leipzig
%% Author: Christopher Fricke
%%----------------------------------

classdef ExcelInterface < handle
    
    properties
        excel = [];
        
        sheet_names = {};
        sheet_data = {};
        sheet_format = {};
    end
    
    methods
        function obj = ExcelInterface()
            obj.excel = actxserver('Excel.Application');
        end
        
        function save(obj,fn)
            obj.excel.ActiveWorkbook.SaveAs(fn);
        end
        
        function delete(obj)
            Quit(obj.excel);
            delete(obj.excel);
        end
        
        function ec = coordToExcel(obj,c)
            n0 = mod(c(2),26);
            n1 = floor(c(2)/26);
            ec = '';
            if (n1 > 0)
                ec = char(n1+64);
            end
            ec = strcat(ec,char(n0+64));
            ec = sprintf('%s%i',ec,c(1));
        end

        function ec = rangeToExcel(obj,r,c)
            if (length(r) == 1)
                ec1 = this.coordToExcel([r c(1)]);
                ec2 = this.coordToExcel([r c(end)]);
                ec = sprintf('%s:%s',ec1,ec2);
            else
            end
        end
        
        function addSheet(obj,name,data,format)
            obj.sheet_names{end+1} = name;
            obj.sheet_data{end+1} = data;
            if (isempty(format))
                obj.sheet_format{end+1} = num2cell(nan(size(data)));
            else
                obj.sheet_format{end+1} = format;
            end
        end
        
        function setValue(obj,sheetn,coord,value)
            obj.sheet_data{sheetn}{coord(1),coord(2)} = value;
        end
        
        function setFormat(obj,sheetn,coord,formatstr)
            obj.sheet_format{sheetn}{coord(1),coord(2)} = formatstr;
        end
        
        function applyFormat(obj,c,f)
            font = regexp(f,'font{(.*)}','tokens');
            type = regexp(f,'number{(.*)}','tokens');
            if (~isempty(font))
                fontdata = regexp(font{1},{'name=(?<name>\w*)','size=(?<size>\d*)','style=(?<style>\w*)'},'tokens');
                
                if (~isempty(fontdata{1}))
                    c.Font.Name = fontdata{1}{1};
                end
                if (~isempty(fontdata{2}))
                    c.Font.Size = str2num(fontdata{2}{1}{1});
                end
                if (~isempty(fontdata{3}))
                    if (strcmp(fontdata{3}{1},'b'))
                        c.Font.FontStyle = 'Bold';
                    elseif (strcmp(fontdata{3}{1},'i'))
                        c.Font.FontStyle = 'Italic';
                    end  
                end
            end
            if (~isempty(type))
                c.NumberFormat = type{1};              
            end
        end
        
        function flushToExcel(obj)
            wb = obj.excel.Workbooks.Add();
            ws = wb.Worksheets;
            names = {};
            for i = 1:ws.Count
                names{end+1} = ws.Item(i).Name;
            end
            
           % obj.excel.Visible = 1;
            sheets = wb.Sheets;
                       
            for i = 1:length(obj.sheet_data)
                s = sheets.Add();
                s.set('Name',obj.sheet_names{i});
                s.Activate();               
                for x = 1:size(obj.sheet_data{i},1)
                    for y = 1:size(obj.sheet_data{i},2)
                        if (~isempty(obj.sheet_data{i}{x,y}))
                            c = get(s,'Cells',x,y);
                         %   disp(obj.sheet_data{i}{x,y});
                            c.Value = obj.sheet_data{i}{x,y};
                            if (~isnan(obj.sheet_format{i}{x,y}))
                                obj.applyFormat(c,obj.sheet_format{i}{x,y});
                            end
                        end
                    end
                end
            end
            for i = 1:length(names)
                ws.Item(names{i}).Delete;
            end
        end
    end
end

