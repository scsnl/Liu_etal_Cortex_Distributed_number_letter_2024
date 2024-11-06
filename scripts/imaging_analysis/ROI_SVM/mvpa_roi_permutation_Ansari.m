% Where do you want to run the script?
local_run = 1;

if local_run == 1
    main_path = ''; % server path
elseif local_run == 0
    main_path = ''; % local path
end

% Define directories
% project dir
project_dir = fullfile(main_path,'<path to your project folder where you save the data and where you want to save the results>');

% ROI dir
rsa_roi_dir = fullfile(main_path,'<path to your ROI folder>');
savedir = fullfile(project_dir,'<path to where you want to save the results>');

rsa_roi_list =dir(rsa_roi_dir);
% roi_folder_name = 'scsnl_rsa';
dir_roi_filler = 2;% <- check length of 'rsa_roi_list' and change this number accordingly


% subject list
subjectlist_dir = fullfile(main_path,'<path to the subject list file in .csv format>');
% Subjects = csvread(subjectlist,1);
opt = {'Delimiter',','};
fid = fopen(subjectlist_dir,'rt');
hdr = fgetl(fid);
num = numel(regexp(hdr,',','split'));
fmt = repmat('%s',1,num);
subjectlist = textscan(fid,fmt,opt{:});
fclose(fid);
Subjects = subjectlist;

% Uncomment below for task conditions
% 0021 - d-sd; 0027 - l-sl
conditions = ["con_0021.nii" "con_0027.nii"]; %  "equation_swgcar" "word_swgcar"

% Uncomment below for rsa contrast conditions
% conditions = ["letter-ctr_VS_numeral-ctr","letter-ctr_VS_word-ctr","numeral-ctr_VS_equation-ctr","word-ctr_VS_equation-ctr","numeral-ctr_VS_word-ctr"];

for iRoi = 1:(length(rsa_roi_list)-dir_roi_filler)
    roi_name = rsa_roi_list(iRoi+dir_roi_filler).name
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
%         [coeff,pcascore,latent] = pca(roi_readouts);
%         data_frame{iCond,1} = pcascore;
        data_frame{iCond,1} = roi_readouts;
    end
     df_cat = cell2mat(data_frame);

     % df_cat = fillmissing(df_cat,'spline');
     labels = [repmat("digit",length(Subjects{1,1}),1) ;repmat("letter",length(Subjects{1,1}),1)];
%      mat_filename_df = append(roi_folder_name,'_',roi_name,'_df.mat');
%      df_save_dir = fullfile(savedir,mat_filename_df);
%      save(df_save_dir,'df_cat');
     
     %CV: LOO
         cv_num = length(Subjects{1,1});
         pred_acc = [];
         for k = 1:cv_num
             training_df = df_cat;
             training_df([k,k+length(Subjects{1,1})],:)=[];
             testing_df = df_cat([k,k+length(Subjects{1,1})],:);
             
             training_labels = labels;
             training_labels([k,k+length(Subjects{1,1})],:)=[];
             testing_labels = labels([k,k+length(Subjects{1,1})],:);
             
             svm_mdlfit = fitcsvm(training_df,training_labels);
             [pred_label,score] = predict(svm_mdlfit,testing_df);
             
             label_diff = (pred_label ==testing_labels);
             pred_acc(k) = sum(label_diff)/length(label_diff);
         end
         mean_pred_acc = mean(pred_acc);
         raw_pred_acc(iRoi) = mean_pred_acc;
         
         % permutation
         pred_acc_perm = [];
         for p =1:1000
             p
             labels_perm = labels(randperm(length(labels)));
             pred_acc_tmp_perm = [];
             fprintf('%05d\n',p)
             for k = 1:cv_num
                 training_df = df_cat;
                 training_df([k,k+length(Subjects{1,1})],:)=[];
                 testing_df = df_cat([k,k+length(Subjects{1,1})],:);
    
                 training_labels = labels_perm;
                 training_labels([k,k+length(Subjects{1,1})],:)=[];
                 testing_labels = labels_perm([k,k+length(Subjects{1,1})],:);
    
                 svm_mdlfit = fitcsvm(training_df,training_labels);
                 [pred_label,score] = predict(svm_mdlfit,testing_df);
    
                 label_diff = (pred_label ==testing_labels);
                 pred_acc_tmp_perm(k) = sum(label_diff)/length(label_diff);
             end
             mean_pred_acc_perm = mean(pred_acc_tmp_perm); 
             pred_acc_perm(p) = mean_pred_acc_perm;
         end
         I = length(find(pred_acc_perm > mean_pred_acc));
         perm_p_value = I/length(pred_acc_perm);
         permute_pred_acc_all(:,iRoi) = pred_acc_perm;
         permuted_p_values(iRoi) = perm_p_value;
end

results = vertcat(raw_pred_acc,permuted_p_values);
csv_filename_permutation = 'your_ideal_filename.csv';
csv_filename_acc_pvalue = 'your_ideal_filename.csv';
csv_savepath_permutation = fullfile(savedir,csv_filename_permutation);
csv_savepath_results = fullfile(savedir,csv_filename_acc_pvalue);

csvwrite(csv_savepath_permutation,permute_pred_acc_all);
csvwrite(csv_savepath_results,results);

