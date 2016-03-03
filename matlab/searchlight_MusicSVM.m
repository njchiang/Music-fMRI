function [smm_rs, smm_ps, n] = searchlight_MusicSVM(fullBrainVolumes, models, mask, userOptions, localOptions)
% this is identical to searchlight_fMRI in the rsa toolbox, except that
% I've added parallelization and a small permutation loop.


% ARGUMENTS
% fullBrainVolumes	A voxel x condition x session matrix of activity
% 				patterns.
%
% models		A struct of model RDMs.
%
% runs          matrix describing which runs the trials were in
% mask     		A 3d or 4d mask to perform the searchlight in.
%
% userOptions and localOptions
%
% RETURN VALUES
% smm_rs        4D array of 3D maps (x by y by z by model index) of
%               correlations between the searchlight pattern similarity
%               matrix and each of the model similarity matrices.
%
% smm_ps        4D array of 3D maps (x by y by z by model index) of p
%               values computed for each corresponding entry of smm_rs.
%
% n             an array of the same dimensions as the volume, which
%               indicates for each position how many voxels contributed
%               data to the corresponding values of the infomaps.
%               this is the number of searchlight voxels, except at the
%               fringes, where the searchlight may illuminate voxels
%               outside the input-data mask or voxel with all-zero
%               time-courses (as can arise from head-motion correction).
%
% mappingMask_actual
%               3D mask indicating locations for which valid searchlight
%               statistics have been computed.
%
% Based on Niko Kriegeskorte's searchlightMapping_RDMs.m
%
% Additions by Cai Wingfield 2-2010:
% 	- Now skips points in the searchlight where there's only one voxel inside.
% 	- Now takes a userOptions struct for the input parameters.

localOptions = setIfUnset(localOptions, 'averageSessions', true);
userOptions=setIfUnset(userOptions, 'analysisType', 'SVM');
%% Figure out whether to average over sessions or not
if localOptions.averageSessions
    for sessionNumber = 1:size(fullBrainVolumes,3)
        thisSessionId = ['s' num2str(sessionNumber)];
        t_patsPerSession.(thisSessionId) = fullBrainVolumes(:,:,sessionNumber)';
    end%for:sessionNumber
else
    justThisSession = 1;
    t_pats = fullBrainVolumes(:,:,justThisSession)';
    
    fprintf(['\nYou have selected not to average over sessions.\n         Only session number ' num2str(justThisSession) ' will be used.\n']);
    
end%if

%% Get parameters
voxSize_mm = userOptions.voxelSize;
searchlightRad_mm = userOptions.searchlightRadius;
monitor = localOptions.monitor;
nConditions = size(fullBrainVolumes, 2);


clear fullBrainVolumes;

% Prepare models
modelRDMs_ltv=models';
% permLabels=permuteLabels(models([1:14, 29:42]), ones(28,1), 1000);
permLabels=permuteLabels(models([1:14, 29:42]), ones(28,1), 1);

% Prepare masks
mask(isnan(mask)) = 0; % Just in case!
if ndims(mask)==3
    inputDataMask=logical(mask);
    mappingMask_request=logical(mask);
else
    inputDataMask=logical(mask(:,:,:,1));
    mappingMask_request=logical(mask(:,:,:,2));
end

% Check to see if there's more data than mask...
if localOptions.averageSessions
    for sessionNumber = 1:numel(fieldnames(t_patsPerSession))
        thisSessionId = ['s' num2str(sessionNumber)];
        t_patsPerSession.(thisSessionId) = t_patsPerSession.(thisSessionId)(:, inputDataMask(:));
    end%for:sessionNumber
else
    if (size(t_pats,2)>sum(inputDataMask(:)))
        t_pats=t_pats(:,inputDataMask(:));
    end%if
end%if

% Other data
volSize_vox=size(inputDataMask);
% nModelRDMs=size(modelRDMs_ltv,1);
nModelRDMs=2;
rad_vox=searchlightRad_mm./voxSize_mm;
minMargin_vox=floor(rad_vox);


%% create spherical multivariate searchlight
[x,y,z]=meshgrid(-minMargin_vox(1):minMargin_vox(1),-minMargin_vox(2):minMargin_vox(2),-minMargin_vox(3):minMargin_vox(3));
sphere=((x*voxSize_mm(1)).^2+(y*voxSize_mm(2)).^2+(z*voxSize_mm(3)).^2)<=(searchlightRad_mm^2);  % volume with sphere voxels marked 1 and the outside 0
sphereSize_vox=[size(sphere),ones(1,3-ndims(sphere))]; % enforce 3D (matlab stupidly autosqueezes trailing singleton dimensions to 2D, try: ndims(ones(1,1,1)). )

if monitor, figure(50); clf; showVoxObj(sphere); end % show searchlight in 3D

