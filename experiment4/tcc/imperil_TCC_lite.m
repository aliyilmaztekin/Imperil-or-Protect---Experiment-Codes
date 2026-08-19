%% TCC Model Analysis

% Select study code
experiment = 6; % 4 or 6
mode = 2; % 1 = only the 1st and 5th reps; 2 = all reps, 1st and 5th reps collapsed across conds

tic

%% Relevant directories
% to access the behavioral data
if ismember(experiment, [1 2 3])
    dataDest = sprintf('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/mixture_modelling/combinedData_thirdpass%d.mat', experiment, experiment);
elseif experiment == 4
    dataDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4';...
elseif experiment == 6
    dataDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_delta_output';
end
       
% DIRs common to all experiments
addpath(genpath('/Users/ali/Desktop/visual imperil project/imperil4materials/tcc_model_analysis/TCC_Code_InManuscriptOrder/Model'));...
    % to access MemToolbox to estimate dprime
addpath('/Users/ali/Desktop/visual imperil project/imperil4materials/tcc_model_analysis/TCC_Code_InManuscriptOrder/Tools/MemToolbox');...
    % to access the psychosimilarity and correlated noise data: TCCCorrelated.m and TCCCorrelated_Precomputed.mat')
addpath('/Users/ali/Desktop/visual imperil project/imperil4materials/tcc_model_analysis/TCC_Code_InManuscriptOrder')

if experiment == 4 
    badParticipants = 62; % outlier
elseif experiment == 6
    badParticipants = [8, 12, 17, 34]; % missing data
end

if experiment == 4 || experiment == 6
    dataFiles = dir(dataDest);
    dataFiles = dataFiles(~ismember({dataFiles.name}, {'.', '..', '.DS_Store'}));
    nSbj = size(dataFiles, 1);
    
    if experiment == 4
        carry = dataFiles(1:2);
        dataFiles(1:2) = [];
        dataFiles(end+1:end+2) = carry;
    end
    
    allSbjs = string({dataFiles.name})';
    
    if experiment == 4    
        allSbjs = erase(allSbjs, "imperil4dataID"); allSbjs = erase(allSbjs, ".mat");
    elseif experiment == 6
        allSbjs = erase(allSbjs, "imperil6DeltaDataID"); allSbjs = erase(allSbjs, ".mat");
    end
    
    allSbjs = sort(str2double(allSbjs),"ascend");
    
    subjList = setdiff(allSbjs(1):allSbjs(end), badParticipants);
    nSubjs = numel(subjList);

else
    
    % Load the long-format data
    load(dataDest)

    % Sample characteristics
    badParticipants = setdiff(1:max(unique(thirdpass(:,1))), unique(thirdpass(:,1)), "stable");

    % Participant IDs
    subjList = setdiff((unique(thirdpass(:,1))), badParticipants);
    nSubjs  = numel(subjList);

    % Value indices
    subCol     = 1;   
    repCol     = 3;  
    contextCol = 10;   
    interfCol  = 11; 

    if experiment == 1
        errCol = 13; % col 5 is abs transformed error, 13 is raw error 
    elseif experiment == 2 || experiment == 3
        errCol = 12;
    end

end

if experiment == 4 || experiment == 6
    % 2 IVs; 4 conds
    conds = [1 2 3 4];
    nCond = length(conds);

    dprime1 = NaN(nSubjs, nCond); % memory strength for novel items
    dprime2 = NaN(nSubjs, nCond); % memory strength for repeated items
else
    % 3 IVs; 8 conds
    conds = 1:8;
    nCond = length(conds);

    dprime = NaN(nSubjs, nCond); % memory strength for the test item
end

subjIDs = NaN(nSubjs, 1);

% Load model 
model = TCCCorrelated();

