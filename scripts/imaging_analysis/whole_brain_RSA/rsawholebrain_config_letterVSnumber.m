%-Configuration file for rsa_wholebrain.m
%-Tianwen Chen, 2012-03-29
%__________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%--------------------------------------------------------------------------
%-Please specify parallel or nonparallel
%-e.g. for individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '0';

% Please specify the path to the folder holding subjects
paralist.ServerPath = '';

% Please specify the path to your main project directory
paralist.projectdir = '';

% Plese specify the list of subjects or a cell array
paralist.SubjectList = '';
% paralist.SubjectList = '/Users/ruizheliu/Desktop/oat_mount/projects/rul23/2020_Math_Localizer_Study/data/subjectlist/RSA/rsa_subjectlist_localizers_anova.csv';

% Please specify the stats folder name from SPM analysis
% Ruizhe's modification: uncomment line 25 for two folders
% that contain different conditions
paralist.StatsFolder = {'number_swgcar','letter_swgcar'};
% paralist.StatsFolder = 'LetterNumConcat_swgcar'; % for the comp_num task

% Please specify the task name for each stats folder (only 2 allowed) 
paralist.TaskName = {'number-ctr','letter-ctr'}; 

% Please specify whether to use t map or beta map ('tmap' or 'conmap')
paralist.MapType = 'conmap';

% Please specify the index of tmap or contrast map (only 2 allowed)
% If the second t map is spmT_0003.img, the number is 3 (from 003) in the 
% second slot
% con_0001: letter > rest; con_0003: number > rest
% con_0007: letter > checkerboard; 0009: number > checkerboard
paralist.MapIndex = [1]; % 0001 is letter-ctr or number-ctr 

% Please specify the mask file, if it is empty, it uses the default one from SPM.mat
% paralist.MaskFile = '/oak/stanford/groups/menon/projects/rul23/2020_Math_Localizer_Study/scripts/taskfmri/RSA/NFA_VWFA_rois/VWFA_Grotheer_2016.nii';
paralist.MaskFile = '';

% Please specify the path to the folder holding analysis results
paralist.OutputDir = '';

% Please specify the version of spm to run
paralist.spmversion = 'spm12';

% Please specify whether or not you want it done in parallel
% line 50 redundant. conflict w/ line 9. commented by Ruizhe
% paralist.parallel = 0;

%--------------------------------------------------------------------------
paralist.SearchShape = 'sphere';
paralist.SearchRadius = 6; % in mm
%--------------------------------------------------------------------------
