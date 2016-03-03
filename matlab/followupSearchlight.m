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
toolboxRoot = ['D:/GitHub/Music-fMRI/matlab']; addpath(genpath(toolboxRoot));
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
% if starting from scratch, run this:
% fullBrainVols = fMRIDataPreparation(betaCorrespondence_music2(), userOptions);
% binaryMasks_nS = fMRIMaskPreparation(userOptions);

% load previously generated files
a=load('ImageData/SearchlightMusic_ImageData');
fullBrainVols=a.fullBrainVols;
clear a
userOptions.maskNames={'grayMatter'};
% load the corresponding masks. Run the whole brain in case, but the stats
% are only run in the correct regions (we didn't look at the remainder of
% the brain)

% load('ImageData/SearchlightMusic_Masks')
% load('ImageData/Follow_Up_Masks')
% load('ImageData/IFG_followUp_Masks.mat')
load('ImageData/SearchlightMusic_Masks.mat')

% configure labels or hypothesis matrices
% models = constructModelRDMs(modelRDMs_searchlight2, userOptions);
models(1).name='L2M';
models(1).label=[ones(1,28) 2*ones(1,14)];
models(2).name='M2L';
models(2).label=models(1).label;
% models(3).name='L2L';
% models(3).label=models(1).label;
% models(4).name='M2M';
% models(4).label=models(1).label;

% set the mask
% maskName = userOptions.maskNames;
% maskName='grayMatter'; % set the mask
% maskName='uniOverlap'; % set the mask
% maskName='LH_InferiorFrontalGyrus';
maskName='grayMatter';
% parpool open

for subI = 1:length(userOptions.subjectNames)
    subject=userOptions.subjectNames{subI};
    fprintf(['extracting fullBrain volumes for subject %d \n'],subI)
    singleSubjectVols=fullBrainVols.(subject);
    userOptions.searchlightRadius = 6;
    mask = binaryMasks_nS.(subject).(maskName);
    fprintf(['computing correlation maps for subject %d \n'],subI)
    % searchlight analysis
    tic
    [rs, ps, ns] = searchlight_MusicSVM(singleSubjectVols, models(1).label, mask, userOptions, searchlightOptions);
    %     [rs, ps, ns] = searchlight_MusicSVMAP(singleSubjectVols, models(1).label, mask, userOptions, searchlightOptions);
    toc
    % write NIFTI images
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
        % the template brain is the example functional image for each
        % subject
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
    clear rs ps
    cd(returnHere)
    
end %subjectloop
delete(gcp)

