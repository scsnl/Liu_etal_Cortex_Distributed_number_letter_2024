from sklearn.model_selection import GridSearchCV, cross_val_score, KFold
import pandas as pd
from nilearn import image, plotting, input_data
import numpy as np
from glmnet_python import glmnet, glmnetCoef, glmnetPredict, cvglmnet, cvglmnetCoef, cvglmnetPlot, cvglmnetPredict
# from sklearn.linear_model import LogisticRegression
# from sklearn.svm import LinearSVC
from sklearn import preprocessing, metrics
from sklearn.pipeline import Pipeline
from sklearn.model_selection import LeaveOneGroupOut
from sklearn import svm
import time
import warnings
warnings.filterwarnings('ignore')
warnings.filterwarnings("ignore", category=FutureWarning)

def classifLeaveOneGroupOut(data,labels,groups,alpha):
    cvfit = cvglmnet(x=data.copy(), y=labels.copy(), foldid=groups, family='binomial', \
                     alpha=alpha, ptype='class', keep=True, parallel=True)
    best_lambda = cvfit['lambda_min']
    lambdau = cvfit['lambdau']
    # print(lambdau.shape)
    idx = np.where(lambdau == best_lambda)
    # print(idx[0])
    preval = cvfit['fit_preval']
    # get predicted value in cv
    ypreval = (np.squeeze(preval[:, idx[0]]) > 0.5) * 1
    # print(ypreval.shape)
    ypreval = np.squeeze(ypreval)
    # accuracy
    accuracy = 100.0 * np.sum(labels == ypreval) / len(ypreval)
    # get coefficients
    coef = cvglmnetCoef(cvfit, s='lambda_min')
    # print(coef.shape)
    coef = np.transpose(coef[1:, :])
    # print out information
    print('best lambda is {}'.format(best_lambda))
    print('cross-validation accuracy is {}'.format(accuracy))
    print('shape of coef {}'.format(coef.shape))
    print('max and min value of coef {}, {}'.format(np.max(coef), np.min(coef)))
    print('number & percent of features with 0 coefficient')
    print(sum(np.squeeze(coef) == 0), 100 * sum(np.squeeze(coef) == 0) / coef.shape[1])

    return accuracy, coef, best_lambda

def classifLeaveOneGroupOutPerm(data,labels,groups,alpha,best_lambda):
    cvfit = cvglmnet(x=data.copy(), y=labels.copy(), foldid=groups, family='binomial', \
                     alpha=alpha, ptype='class', keep=True, parallel=True, lambdau=np.array([best_lambda, best_lambda+0.1]))
    lambdau = cvfit['lambdau']
    # print(lambdau)
    idx = np.where(lambdau == best_lambda)
    # print(idx[0])
    preval = cvfit['fit_preval']
    # get predicted value in cv
    ypreval = (np.squeeze(preval[:, idx[0]]) > 0.5) * 1
    # print(ypreval.shape)
    ypreval = np.squeeze(ypreval)
    # accuracy
    accuracy = 100.0 * np.sum(labels == ypreval) / len(ypreval)
    # get coefficients
    coef = cvglmnetCoef(cvfit, s='lambda_min')
    # print(coef.shape)
    coef = np.transpose(coef[1:, :])

    return accuracy, coef


def dataPermute(labels):
    group1_size = np.sum(labels == 1)
    group2_size = np.sum(labels == 0)
    subj_ids = np.arange(0,group1_size)
    # Switch labels with probability 0.5
    labels_group1_perm = np.ones(len(subj_ids))
    labels_group2_perm = np.zeros(len(subj_ids))
    u = np.random.rand(len(subj_ids))
    ix = u >= 0.5
    labels_group1_perm[ix] = 0
    labels_group2_perm[ix] = 1
    labels_perm = np.append(labels_group1_perm,labels_group2_perm)
    return labels_perm