% compute center-relative sphere SUBindices
[sphereSUBx,sphereSUBy,sphereSUBz]=ind2sub(sphereSize_vox,find(sphere)); % (SUB)indices pointing to sphere voxels
sphereSUBs=[sphereSUBx,sphereSUBy,sphereSUBz];
ctrSUB=sphereSize_vox/2+[.5 .5 .5]; % (c)en(t)e(r) position (sphere necessarily has odd number of voxels in each dimension)
ctrRelSphereSUBs=sphereSUBs-ones(size(sphereSUBs,1),1)*ctrSUB; % (c)en(t)e(r)-relative sphere-voxel (SUB)indices

nSearchlightVox=size(sphereSUBs,1);


%% define masks
validInputDataMask=inputDataMask;

if localOptions.averageSessions
    for sessionNumber = 1:numel(fieldnames(t_patsPerSession))
        thisSessionId = ['s' num2str(sessionNumber)];
        sumAbsY=sum(abs(t_patsPerSession.(thisSessionId)),1);
    end%for:sessionNumber
else
    sumAbsY=sum(abs(t_pats),1);
end%if

validYspace_logical= (sumAbsY~=0) & ~isnan(sumAbsY); clear sumAbsY;
validInputDataMask(inputDataMask)=validYspace_logical; % define valid-input-data brain mask

if localOptions.averageSessions
    for sessionNumber = 1:numel(fieldnames(t_patsPerSession))
        thisSessionId = ['s' num2str(sessionNumber)];
        t_patsPerSession.(thisSessionId) = t_patsPerSession.(thisSessionId)(:,validYspace_logical);
        nVox_validInputData=size(t_patsPerSession.(thisSessionId),2);
    end%for:sessionNumber
else
    t_pats=t_pats(:,validYspace_logical); % reduce t_pats to the valid-input-data brain mask
    nVox_validInputData=size(t_pats,2);
end%if

mappingMask_request_INDs=find(mappingMask_request);
nVox_mappingMask_request=length(mappingMask_request_INDs);

if monitor
    disp([num2str(round(nVox_mappingMask_request/prod(volSize_vox)*10000)/100),'% of the cuboid volume requested to be mapped.']);
    disp([num2str(round(nVox_validInputData/prod(volSize_vox)*10000)/100),'% of the cuboid volume to be used as input data.']);
    disp([num2str(nVox_validInputData),' of ',num2str(sum(inputDataMask(:))),' declared input-data voxels included in the analysis.']);
end

volIND2YspaceIND=nan(volSize_vox);
volIND2YspaceIND(validInputDataMask)=1:nVox_validInputData;

% n voxels contributing to infobased t at each location
n=nan(volSize_vox);
nVec=nan(size(nVox_mappingMask_request));

%% similarity-graph-map the volume with the searchlight
smm_ps=nan([volSize_vox,nModelRDMs]);
smm_rs=nan([volSize_vox,nModelRDMs]);
vec_ps=nan([nVox_mappingMask_request,nModelRDMs]);
vec_rs=nan([nVox_mappingMask_request,nModelRDMs]);
if strcmp(userOptions.analysisType, 'RSA')
    searchlightRDMs = nan([nConditions, nConditions, volSize_vox]);
end
if monitor
    h_progressMonitor=progressMonitor(1, nVox_mappingMask_request,  'Similarity-graph-mapping...');
end

