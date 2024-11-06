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
Subjects = csvread(subjectlist,1);

% Uncomment below for task conditions
conditions = ["letter_swgcar" "number_swgcar"]; %  "equation_swgcar" "word_swgcar"

% Uncomment below for rsa contrast conditions
% conditions = ["letter-ctr_VS_numeral-ctr","letter-ctr_VS_word-ctr","numeral-ctr_VS_equation-ctr","word-ctr_VS_equation-ctr","numeral-ctr_VS_word-ctr"];

raw_pred_acc = [];
permute_pred_acc_all = [];
permuted_p_values = [];
for iRoi = 1:(length(rsa_roi_list)-2)
    roi_name = rsa_roi_list(iRoi+2).name
    RoiDir = fullfile(rsa_roi_dir,roi_name);
    
    data_frame = {};
    for iCond = 1:length(conditions)
        roi_readouts = [];
        for iSubj = 1:length(Subjects)
            PID = sprintf('%04d',Subjects(iSubj,1));
            VISIT = num2str(Subjects(iSubj,2));
            SESSION = num2str(Subjects(iSubj,3));
        
            % uncomment below for beta values readout
            StatsDir = fullfile(project_dir,'results/taskfmri/participants/', PID, ['visit',VISIT], ['session',SESSION],'glm', 'stats_spm12', char(conditions(iCond)),'con_0001.nii');

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

     %CV: LOO
     cv_num = length(Subjects);
     pred_acc = [];
     for k = 1:cv_num
         training_df = df_cat; % replace 'df_cat' with 'df_cat_miss' if have missing values
         training_df([k,k+length(Subjects)],:)=[];
         testing_df = df_cat([k,k+length(Subjects)],:); % replace 'df_cat' with 'df_cat_miss' if have missing values
         
         training_labels = labels;
         training_labels([k,k+length(Subjects)],:)=[];
         testing_labels = labels([k,k+length(Subjects)],:);
         
         svm_mdlfit = fitcsvm(training_df,training_labels);
         [pred_label,score] = predict(svm_mdlfit,testing_df);
         
         label_diff = (pred_label ==testing_labels);
         pred_acc(k) = sum(label_diff)/length(label_diff);
     end
     mean_pred_acc = mean(pred_acc);
     raw_pred_acc(iRoi) = mean_pred_acc;
     
     % permutation
     pred_acc_perm = [];
     iterations = 1000
     for p =1:iterations
         p
         labels_perm = labels(randperm(length(labels)));
         pred_acc_tmp_perm = [];
         % fprintf('%05d',p)
         for k = 1:cv_num
             training_df = df_cat;
             training_df([k,k+length(Subjects)],:)=[];
             testing_df = df_cat([k,k+length(Subjects)],:);

             training_labels = labels_perm;
             training_labels([k,k+length(Subjects)],:)=[];
             testing_labels = labels_perm([k,k+length(Subjects)],:);

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
savedir = fullfile(project_dir,'your ideal saving dir');
csv_savepath_permutation = fullfile(savedir,csv_filename_permutation);
csv_savepath_results = fullfile(savedir,csv_filename_acc_pvalue);

csvwrite(csv_savepath_permutation,permute_pred_acc_all);
csvwrite(csv_savepath_results,results);
