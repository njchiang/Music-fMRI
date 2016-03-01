%% RSASearchlight
% simulates fMRI data for a number of subjects and runs searchlight
% analysis using RSA, computes the similarity maps for each subject
% and does group level inference.

%%%%%%%%%%%%%%%%%%%%
%% Initialisation %%
%%%%%%%%%%%%%%%%%%%%
clear;clc
returnHere = pwd; % We'll come back here later
% cd ..
toolboxRoot = ['Z:/Box Sync/UCLA/Research/Music_fMRI/code']; addpath(genpath(toolboxRoot));
% Generate a userOptions structure
% cd /Volumes/pudgyDrive/Music
userOptions = defineUserOptions_music(); %edit this
userOptions.searchlightRadius=6;
userOptions.analysisName='Follow_up';
% userOptions.rootPath = [pwd,filesep];
% userOptions.analysisName = 'Searchlight';

% Generate a simulationOptions structure.
% simulationOptions = simulationOptions_demo_SL();

%% config
searchlightOptions.monitor = false;
searchlightOptions.fisher = true;

searchlightOptions.nConditions=size(betaCorrespondence_music2(),2);
searchlightOptions.nSessions=size(betaCorrespondence_music2(),1);
Nsubjects = length(userOptions.subjectNames);

mapsFilename = [userOptions.analysisName, '_fMRISearchlight_Maps.mat'];
RDMsFilename = [userOptions.analysisName, '_fMRISearchlight_RDMs.mat'];
DetailsFilename = [userOptions.analysisName, '_fMRISearchlight_Details.mat'];


%% loading structurals: I DON'T DO THIS
% load([returnHere,filesep,'sampleMask_org.mat'])
% load([returnHere,filesep,'anatomy.mat']);% load the resliced structural image
% warpFlags.interp = 1;
% warpFlags.wrap = [0 0 0];
% userOptions.voxelSize = [3 3 3];
% warpFlags.vox = userOptions.voxelSize; % [3 3 3.75]
% warpFlags.bb = [-78 -112 -50; 78 76 85];
% warpFlags.preserve = 0;

%initialize data
% fullBrainVols = fMRIDataPreparation(betaCorrespondence_music2(), userOptions);
% a=load('ImageData/SearchlightMusic_ImageData_L')
% fullBrainVols_Lang=a.fullBrainVols;
% clear a;
% a=load('ImageData/SearchlightMusic_ImageData_M')
% fullBrainVols_Mus=a.fullBrainVols;
% clear a;
a=load('ImageData/SearchlightMusic_ImageData');
fullBrainVols=a.fullBrainVols;
clear a
userOptions.maskNames={'grayMatter'};
% % binaryMasks_nS = fMRIMaskPreparation(userOptions);
% load('ImageData/SearchlightMusic_Masks')
load('ImageData/Follow_Up_Masks')
load('ImageData/IFG_followUp_Masks.mat')
load('ImageData/SearchlightMusic_Masks.mat')

% models = constructModelRDMs(modelRDMs_searchlight2, userOptions);
models(1).name='L2M';
models(1).label=[ones(1,28) 2*ones(1,14)];
models(2).name='M2L';
models(2).label=models(1).label;
% models(3).name='L2L';
% models(3).label=models(1).label;
% models(4).name='M2M';
% models(4).label=models(1).label;
%%compute the correlation maps per subject
% add mask loop?
% maskName = userOptions.maskNames;
% maskName='grayMatter'; % set the mask
maskName='uniOverlap'; % set the mask
maskName='LH_InferiorFrontalGyrus';
maskName='grayMatter';
% parpool open

for subI = 1:length(userOptions.subjectNames) % can parallelize
% for subI = 14:Nsubjects % can parallelize
    subject=userOptions.subjectNames{subI};
    fprintf(['extracting fullBrain volumes for subject %d \n'],subI)
    singleSubjectVols=fullBrainVols.(subject);
    
    userOptions.searchlightRadius = 6;
    mask = binaryMasks_nS.(subject).(maskName);
    fprintf(['computing correlation maps for subject %d \n'],subI)
    %     [rs, ps, ns, searchlightRDMs.(subject)] = searchlightMapping_fMRI(singleSubjectVols, models, mask, userOptions, searchlightOptions);
    tic
    [rs, ps, ns] = searchlight_MusicSVM(singleSubjectVols, models(1).label, mask, userOptions, searchlightOptions);
%     [rs, ps, ns] = searchlight_MusicSVMAP(singleSubjectVols, models(1).label, mask, userOptions, searchlightOptions);
    toc
    % NEED TO DELETE STRUCTURALSPATH BEFORE RUNNING BECAUSE I DON'T KNOW HOW IT
    % WORKS
    %     [rs, ps, ns, searchlightRDMs] = fMRISearchlight_jeff(singleSubjectVols, models, mask, userOptions, searchlightOptions);
    for modelI=1:length(models)
        modelName=models(modelI).name;
        gotoDir(userOptions.rootPath, 'Maps');
        
        fName= strcat(subject,  '_', maskName, modelName, '_rMap');
        if class(fName)=='cell'
            writeOpts.name=fName{1};
        else
            writeOpts.name=fName;
        end
        writeOpts.description=[subject '_R-Map'];
        writeOpts.template=[userOptions.rootPath '/template_brain.hdr'];
        writeMe=rs(:,:,:,modelI);
        write_brainMap(writeMe, userOptions, writeOpts);
        
        
        fName= strcat(subject,  '_', maskName, modelName, '_thresh');
        if class(fName)=='cell'
            writeOpts.name=fName{1};
        else
            writeOpts.name=fName;
        end
        writeOpts.description=[subject '_Threshold'];
        writeOpts.template=[userOptions.rootPath '/template_brain.hdr'];
        writeMe=ps(:,:,:,modelI);
        write_brainMap(writeMe, userOptions, writeOpts);
    end
    save(['rs_',subject,'.mat'],'rs', 'ps');
    %     save(['RDMs_', subject, '.mat'], 'searchlightRDMs', '-v7.3');
    clear rs ps
    cd(returnHere)
    
    cd(returnHere)
    
end %subjectloop
   delete(gcp)

