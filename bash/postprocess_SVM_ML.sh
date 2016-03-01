#!/bin/bash
:<<doc
registers stat maps to standard space

runs randomise
doc
#standard=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
#projectDir=/media/sf_fmri/Music
#projectDir=/media/jeff/pudgyData/fmri/Music
projectDir=/Volumes/fmri/Music
refImage=${projectDir}/fnirt/MNI152_T1_3mm_brain.nii.gz
refMask=${projectDir}/fnirt/MNI152_T1_3mm_brain_mask.nii.gz
targetDir=${projectDir}/Maps

cd ${targetDir}
#move raw outputs

mkdir raw
mkdir std
mv *.hdr raw
mv *.img raw
cd raw
for f in *.hdr
do
fslchfiletype NIFTI_GZ ${f}
echo ${f}
done

#cd raw
for model in L2M M2L #L2L M2M
do
for indMap in `ls | grep ${model}_rMap.nii.gz`
do
	echo ${indMap} ${sub}
sub=`echo ${indMap} | cut -d '_' -f1`
#regMat=${projectDir}/registration/${sub}_highres2standard.mat
#flirt -in ${indMap} -out ../std_${indMap} -ref ${refImage} -applyxfm -init ${regMat}
echo ${sub} ${regMat}
fslmaths ${indMap} -nan -bin tmp.nii.gz
fslmaths tmp.nii.gz -mul 50 tmp.nii.gz
fslmaths ${indMap} -nan -sub tmp.nii.gz rnd_${indMap}
warpMap=${projectDir}/registration/${sub}_}warp_highres2standard.mat.nii.gz
applywarp -i rnd_${indMap} -o ../std/NL_${indMap} -r ${refImage} -w ${warpMap} 
rm rnd_${indMap}
rm tmp.nii.gz
done
fslmaths Mus012_grayMatter${model}_rMap.nii.gz -nan -bin tmp.nii.gz
fslmaths tmp.nii.gz -mul 50 tmp.nii.gz
fslmaths Mus012_grayMatter${model}_rMap.nii.gz -nan -sub tmp.nii.gz rnd_Mus012_grayMatter${model}_rMap.nii.gz
flirt -in rnd_Mus012_grayMatter${model}_rMap.nii.gz -ref ${refImage} -out ../std/NL_Mus012_grayMatter${model}_rMap.nii.gz -applyxfm -init ${projectDir}/registration/Mus012_highres2standard.mat
rm tmp.nii.gz
rm rnd_Mus012_grayMatter${model}_rMap.nii.gz
echo Mus012

fslmerge -t ../Group_NL_${model}.nii.gz ../std/NL*${model}*nii.gz
randomise -i ../Group_NL_${model}.nii.gz -o ../NL_LangMap_n1000_${model} -1 -T -n 1000 -m ${projectDir}/masks/3mm_language_univariate.nii.gz --uncorrp
randomise -i ../Group_NL_${model}.nii.gz -o ../NL_MusMapn1000_${model} -1 -T -n 1000 -m ${projectDir}/masks/3mm_music_univariate.nii.gz --uncorrp

done

