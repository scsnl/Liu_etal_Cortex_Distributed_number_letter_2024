% Where do you want to run the script?
local_run = 1;

if local_run == 1
    main_path = ''; % server path
elseif local_run == 0
    main_path = ''; % local path
end

% Define directories
% ROI dir
rsa_roi_dir = fullfile(main_path,'<path to your ROI folder>');


rsa_roi_list =dir(rsa_roi_dir); 
% check rsa_roi_list and determine the value for dir_filler
dir_filler = 2;

% project dir
project_dir = fullfile(main_path,'<path to your project folder where you save the data and where you want to save the results>');

% subject list
subjectlist = fullfile(main_path,'<path to the subject list file in .csv format>');
% Subjects = csvread(subjectlist,1);
subjtxtfile = fopen(subjectlist);
Subjects=textscan(subjtxtfile,'%s %s %s','Delimiter',',','HeaderLines',1);
fclose(subjtxtfile);

% Uncomment below for task conditions
% conditions = ["letter_swgcar" "number_swgcar" "equation_swgcar" "word_swgcar"];

% Uncomment below for rsa contrast conditions
% conditions = ["letter-ctr_VS_numeral-ctr","letter-ctr_VS_word-ctr","numeral-ctr_VS_equation-ctr","word-ctr_VS_equation-ctr","numeral-ctr_VS_word-ctr"];
conditions = ["D-SD_VS_L-SL"];
for iCond = 1:length(conditions)
    roi_readouts = [];
    for iSubj = 1:length(Subjects{1})
        PID = Subjects{1}{iSubj};
        VISIT = Subjects{2}{iSubj};
        SESSION = Subjects{3}{iSubj};
        
        
        for iRoi = 1:(length(rsa_roi_list)-dir_filler)
            roi_name = rsa_roi_list(iRoi+dir_filler).name;
            RoiDir = fullfile(rsa_roi_dir,roi_name);
            % uncomment below for beta values readout
            % StatsDir = fullfile(project_dir,'results/taskfmri/participants/', PID, ['visit',VISIT], ['session',SESSION],'glm', 'stats_spm12', char(conditions(iCond)),'con_0001.nii');
            
            % uncomment below for rsa estimates
            StatsDir = fullfile(project_dir,'results/Ansari_RSA/participants/', PID, VISIT, SESSION,'rsa_D-SD_L-SL', 'stats_spm12', char(conditions(iCond)),'rsa_corr.nii');

            ROI_data = Extract_ROI_Data(RoiDir,StatsDir);
            roi_readouts(iSubj,iRoi) = ROI_data;           
        end
    end
    csv_filename = char(conditions(iCond)+'xxx.csv');
    csv_savedir = fullfile(project_dir,'<your ideal saving dir>',csv_filename);
    csvwrite(csv_savedir,roi_readouts)

end