if mode == 1
    for subjRow = 1:nSubjs
    
        sbj = subjList(subjRow);
        subjIDs(subjRow) = sbj;
    
        % Build filename
        if experiment == 4
            curSbj = sprintf('imperil4dataID%d.mat', sbj);
            fileToLoad = fullfile(dataDest, curSbj);

            % Load file
            load(fileToLoad);  % loads outputMatrix
        elseif experiment == 6
            curSbj = sprintf('imperil6DeltaDataID%d.mat', sbj);
            fileToLoad = fullfile(dataDest, curSbj);

            % Load file
            load(fileToLoad);  % loads outputMatrix
        else
            [dim1 , dim2] = size(thirdpass);
            outputMatrix = NaN(dim1,dim2);
            outputMatrix(:,:) = thirdpass(:,:);
        end
    
        for curCondIdx = 1:nCond
    
            curCond = conds(curCondIdx);
    
            % Select errors for current condition
            if experiment == 4
                curAngle1 = outputMatrix(outputMatrix(:,19) == curCond, 10); % Test 1 error (novel items tested)
                curAngle2 = outputMatrix(outputMatrix(:,19) == curCond, 14); % Test 2 error (repeated items tested)
            elseif experiment == 6
                curAngle1 = outputMatrix(outputMatrix(:,23) == curCond & outputMatrix(:,13) == 3, 14); % Novel item error
                curAngle2 = outputMatrix(outputMatrix(:,23) == curCond & outputMatrix(:,13) ~= 3, 14); % Repeated item error
            else
                curAngle = outputMatrix( outputMatrix(:,9) == curCond ...
                                       & outputMatrix(:,subCol) == sbj, end );            
            end
            
            if experiment == 4 || experiment == 6
                % Wrap errors
                errors1 = mod(curAngle1 + 180, 360) - 180;
                errors2 = mod(curAngle2 + 180, 360) - 180;
        
                % Remove timed-out responses
                errors1 = errors1(~isnan(errors1));
                errors2 = errors2(~isnan(errors2));
            else
                error = curAngle;
            end
    
            % Skip if too few trials
            if experiment == 4 || experiment == 6
                if numel(errors1) < 5 || numel(errors2) < 5
                    warning('Subject %d, condition %d has too few trials.', sbj, curCond);
                    continue;
                end
            else
                if numel(error) < 5
                    warning('Subject %d, condition %d has too few trials.', sbj, curCond);
                    continue;
                end
            end
            
            if experiment == 4 || experiment == 6
                try
                   
                    % Fit TCC model for test 1
                    data = struct();
                    data.errors = errors1;
                    fit1 = MemFit(data, model, 'Verbosity', 0);
        
                    % Fit TCC model for test 2
                    data = struct();
                    data.errors = errors2;
                    fit2 = MemFit(data, model, 'Verbosity', 0);
        
                    % Store MAP estimates
                    dprime1(subjRow, curCondIdx) = fit1.maxPosterior;
                    dprime2(subjRow, curCondIdx) = fit2.maxPosterior;
        
                catch ME
                    warning('Fit failed for subject %d, condition %d: %s', ...
                            sbj, curCond, ME.message);
                    continue;
                end 
            else
                try
                    % Fit TCC model
                    data = struct();
                    data.errors = error;
                    fit = MLE(data, model, 'Verbosity', 0);

                    % Store MAP estimates
                    dprime(subjRow, curCondIdx) = fit.maxPosterior;
                    
                catch ME
                    warning('Fit failed for subject %d, condition %d: %s', ...
                        sbj, curCond, ME.message);
                    continue;
                end
            end
        end
    
        fprintf('Finished subject %d (%d/%d)\n', sbj, subjRow, nSubjs);
    
    end
    
    if experiment == 4 || experiment == 6
        cond1test1 = dprime1(:,1);
        cond2test1 = dprime1(:,2);
        cond3test1 = dprime1(:,3);
        cond4test1 = dprime1(:,4);
        
        cond1test2 = dprime2(:,1);
        cond2test2 = dprime2(:,2);
        cond3test2 = dprime2(:,3);
        cond4test2 = dprime2(:,4);
        
        finD1 = [cond1test1; cond2test1; cond3test1; cond4test1];
        finD2 = [cond1test2; cond2test2; cond3test2; cond4test2];
    
    else

        cond1 = dprime(:,1);
        cond2 = dprime(:,2);
        cond3 = dprime(:,3);
        cond4 = dprime(:,4);
        cond5 = dprime(:,5);
        cond6 = dprime(:,6);
        cond7 = dprime(:,7);
        cond8 = dprime(:,8);

        finD = [cond1; cond2; cond3; cond4;...
            cond5; cond6; cond7; cond8];

    end

    subjIDs_long = repmat(subjIDs, length(conds), 1);
    
    if experiment == 4 || experiment == 6
        reps = [
            repmat(1, nSubjs, 1);  % cond 1
            repmat(1, nSubjs, 1);  % cond 2
            repmat(5, nSubjs, 1);  % cond 3
            repmat(5, nSubjs, 1)   % cond 4
        ];
        
        change = [
            repmat(0, nSubjs, 1);  % cond 1
            repmat(1, nSubjs, 1);  % cond 2
            repmat(0, nSubjs, 1);  % cond 3
            repmat(1, nSubjs, 1)   % cond 4
        ];
        
        finalMatrix = [subjIDs_long, reps, change, finD1, finD2];
    else

        reps = [
            repmat(1, nSubjs, 1);  
            repmat(1, nSubjs, 1);  
            repmat(1, nSubjs, 1);  
            repmat(1, nSubjs, 1);   
            repmat(5, nSubjs, 1);  
            repmat(5, nSubjs, 1);  
            repmat(5, nSubjs, 1);  
            repmat(5, nSubjs, 1)   
            ];

        change = [
            repmat(0, nSubjs, 1);   % cond 1
            repmat(0, nSubjs, 1);   % cond 2
            repmat(1, nSubjs, 1);   % cond 3
            repmat(1, nSubjs, 1);   % cond 4
            repmat(0, nSubjs, 1);   % cond 5
            repmat(0, nSubjs, 1);   % cond 6
            repmat(1, nSubjs, 1);   % cond 7
            repmat(1, nSubjs, 1)    % cond 8
            ];

        interference = [
            repmat(0, nSubjs, 1);  
            repmat(1, nSubjs, 1); 
            repmat(0, nSubjs, 1); 
            repmat(1, nSubjs, 1);
            repmat(0, nSubjs, 1);  
            repmat(1, nSubjs, 1);  
            repmat(0, nSubjs, 1);  
            repmat(1, nSubjs, 1)   
            ];

        finalMatrix = [subjIDs_long, reps, change, interference, finD];
    end

    if experiment == 4
        save(fullfile('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/tcc', 'imperil4_TCC_subjectwise_dprime.mat'), "finalMatrix")
    elseif experiment == 6
        save(fullfile('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/TCC', 'imperil6_TCC_full_model_dprime.mat'), "finalMatrix")
    else

        outDest = sprintf('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/TCC/param_out', experiment);

        if ~exist(outDest, "dir")
            mkdir(outDest);
        end
        save(fullfile(outDest, ...
            sprintf('imperil%d_TCC_full_model_dprime.mat', experiment)), "finalMatrix")
    end
    
    % shut down parallel processing pool
    delete(gcp('nocreate'))

    toc

