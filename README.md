# Music-fMRI

IN PROGRESS

This repository contains the code used in the Music-fMRI project (cite this).  

raw data can be found (link here) 

I tried to include matlab dependencies, but this version uses the MATLAB parallel toolbox so your system must be set up accordingly. Some file paths need to be modified as well.

Usage is pretty much the same as any analysis in the rsatoolbox by Nili et al (2014). The workflow is like this:
Run all preprocessing in FSL and convert beta-maps to Analyze format 

fslchfiletype NIFTI_PAIR ${BETA}.nii.gz

Run searchlight analysis in MATLAB

1. edit defineUserOptions.m and fill out study information (subject names, paths, etc)

2. edit betaCorrespondence.m (condition names, paths)

3. run followUpSearchlight.m (searchlightMapping and permutationSVM are dependencies of this). I ran it a few lines at a time, rather than simply running the script. 


References
RSA toolbox: 
Nili H, Wingfield C, Walther A, Su L, Marslen-Wilson W, Kriegeskorte N (2014) A Toolbox for Representational Similarity Analysis. PLoS Comput Biol 10(4): e1003553. doi:10.1371/journal.pcbi.1003553

LibSVM:
C.-C. Chang and C.-J. Lin. LIBSVM : a library for support vector machines. ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27, 2011. 