%% THE BIG LOOP! %%
% rs=zeros(2,1);
parfor cMappingVoxI=1:nVox_mappingMask_request
    
    %     if mod(cMappingVoxI,1000)==0
    %         if monitor
    %             progressMonitor(cMappingVoxI, nVox_mappingMask_request, 'Searchlight mapping Mahalanobis distance...', h_progressMonitor);
    %             %                 cMappingVoxI/nVox_mappingMask_request
    %         else
    %             fprintf('.');
    %         end%if
    %     end%if
    %% apply sphere to index
    [x, y, z]=ind2sub(volSize_vox,mappingMask_request_INDs(cMappingVoxI));
    
    % compute (sub)indices of (vox)els (c)urrently (ill)uminated by the spherical searchlight
    cIllVoxSUBs=repmat([x,y,z],[size(ctrRelSphereSUBs,1) 1])+ctrRelSphereSUBs;
    
    % exclude out-of-volume voxels
    outOfVolIs=(cIllVoxSUBs(:,1)<1 | cIllVoxSUBs(:,1)>volSize_vox(1)|...
        cIllVoxSUBs(:,2)<1 | cIllVoxSUBs(:,2)>volSize_vox(2)|...
        cIllVoxSUBs(:,3)<1 | cIllVoxSUBs(:,3)>volSize_vox(3));
    
    cIllVoxSUBs=cIllVoxSUBs(~outOfVolIs,:);
    
    % list of (IND)ices pointing to (vox)els (c)urrently (ill)uminated by the spherical searchlight
    cIllVox_volINDs=sub2ind(volSize_vox,cIllVoxSUBs(:,1),cIllVoxSUBs(:,2),cIllVoxSUBs(:,3));
    
    % restrict searchlight to voxels inside validDataBrainMask
    cIllValidVox_volINDs=cIllVox_volINDs(validInputDataMask(cIllVox_volINDs));
    cIllValidVox_YspaceINDs=volIND2YspaceIND(cIllValidVox_volINDs);
    
    % note how many voxels contributed to this locally multivariate stat
    nVec(cMappingVoxI)=length(cIllValidVox_YspaceINDs);
    
    if n(x,y,z) < 2, continue; end%if % This stops the function crashing if it accidentally encounters an out-of-brain floating voxel (these can occur if, for example, skull stripping fails)
    %% analysis-THIS PART IS DIFFERENT FROM THE RSATOOLBOX
    if localOptions.averageSessions
        t_pats=zeros(size(t_patsPerSession.s1(:,cIllValidVox_YspaceINDs)));
        for session = 1:localOptions.nSessions
            sessionId = ['s' num2str(session)];
            t_pats = t_pats+t_patsPerSession.(sessionId)(:,cIllValidVox_YspaceINDs);
            t_pats=zscore(t_pats / localOptions.nSessions,0,2);
            l_pats=t_pats(1:42,:);
            m_pats=t_pats(43:84,:);
        end
    end
    
    %%%%%%%
    opts=['-q -t 0'];
    %     tic
    nRand=100;
    %     for m=1:size(models,1)
    %         [rs] = permutationSVM(t_pats, models, runs);
    % randomly grab half of act/pass
    l2m=zeros(1,nRand);
    m2l=zeros(1,nRand);
    l2mthresh=zeros(1,nRand);
    m2lthresh=zeros(1,nRand);
    tmpM2LDist=zeros(nRand, 1000);
    tmpL2MDist=zeros(nRand, 1000);
    for i=1:nRand
        balanceSet=randperm(28); % randomly selecting from "hierarchical" condition
        lSet=l_pats([balanceSet(1:14) 29:42],:);
        mSet=m_pats([balanceSet(1:14) 29:42],:);
        lStruct=libsvmtrain(models([1:14 29:42])', lSet, opts);
        [l2m(i), d, l2mthresh(i)] = permutationSVM(lStruct, mSet, permLabels, ones(28,1));
        tmpL2MDist(i,:)=mean(d,1);
        mStruct=libsvmtrain(models([1:14 29:42])', mSet, opts);
        [m2l(i), d, m2lthresh(i)] = permutationSVM(mStruct, lSet, permLabels, ones(28,1));
        tmpM2LDist(i,:)=mean(d,1);
        %         [~, l2m(:,i), ~]=libsvmpredict(models([1:14 29:42])', mSet, lStruct);
        %         [~, m2l(:,i), ~]=libsvmpredict(models([1:14 29:42])', lSet, mStruct);
        %         l2l(:,i)=libsvmtrain(models([1:14 29:42])', lSet, [opts ' -v 4']);
        %         m2m(:,i)=libsvmtrain(models([1:14 29:42])', mSet, [opts ' -v 4']);
    end
    
    %         rs(1)=mean(l2m(1,:));
    %         rs(2)=mean(m2l(1,:));
    %     end
    %     toc
    %%%%%%%
    
%     ps=nan;
    vec_ps(cMappingVoxI,:) = [quantile(mean(tmpL2MDist,1),.95) quantile(mean(tmpM2LDist,1),.95)];
    vec_rs(cMappingVoxI,:) = [mean(l2m(1,:)) mean(m2l(1,:))];
    %%
end%for:cMappingVoxI

tic
for cMappingVoxI=1:nVox_mappingMask_request
    [x, y, z]=ind2sub(volSize_vox,mappingMask_request_INDs(cMappingVoxI));
    smm_rs(x,y,z,:)=vec_rs(cMappingVoxI,:);
    smm_ps(x,y,z,:)=vec_ps(cMappingVoxI,:);
    n(x,y,z)=nVec(cMappingVoxI);
end
toc
%% END OF THE BIG LOOP! %%

if monitor
    fprintf('\n');
    close(h_progressMonitor);
end

mappingMask_actual=mappingMask_request;
mappingMask_actual(isnan(sum(smm_rs,4)))=0;

%% visualize
if monitor
    aprox_p_uncorr=0.001;
    singleModel_p_crit=aprox_p_uncorr/nModelRDMs; % conservative assumption model proximities nonoverlapping
    smm_min_p=min(smm_ps,[],4);
    smm_significant=smm_min_p<singleModel_p_crit;
    
    vol=map2vol(mask);
    vol2=map2vol(mask);
    
    colors=[1 0 0
        0 1 0
        0 1 1
        1 1 0
        1 0 1];
    
    for modelRDMI=1:nModelRDMs
        vol=addBinaryMapToVol(vol, smm_significant&(smm_bestModel==modelRDMI), colors(modelRDMI,:));
        % 		vol2=addBinaryMapToVol(vol2, smm_bestModel==modelRDMI, colors(modelRDMI,:));
    end
    
    showVol(vol);
    
    % 	vol2 = vol2*0.1;
    % 	vol2(vol<1) = vol(vol<1);
    %
    % 	showVol(vol2);
    
end%if

end%function

