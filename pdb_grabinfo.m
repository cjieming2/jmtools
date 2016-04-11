clear all
clc
close all

%% retrieve information from files
cd('/home/jc2296/workspace/lynne_ppi/combined/3-LitVerified/structures');
pdbfiles = dir('/home/jc2296/workspace/lynne_ppi/combined/3-LitVerified/structures/*.pdb');
fid = fopen('pdbgrabinfo_113_output.txt','w');

% variables
pdbstruct = {length(pdbfiles)};
pdbwant = {length(pdbfiles)};
header = {'pdbfile' 'resolution' 'numChains' 'chainID' 'numOfResidues_chains_total' 'protSeq' };
fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\n', header{1,:});

% retrieving PDB information
for i=1:length(pdbfiles)
    pdbwant{i,1} = pdbfiles(i).name;
    % pdbwant{i,1} = pdbfiles{i};
    pdbstruct = pdbread(char(pdbfiles(i).name));

    % retrieve resolution 2
    tline = pdbstruct.Remark2.Detail;
    if strcmp(tline(1:11),'RESOLUTION.')
        if strcmp(tline(21:27),'ANGSTRO')
           pdbwant{i,2} = str2double(tline(12:20));
        else
           pdbwant{i,2} = 0;
        end
    else
        disp([char(pdbfiles(i).name), ' has no resolution data']);
    end
    
    % retrieve #chains 3
    numchains = length(pdbstruct.Sequence);
    pdbwant{i,3} = numchains;
    
    % retrieve sequence info: numOfRes 5, chainID 4, protSeq 6
    chainNumRes = zeros(numchains);
    chainNumResText = '';
    chainIDText = '';
    protSeqText = '';
    totalNumRes = 0;
    for c=1:numchains 
        % numOfRes 5
        chainNumRes = pdbstruct.Sequence(1,c).NumOfResidues;
        chainNumResText = strcat(chainNumResText,'_',num2str(chainNumRes));
        totalNumRes = totalNumRes + chainNumRes;
        
        % chainID 4
        chainID = pdbstruct.Sequence(1,c).ChainID;
        chainIDText = strcat(chainIDText,'_',chainID);
        
        % protSeq 6
        protSeq = pdbstruct.Sequence(1,c).Sequence;
        protSeqText = strcat(protSeqText,'_',protSeq);
    end
    pdbwant{i,4} = chainIDText;
    pdbwant{i,5} = strcat(chainNumResText,'_',num2str(totalNumRes));
    pdbwant{i,6} = protSeqText;
    fprintf(fid, '%s\t%d\t%d\t%s\t%s\t%s\n', pdbwant{i,:});
end

%pdbwant = [header; pdbwant];

fclose(fid);
