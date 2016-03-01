#!/bin/bash
:<<doc
threshold each image by its thresh
binarize
doc

#cd /Users/njchiang/Desktop/UCLA/scratchpad/Music/across_permutation
cd /Volumes/fmri/Music/withinHist/
for model in L2M M2L #uniOverlapL2M uniOverlapM2L
do
for sub in Mus001 Mus003 Mus005 Mus006 Mus007 Mus008 Mus009 Mus010 Mus011 Mus013 Mus014 Mus015 Mus016 Mus017 Mus019 Mus020 Mus021 Mus022 Mus023
do
	echo ${sub} ${model}
	thr='0.001'	
	fslmaths ${sub}_${model}_rMap.nii.gz -nan subData.nii.gz
	fslmaths ${sub}_uniOverlap${model}_thresh.nii.gz -nan subThresh
	fslmaths subData.nii.gz -sub subThresh.nii.gz -add ${thr} -mas subData.nii.gz tmp.nii.gz
	fslmaths tmp.nii.gz -thr 0 tmp.nii.gz
	fslmaths tmp.nii.gz -bin ${sub}_${model}_sig.nii.gz
	rm tmp.nii.gz
	rm subData.nii.gz
	rm subThresh.nii.gz
#	applywarp -i ${sub}_${model}_sig.nii.gz -o ${sub}_${model}_sig_std.nii.gz -r ../../fnirt/MNI152_T1_3mm_brain.nii.gz -w ../../registration/${sub}_}warp_highres2standard.mat.nii.gz 
#	fslmaths ${sub}_${model}_sig_std.nii.gz -bin -mas ../masks/3mm_mask_Ctx_LH_InferiorFrontalGyrus.nii.gz ${sub}_${model}_sig_std.nii.gz
done
	sub=Mus012
	fslmaths ${sub}_${model}_rMap.nii.gz -nan subData.nii.gz
	fslmaths ${sub}_uniOverlap${model}_thresh.nii.gz -nan subThresh
	fslmaths subData.nii.gz -sub subThresh.nii.gz -add ${thr} -mas subData.nii.gz tmp.nii.gz
	fslmaths tmp.nii.gz -thr 0 tmp.nii.gz
	fslmaths tmp.nii.gz -bin ${sub}_${model}_sig.nii.gz
	rm tmp.nii.gz
	rm subData.nii.gz
	rm subThresh.nii.gz
	echo ${sub}
	
#	flirt -in ${sub}_${model}_sig.nii.gz -ref ../../fnirt/MNI152_T1_3mm_brain.nii.gz -out ${sub}_${model}_sig_std.nii.gz -applyxfm -init ../../registration/${sub}_highres2standard.mat
#	fslmaths ${sub}_${model}_sig_std.nii.gz -bin -mas ../../masks/3mm_mask_Ctx_LH_InferiorFrontalGyrus.nii.gz ${sub}_${model}_sig_std.nii.gz

#	fslmerge -t ../Thresh_${model}.nii.gz *${model}_sig_std.nii.gz#
#	fslmaths Thresh_${model}.nii.gz -Tmean Thresh_${model}_mean.nii.gz
done

#fslmaths Thresh_LH_InferiorFrontalGyrusL2M -add Thresh_LH_InferiorFrontalGyrusM2L -thr 1.5 -bin Thresh_LH_InferiorFrontalGyrusOverlap.nii.gz
