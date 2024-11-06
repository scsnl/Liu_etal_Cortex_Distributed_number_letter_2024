from nilearn import image, plotting, input_data
import numpy as np
import glob
import os
import warnings
warnings.filterwarnings('ignore')

if __name__ == '__main__':

    data_path = 'ansari_new/glmnet_alpha_0.1_stanford_omnibusF_masked_mask_01k0_permutation_5000.npz'
    data = np.load(data_path)
    print(data_path)

    # create masker necessary for saving data into nii.gz
    # mask = 'masks/vbm_grey_mask.nii'
    mask = '' # your path to the omnibus F test results mask
    masker = input_data.NiftiMasker(mask_img=mask)
    tmp = masker.fit_transform(mask)
    print(tmp.shape)

    # load data
    coef = data['coef']
    coef_perm = data['coef_perm']

    # # generate a whole-brain p-value map
    # sig = (np.abs(coef) > np.abs(coef_perm))
    # pvals = np.sum(sig, axis=0) / coef_perm.shape[0]
    # print(pvals.shape, coef_perm.shape[0])
    #
    # p_img = masker.inverse_transform(pvals)
    # p_fname = 'stanford/svm_abs_coef_pmap_vbm_mask_l2.nii.gz'
    # p_img.to_filename(p_fname)

    # save data to nii.gz to faciliate further extracting using ROI masks
    coef_img = masker.inverse_transform(np.abs(coef))
    f_actual = 'ansari_new/glmnet_abs_coef_alpha_0.1_stanford_omnibusF_masked_mask_01k0.nii.gz'
    coef_img.to_filename(f_actual)

    coef_perm_img = masker.inverse_transform(np.abs(coef_perm))
    f_perm = 'ansari_new/glmnet_abs_coef_perm5000_img_alpha_0.1_stanford_omnibusF_masked_mask_01k0.nii.gz'
    coef_perm_img.to_filename(f_perm)

    # roi masks
    roi_sets = ['rois/insula/*'] #['rois/secondary_set/niifile/*'] #['rois/stanford_whole_brain_decoding_double_new_rois/niifile/*','rois/stanford_rsa/*','rois/canonical/*','rois/cyto/*','rois/cyto_left/*']
    print(len(roi_sets))
    for ss in range(len(roi_sets)):
        roi_set = roi_sets[ss]
        roi_list = glob.glob(roi_set)
        print(len(roi_list))

        for d in range(len(roi_list)):
            print(os.path.basename(roi_list[d]))
            # print(roi_list[d])
            roi_img = roi_list[d]
            roi_masker = input_data.NiftiMasker(mask_img=roi_img)
            roi_coef_act = roi_masker.fit_transform(f_actual)
            roi_coef_perm = roi_masker.fit_transform(f_perm)
            # print(roi_coef_act.shape, roi_coef_perm.shape)
            roi_avg_act = np.mean(roi_coef_act, axis=1)
            roi_avg_perm = np.mean(roi_coef_perm, axis=1)
            print(roi_avg_act.shape, roi_avg_perm.shape)
            print('actual roi stats is {}'.format(roi_avg_act))

            sorted_roi_avg_perm = np.sort(roi_avg_perm)
            ix = np.where(sorted_roi_avg_perm >= roi_avg_act)
            if len(ix[0]) > 0:
                    p = 1.0 - ix[0][0] / len(sorted_roi_avg_perm)
                    print("p =", p)
            else:
                    print("p = 0")