if __name__ == '__main__':
    project_dir = 'your_project_dir'
    subjectlist = 'your_project_dir/filename.csv'

    mask_list = ['masks/vbm_grey_mask.nii']
    mask_name_list = ['vbm_grey_mask']

    # alpha = 0 # 1 = lasso, 0 = ridge, 0.5 = mix of lasso and ridge
    # param_grid = list(np.arange(0, 0.1, 0.01))
    # param_grid = list(np.arange(0, 0.1, 0.05))
    param_grid =[0, 0.1, 1] # ridge, elastic net, lasso

    subjects = pd.read_csv(subjectlist)
    # print(subjects)
    numsub = subjects.shape[0]
    print(numsub)

    pid = subjects['PID']  # to fill 0 to left:  str(a).rjust(4,'0')
    session = subjects['session']

    fname_letter_list = []
    fname_number_list = []

    for ii in range(numsub):
        img1 = project_dir + 'results/Ansari_individualstats/' + pid[ii] + '/' + session[ii] + '/func/glm/stats_spm12/LetterNumConcat_swgcar/con_0027.nii'
        img2 = project_dir + 'results/Ansari_individualstats/' + pid[ii] + '/' + session[ii] + '/func/glm/stats_spm12/LetterNumConcat_swgcar/con_0021.nii'

        fname_letter_list.append(img1)
        fname_number_list.append(img2)

    fname_list = fname_letter_list + fname_number_list
    labels = np.zeros(numsub*2)
    labels[0:numsub] = 1 # letter: 1, number: 0
    # print(fname_list)

    img4D = image.concat_imgs(fname_list)

    for mm in range(len(mask_list)):
        mask = mask_list[mm]
        mask_name = mask_name_list[mm]
        print('mask is {}'.format(mask))

        for alpha in param_grid:
            print('alpha is {}'.format(alpha))
            outputf = 'ansari_new/glmnet_coef_img_alpha_' + str(alpha) + '_' + mask_name + '.nii.gz'
            outputf_abs = 'ansari_new/glmnet_abs_coef_img_alpha_' + str(alpha) + '_' + mask_name + '.nii.gz'
            print(outputf)
            # masking the data: from 4D image to 2D array
            # masker = input_data.NiftiMasker(mask_img=mask, standardize=True)
            masker = input_data.NiftiMasker(mask_img=mask)
            fmri_masked = masker.fit_transform(img4D)
            print(fmri_masked.shape)

            # np.savez('stanford/subj_by_features.npz', features=fmri_masked, labels=labels)

            fmri_masked = fmri_masked.astype(np.float64)
            # print(fmri_masked.dtype)

            group1_size = np.sum(labels == 1)
            group2_size = np.sum(labels == 0)
            groups = np.concatenate((np.arange(0, group1_size), np.arange(0, group2_size)))
            accuracy, coef, best_lambda = classifLeaveOneGroupOut(fmri_masked,labels,groups,alpha)

            # unmasking
            print("save glmnet feature weights to file...")
            coef_img = masker.inverse_transform(coef)
            coef_img.to_filename(outputf)
            print(coef_img)

            coef_abs_img = masker.inverse_transform(np.abs(coef))
            coef_abs_img.to_filename(outputf_abs)

            # # plotting
            # print("plotting...")
            # plotting.plot_stat_map(coef_img, title="glmnet weights", display_mode="yx")
            # plotting.show()

            ''' Permutations'''
            print('significance test using permutation')
            no_permutations = 5000
            accuracies_null = []
            coef_null_perm = []
            for i in range(no_permutations):
                if i % 25 == 0:
                    print("Permutation=", i)
                labels_perm = dataPermute(labels)
                accuracy_null, coef_null = classifLeaveOneGroupOutPerm(fmri_masked, labels_perm, groups, alpha, best_lambda)
                accuracies_null.append(accuracy_null)

                if i == 0:
                    coef_null_perm = coef_null
                    # print(coef_null_perm.shape)
                else:
                    coef_null_perm = np.concatenate((coef_null_perm, coef_null), axis=0)
                    # print(coef_null_perm.shape)
            # save actual accaracy and permutation accuracies, and actual coef and permutation coefs
            # to assess significance of ROI importance
            perm_outputf = 'ansari_new/glmnet_alpha_' + str(alpha) + '_' + mask_name + '_permutation_' + str(no_permutations) + '.npz'
            np.savez(perm_outputf, accuracy=accuracy, accuracy_perm=accuracies_null, coef=coef,
                     coef_perm=coef_null_perm)

            ''' Test for significance'''
            sorted_mean_accuracy_perm = np.sort(accuracies_null)
            ix = np.where(sorted_mean_accuracy_perm >= accuracy)
            if len(ix[0]) > 0:
                thresh = 1.0 - ix[0][0] / len(sorted_mean_accuracy_perm)
                print("Threshold =", thresh)
                if thresh <= 0.05:
                    print("Permutation test is Significant")
                else:
                    print("Permutation test is NOT Significant")
            else:
                print("Permutation test is Significant as p = 0")



