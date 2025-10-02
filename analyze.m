datafolder = fullfile(getDropBoxFolder(),'Arbeit\Projekte\MIDI Sequence learning\data\raw');

%%
midiexpan = MIDIExperimentAnalysis(datafolder);
midiexpan.parse(false);
midiexpan.sortConditions();
midiexpan.saveToExcel('results.xlsx',1);

%%
midiexpan_alld = MIDIExperimentAnalysis(datafolder);
midiexpan_alld.parse(true);
alldata_t = midiexpan_alld.generateWideTable();
save(fullfile(datafolder,'widetable.mat'),"alldata_t");