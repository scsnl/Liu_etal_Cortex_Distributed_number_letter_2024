addpath(genpath('<path to spm 12 folder>'))
% addpath(genpath('/Users/zhangyuan/Documents/MATLAB/spm12'));
project_dir = '<path to your research project folder>';
subjectlist = [project_dir, 'path to the subject list csv file'];
res_dir = '<path to where you want to save the results>';
mkdir(res_dir)

subjects = csvread(subjectlist,1);
pid = subjects(:,1);
visit = subjects(:,2);
session = subjects(:,3);
numsub = length(pid);

matlabbatch{1}.spm.stats.factorial_design.dir = {res_dir};

for i=1:numsub
    letter = sprintf('%s/results/taskfmri/participants/%s/visit%d/session%d/glm/stats_spm12/letter_swgcar/con_0001.nii,1',project_dir,num2str(pid(i),'%04.f'),visit(i),session(i));
    number = sprintf('%s/results/taskfmri/participants/%s/visit%d/session%d/glm/stats_spm12/number_swgcar/con_0001.nii,1',project_dir,num2str(pid(i),'%04.f'),visit(i),session(i));    
    matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i).scans{1,1} = letter;
    matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i).scans{2,1} = number;
    matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i).conds = [1 2];
end

matlabbatch{1}.spm.stats.factorial_design.des.anovaw.dept = 1;
matlabbatch{1}.spm.stats.factorial_design.des.anovaw.variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.anovaw.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.anovaw.ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

matlabbatch{2}.spm.stats.fmri_est.spmmat{1} = fullfile(res_dir, 'SPM.mat');
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

BatchFile = fullfile(res_dir, 'batch_anova.mat');
save(BatchFile,'matlabbatch');

spm_jobman('initcfg');
delete(get(0, 'Children'));
spm_jobman('run', BatchFile);