elseif mode == 2
    for subjRow = 1:nSubjs

        sbj = subjList(subjRow);
        subjIDs(subjRow) = sbj;
    
        % Build filename
        if experiment == 4
            curSbj = sprintf('imperil4dataID%d.mat', sbj);
            fileToLoad = fullfile(dataDest, curSbj);
            % Load file
            load(fileToLoad); 
        elseif experiment == 6
            curSbj = sprintf('imperil6DeltaDataID%d.mat', sbj);
            fileToLoad = fullfile(dataDest, curSbj);
            load(fileToLoad);  % loads outputMatrix
        else
            [dim1 , dim2] = size(thirdpass);
            outputMatrix = NaN(dim1,dim2);
            outputMatrix(:,:) = thirdpass(:,:);
        end
    
        for curRep = 1:6
    
            % Select errors for current repetition
            if experiment == 4
                curAngle1 = outputMatrix(outputMatrix(:,5) == curRep, 10); % Test 1 error (novel items tested)
                curAngle2 = outputMatrix(outputMatrix(:,5) == curRep, 14); % Test 2 error (repeated items tested)
            elseif experiment == 6
                curAngle1 = outputMatrix(outputMatrix(:,5) == curRep & outputMatrix(:,13) == 3, 14); % Novel item error
                curAngle2 = outputMatrix(outputMatrix(:,5) == curRep & outputMatrix(:,13) ~= 3, 14); % Repeated item error
            else
                curAngle = outputMatrix(outputMatrix(:,repCol) == curRep ...
                    & outputMatrix(:,subCol) == sbj, end);   
            end
            
            if experiment == 4 || experiment == 6
                % Wrap errors
                errors1 = mod(curAngle1 + 180, 360) - 180;
                errors2 = mod(curAngle2 + 180, 360) - 180;
        
                % Remove timed-out responses
                errors1 = errors1(~isnan(errors1));
                errors2 = errors2(~isnan(errors2));
        
                % Skip if too few trials
                if numel(errors1) < 5 || numel(errors2) < 5
                    warning('Subject %d, condition %d has too few trials.', sbj, curRep);
                    continue;
                end
            else
                error = curAngle;

                % Skip if too few trials
                if numel(error) < 5
                    warning('Subject %d, condition %d has too few trials.', sbj, curRep);
                    continue;
                end
            end
            
            if experiment == 4 || experiment == 6
                try
                    % Fit TCC model for test 1
                    data = struct();
                    data.errors = errors1;
                    fit1 = MemFit(data, model, 'Verbosity', 0);
        
                    % Fit TCC model for test 2
                    data = struct();
                    data.errors = errors2;
                    fit2 = MemFit(data, model, 'Verbosity', 0);
        
                    % Store MAP estimates
                    dprime1(subjRow, curRep) = fit1.maxPosterior;
                    dprime2(subjRow, curRep) = fit2.maxPosterior;
        
                catch ME
                    warning('Fit failed for subject %d, condition %d: %s', ...
                            sbj, curRep, ME.message);
                    continue;
                end
            else
                try
                    % Fit TCC model
                    data = struct();
                    data.errors = error;
                    fit = MemFit(data, model, 'Verbosity', 0);

                    % Store MAP estimates
                    dprime(subjRow, curRep) = fit.maxPosterior;

                catch ME
                    warning('Fit failed for subject %d, condition %d: %s', ...
                        sbj, ME.message);
                    continue;
                end
            end
        end
    
        fprintf('Finished subject %d (%d/%d)\n', sbj, subjRow, nSubjs);
    
    end
    
    if experiment == 4 || experiment == 6
        rep1test1 = dprime1(:,1);
        rep2test1 = dprime1(:,2);
        rep3test1 = dprime1(:,3);
        rep4test1 = dprime1(:,4);
        rep5test1 = dprime1(:,5);
        rep6test1 = dprime1(:,6);
        
        rep1test2 = dprime2(:,1);
        rep2test2 = dprime2(:,2);
        rep3test2 = dprime2(:,3);
        rep4test2 = dprime2(:,4);
        rep5test2 = dprime2(:,5);
        rep6test2 = dprime2(:,6);
    
        nSubjs = numel(subjIDs);
        
        finD1 = [rep1test1; rep2test1; rep3test1; rep4test1; rep5test1; rep6test1];
        finD2 = [rep1test2; rep2test2; rep3test2; rep4test2; rep5test2; rep6test2];
    else
        rep1 = dprime(:,1);
        rep2 = dprime(:,2);
        rep3 = dprime(:,3);
        rep4 = dprime(:,4);
        rep5 = dprime(:,5);
        rep6 = dprime(:,6);

        nSubjs = numel(subjIDs);

        finD = [rep1; rep2; rep3; rep4; rep5; rep6];
    end

    subjIDs_long = repmat(subjIDs, 6, 1);
    
    reps = [
        repmat(1, nSubjs, 1);  
        repmat(2, nSubjs, 1);  
        repmat(3, nSubjs, 1);  
        repmat(4, nSubjs, 1);
        repmat(5, nSubjs, 1);  
        repmat(6, nSubjs, 1);
    ];
    
    if experiment == 4 || experiment == 6
        finalMatrix = [subjIDs_long, reps, finD1, finD2];
    else
        finalMatrix = [subjIDs_long, reps, finD];
    end
    
    if experiment == 4
        save(fullfile('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/tcc', 'imperil4_TCC_subjectwise_dprime_all_reps.mat'), "finalMatrix")
    elseif experiment == 6
        save(fullfile('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/TCC', 'imperil6_TCC_reps_only_dprime.mat'), "finalMatrix")
    else
        outDest = sprintf('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/TCC/param_out', experiment);
        if ~exist(outDest, "dir")
            mkdir(outDest);
        end

        save(fullfile(outDest, ...
            sprintf('imperil%d_TCC_reps_only_dprime.mat', experiment)), "finalMatrix")
    end
    
    % shut down parallel processing pool
    delete(gcp('nocreate'))

    toc
end