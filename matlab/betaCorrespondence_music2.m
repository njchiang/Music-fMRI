function betas = betaCorrespondence_music()
%
%  betaCorrespondence.m is a simple function which should combine
%  three things: preBeta:	a string which is at the start of each file
%  containing a beta image, betas:	a struct indexed by (session,
%  condition) containing a sting unique to each beta image, postBeta:	a
%  string which is at the end of each file containing a beta image, not
%  containing the file .suffix
% 
%  use "[[subjectName]]" as a placeholder for the subject's name as found
%  in userOptions.subjectNames if necessary For example, in an experment
%  where the data from subject1 (subject1 name)  is saved in the format:
%  subject1Name_session1_condition1_experiment1.img and similarly for the
%  other conditions, one could use this function to define a general
%  mapping from experimental conditions to the path where the brain
%  responses are stored. If the paths are defined for a general subject,
%  the term [[subjectName]] would be iteratively replaced by the subject
%  names as defined by userOptions.subjectNames.
% 
%  note that this function could be replaced by an explicit mapping from
%  experimental conditions and sessions to data paths.
% 
%  Cai Wingfield 1-2010
%__________________________________________________________________________
% Copyright (C) 2010 Medical Research Council

preBeta = '';

% betas(session, condition).identifier = ???
all_conds={ ...
'run1_langActive_1', ...
'run1_langActive_2', ...
'run1_langActive_3', ...
'run2_langActive_1', ...
'run2_langActive_2', ...
'run2_langActive_3', ...
'run2_langActive_4', ...
'run3_langActive_1', ...
'run3_langActive_2', ...
'run3_langActive_3', ...
'run4_langActive_1', ...
'run4_langActive_2', ...
'run4_langActive_3', ...
'run4_langActive_4', ...
'run1_langPassive_1', ...
'run1_langPassive_2', ...
'run1_langPassive_3', ...
'run1_langPassive_4', ...
'run2_langPassive_1', ...
'run2_langPassive_2', ...
'run2_langPassive_3', ...
'run3_langPassive_1', ...
'run3_langPassive_2', ...
'run3_langPassive_3', ...
'run3_langPassive_4', ...
'run4_langPassive_1', ...
'run4_langPassive_2', ...
'run4_langPassive_3', ...
'run1_langRepeat_1', ...
'run1_langRepeat_2', ...
'run1_langRepeat_3', ...
'run2_langRepeat_1', ...
'run2_langRepeat_2', ...
'run2_langRepeat_3', ...
'run2_langRepeat_4', ...
'run3_langRepeat_1', ...
'run3_langRepeat_2', ...
'run3_langRepeat_3', ...
'run4_langRepeat_1', ...
'run4_langRepeat_2', ...
'run4_langRepeat_3', ...
'run4_langRepeat_4', ...
'run1_musicRoot_1', ...
'run1_musicRoot_2', ...
'run1_musicRoot_3', ...
'run1_musicRoot_4', ...
'run2_musicRoot_1', ...
'run2_musicRoot_2', ...
'run2_musicRoot_3', ...
'run3_musicRoot_1', ...
'run3_musicRoot_2', ...
'run3_musicRoot_3', ...
'run3_musicRoot_4', ...
'run4_musicRoot_1', ...
'run4_musicRoot_2', ...
'run4_musicRoot_3', ...
'run1_music2ndInv_1', ...
'run1_music2ndInv_2', ...
'run1_music2ndInv_3', ...
'run2_music2ndInv_1', ...
'run2_music2ndInv_2', ...
'run2_music2ndInv_3', ...
'run2_music2ndInv_4', ...
'run3_music2ndInv_1', ...
'run3_music2ndInv_2', ...
'run3_music2ndInv_3', ...
'run4_music2ndInv_1', ...
'run4_music2ndInv_2', ...
'run4_music2ndInv_3', ...
'run4_music2ndInv_4', ...
'run1_musicRepeat_1', ...
'run1_musicRepeat_2', ...
'run1_musicRepeat_3', ...
'run1_musicRepeat_4', ...
'run2_musicRepeat_1', ...
'run2_musicRepeat_2', ...
'run2_musicRepeat_3', ...
'run3_musicRepeat_1', ...
'run3_musicRepeat_2', ...
'run3_musicRepeat_3', ...
'run3_musicRepeat_4', ...
'run4_musicRepeat_1', ...
'run4_musicRepeat_2', ...
'run4_musicRepeat_3' 
};

for i = 1:length(all_conds)
    betas(1,i).identifier=all_conds{i};
end
% for j = 1:length(all_conds)/6;
% 
% for i = 1:6
%         betas(j,i).identifier=all_conds{14*(i-1)+j};
%     end
% end
% betas(1,1).identifier = 'session1_condition1';
% betas(1,2).identifier = 'session1_condition2';
% betas(1,3).identifier = 'session1_condition3';
% betas(1,4).identifier = 'session1_condition4';
% betas(1,5).identifier = 'session1_condition5';
% betas(1,6).identifier = 'session1_condition6';
% betas(1,7).identifier = 'session1_condition7';
% betas(1,8).identifier = 'session1_condition8';

postBeta = '_sub.img';

for session = 1:size(betas,1)
	for condition = 1:size(betas,2)
		betas(session,condition).identifier = [preBeta betas(session,condition).identifier postBeta];
	end%for
end%for