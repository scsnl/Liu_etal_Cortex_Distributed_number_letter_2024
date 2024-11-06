%-Whole brain similarity analysis
%-Tianwen Chen, 2012-03-29
%-L.Chen updated the script to handle PID and output file dir to be compatible with
%groupstats_rsa_yz.m
%__________________________________________________________________________
%-2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory

function rsa_wholebrain (ConfigFile)

 addpath(genpath('<path to your spm12 folder>'));
 
disp('==================================================================');
disp('rsa_wholebrain.m is running');
fprintf('Current directory is: %s\n', pwd);
fprintf('Config file is: %s\n', ConfigFile);
disp('------------------------------------------------------------------');
disp('Send error messages to tianwenc@stanford.edu');
disp('==================================================================');
fprintf('\n');

ConfigFile = strtrim(ConfigFile);
CurrentDir = pwd;
if ~exist(ConfigFile,'file')
  fprintf('Cannot find the configuration file %s ..\n',ConfigFile);
  error('Cannot find the configuration file');
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
  eval(ConfigFile);
  clear ConfigFile;

ServerPath   = strtrim(paralist.ServerPath);
SubjectList  = strtrim(paralist.SubjectList);
MapType      = strtrim(paralist.MapType);
MapIndex     = paralist.MapIndex;
MaskFile     = strtrim(paralist.MaskFile);
% Below modified for SMP Localizer by Ruizhe liu
StatsFolder  = paralist.StatsFolder;
% -- End --
OutputDir    = strtrim(paralist.OutputDir);
SearchShape  = strtrim(paralist.SearchShape);
SearchRadius = paralist.SearchRadius;
SPM_Version  = paralist.spmversion;

addpath(genpath(['path to your spm folder',SPM_Version]));

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

Subjects = csvread(SubjectList,1);
NumSubj = size(Subjects,1); %length(Subjects); % Yuan edit

NumMap = length(MapIndex);

if NumMap ~= 2
  error('Only 2 MapIndex are allowed');
end

for iSubj = 1:NumSubj
  PID = char(pad(num2str(Subjects(iSubj,1)),4,'left','0'));
  VISIT = num2str(Subjects(iSubj,2));
  SESSION = num2str(Subjects(iSubj,3));
  
  % Below modified for Ruizhe's SMO localizer analysis
  % This analysis compares Conditions across runs, which are saved in
  % different fodlers
  DataDir = {fullfile(ServerPath,PID,['visit',VISIT], ['session',SESSION], ...
    'glm', 'stats_spm12', StatsFolder{1}); fullfile(ServerPath,PID,['visit',VISIT], ['session',SESSION], ...
    'glm', 'stats_spm12', StatsFolder{2})};
  
  spm1 = load(fullfile(DataDir{1}, 'SPM.mat'));
  spm2 = load(fullfile(DataDir{2}, 'SPM.mat'));
  
  VY = cell(NumMap, 1);
  
  MapName = cell(NumMap, 1);
  
  % Below DataDir is changed to DataDir(1,:) and DataDir(2,:) to
  % accommondate the comparison of conditions in different folders
  % by Ruizhe Liu, 06/13/2021
  switch lower(MapType)
    case 'tmap' 
      VY{1} = fullfile(DataDir{1}, spm1.SPM.xCon(MapIndex(1)).Vspm.fname);
      MapName{1} = spm1.SPM.xCon(MapIndex(1)).name;
      VY{2} = fullfile(DataDir{2}, spm2.SPM.xCon(MapIndex(2)).Vspm.fname);
      MapName{2} = spm2.SPM.xCon(MapIndex(2)).name;
  
    case 'conmap'
      VY{1} = fullfile(DataDir{1}, spm1.SPM.xCon(MapIndex(1)).Vcon.fname);
      MapName{1} = spm1.SPM.xCon(MapIndex(1)).name;
      VY{2} = fullfile(DataDir{2}, spm2.SPM.xCon(MapIndex(2)).Vcon.fname);
      MapName{2} = spm2.SPM.xCon(MapIndex(2)).name;
      
  end
  % -- end --
  
  if isempty(MaskFile)
    VM = fullfile(DataDir{1}, spm1.SPM.VM.fname);
  else
    VM = MaskFile;
  end
  
  OutputFolder = fullfile(OutputDir, PID,['visit',VISIT], ['session',SESSION],'rsa',['stats_',SPM_Version],[MapName{1}, '_VS_', MapName{2}]);
  if ~exist(OutputFolder, 'dir')
    mkdir(OutputFolder);
  end
  
  OutputFile = fullfile(OutputFolder, 'rsa');
  
  SearchOpt.def = SearchShape;
  SearchOpt.spec = SearchRadius;
  
  scsnl_searchlight(VY, VM, SearchOpt, 'pearson_correlation', OutputFile);
end

disp('-----------------------------------------------------------------');
fprintf('Changing back to the directory: %s \n', CurrentDir);
cd(CurrentDir);
disp('Wholebrain RSA is done.');
clear all;
close all;

end
