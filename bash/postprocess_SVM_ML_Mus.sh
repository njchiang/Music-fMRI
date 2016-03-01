#!/bin/bash
:<<doc
registers stat maps to standard space

runs randomise
doc
#standard=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
projectDir=/media/sf_fmri/Music
#projectDir=/media/jeff/pudgyData/fmri/LanguageMVPA
refImage=${projectDir}/fnirt/MNI152_T1_3mm_brain.nii.gz
refMask=${projectDir}/fnirt/MNI152_T1_3mm_brain_mask.nii.gz
targetDir=${projectDir}/Maps/4mm_AvP_LangUnivariate

cd ${targetDir}
#move raw outputs

mkdir raw
mv *.hdr raw
mv *.img raw
cd raw
for f in *.hdr
do
fslchfiletype NIFTI_GZ ${f}
echo ${f}
done

cd raw
for model in L2M M2L L2L M2M
do
for indMap in `ls | grep ${model}_rMap.nii.gz`
do
	echo ${indMap} ${sub}
sub=`echo ${indMap} | cut -d '_' -f1`
#regMat=${projectDir}/registration/${sub}_highres2standard.mat
#flirt -in ${indMap} -out ../std_${indMap} -ref ${refImage} -applyxfm -init ${regMat}
echo ${sub} ${regMat}
warpMap=${projectDir}/registration/${sub}_}warp_highres2standard.mat.nii.gz
applywarp -i ${indMap} -o ../NL_${indMap} -r ${refImage} -w ${warpMap} 

done
flirt -in Mus012_language_univariate${model}_rMap.nii.gz -ref ${refImage} -out ../NL_Mus012_language_univariate${model}_rMap.nii.gz -applyxfm -init ${projectDir}/registration/Mus012_highres2standard.mat
#fslmerge -t ../Group_L_${model}.nii.gz ../std*_${model}*nii.gz
#randomise -i ../Group_L_${model}.nii.gz -o ../L_n1000_${model} -1 -T -n 1000 -m ${projectDir}/masks/3mm_grayMatter.hdr
fslmerge -t ../Group_NL_${model}.nii.gz ../NL*${model}*nii.gz
fslmaths ../Group_NL_${model} -sub 50 -nan ../Group_NL_${model}
randomise -i ../Group_NL_${model}.nii.gz -o ../NL_n1000_${model} -1 -T -n 1000  --uncorrp #-m ${projectDir}/masks/3mm_overlap_univariate.nii.gz
done

