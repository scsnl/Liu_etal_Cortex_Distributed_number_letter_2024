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

% project dir
project_dir = fullfile(main_path,'<path to your project folder where you save the data and where you want to save the results>');

% subject list
subjectlist = fullfile(main_path,'<path to the subject list file in .csv format>');
opt = {'Delimiter',','};
fid = fopen(subjectlist,'rt');
hdr = fgetl(fid);
num = numel(regexp(hdr,',','split'));
fmt = repmat('%s',1,num);
subjectlist = textscan(fid,fmt,opt{:});
fclose(fid);
Subjects = subjectlist;

% Uncomment below for task conditions
conditions = ["con_0021.nii" "con_0027.nii"]; %  "equation_swgcar" "word_swgcar"

% Uncomment below for rsa contrast conditions
% conditions = ["letter-ctr_VS_numeral-ctr","letter-ctr_VS_word-ctr","numeral-ctr_VS_equation-ctr","word-ctr_VS_equation-ctr","numeral-ctr_VS_word-ctr"];

raw_t_value = [];
permute_t_all = [];
permuted_p_values = [];
for iRoi = 1:(length(rsa_roi_list)-2)
    roi_name = rsa_roi_list(iRoi+2).name
    RoiDir = fullfile(rsa_roi_dir,roi_name);
    
    data_frame = {};
    for iCond = 1:length(conditions)
        roi_readouts = [];
        for iSubj = 1:length(Subjects{1,1})
            PID = sprintf(Subjects{1,1}{iSubj});
            VISIT = Subjects{1,2}{iSubj};
            SESSION = Subjects{1,3}{iSubj};
        
            % uncomment below for beta values readout
            StatsDir = convertStringsToChars(fullfile(project_dir,'/results/Ansari_individualstats', PID,VISIT,SESSION,'glm', 'stats_spm12', 'LetterNumConcat_swgcar',conditions(iCond)));

            % uncomment below for rsa estimates
            % StatsDir = fullfile(project_dir,'results/taskfmri/participants/', PID, ['visit',VISIT], ['session',SESSION],'rsa', 'stats_spm12', char(conditions(iCond)),'rsa_corr.nii');

            [Ym R info] = extract_voxel_values(RoiDir,StatsDir);
            roi_readouts(iSubj,:) = R.I.Ya;  
        end

        % uncomment below for running pca before mvpa
        % [coeff,pcascore,latent] = pca(roi_readouts);
        
        % using readouts
        data_frame{iCond,1} = roi_readouts;

        % using pca
        % data_frame{iCond,1} = pcascore;
    end
     df_cat = cell2mat(data_frame);

     % Use line below for filling in missing values, using 'spline' here but can try other methods based on your needs/judgement
     % df_cat_miss = fillmissing(df_cat,'spline');

     labels = [repmat(conditions(1),length(Subjects),1) ;repmat(conditions(2),length(Subjects),1)];

     corr_group = [];
     for subj=1:length(Subjects)
         corr_subj_mtx = corrcoef(df_cat(subj,:), df_cat(subj+length(Subjects),:));
         corr_subj = corr_subj_mtx(2);
         corr_group(subj)=corr_subj;
     end
     [h,p,ci,stats] = ttest(corr_group);
     t_true = stats.tstat;
     raw_t_value(iRoi) = t_true;
     
     % permutation
     t_perm = [];
     iterations = 5000;
     for p =1:iterations
         % fprintf('%05d',p)
         labels_perm = labels(randperm(length(labels)));
         I = find(labels_perm == "con_0027.nii");
         df_letter = df_cat(I,:);
         df_number = df_cat;
         df_number(I,:)=[];

         corr_group_perm = [];
         for subj=1:length(Subjects)
             corr_subj_mtx = corrcoef(df_letter(subj,:), df_number(subj,:));
             corr_subj = corr_subj_mtx(2);
             corr_group_perm(subj)=corr_subj;
         end
         [h_perm,p_perm_tmp,ci_perm,stats_perm] = ttest(corr_group_perm); 
         t_perm(p) = stats_perm.tstat;
     end
     I = length(find(t_perm > t_true));
     perm_p_value = I/length(t_perm);
     permute_t_all(:,iRoi) = t_perm;
     permuted_p_values(iRoi) = perm_p_value;
end

results = vertcat(raw_t_value,permuted_p_values);
csv_filename_permutation = 'your_ideal_filename.csv';
csv_filename_acc_pvalue = 'your_ideal_filename.csv';
savedir = fullfile(project_dir,'your ideal saving dir');
csv_savepath_permutation = fullfile(savedir,csv_filename_permutation);
csv_savepath_results = fullfile(savedir,csv_filename_acc_pvalue);

csvwrite(csv_savepath_permutation,permute_t_all);
csvwrite(csv_savepath_results,results);
