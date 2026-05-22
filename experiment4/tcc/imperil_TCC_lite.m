%% TCC Model Analysis
% Relevant directories
dataDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4';...
    % to access the behavioral data
addpath(genpath('/Users/ali/Desktop/visual imperil project/imperil4materials/tcc_model_analysis/TCC_Code_InManuscriptOrder/Model'));...
    % to access MemToolbox to estimate dprime
addpath('/Users/ali/Desktop/visual imperil project/imperil4materials/tcc_model_analysis/TCC_Code_InManuscriptOrder/Tools/MemToolbox');...
    % to access the psychosimilarity and correlated noise data: TCCCorrelated.m and TCCCorrelated_Precomputed.mat')
addpath('/Users/ali/Desktop/visual imperil project/imperil4materials/tcc_model_analysis/TCC_Code_InManuscriptOrder')

subjList = setdiff(13:101, 62);
nSubjs = numel(subjList);

conds = [1 2 3 4];
nCond = length(conds);

dprime1 = NaN(nSubjs, nCond);
dprime2 = NaN(nSubjs, nCond);

subjIDs = NaN(nSubjs, 1);

% Load model once
model = TCCCorrelated();

for subjRow = 1:nSubjs

    sbj = subjList(subjRow);
    subjIDs(subjRow) = sbj;

    % Build filename
    curSbj = sprintf('imperil4dataID%d.mat', sbj);
    fileToLoad = fullfile(dataDest, curSbj);

    % Load file
    load(fileToLoad);  % loads outputMatrix

    for curCondIdx = 1:nCond

        curCond = conds(curCondIdx);

        % Select errors for current condition
        curAngle1 = outputMatrix(outputMatrix(:,19) == curCond, 10);
        curAngle2 = outputMatrix(outputMatrix(:,19) == curCond, 14);

        % Wrap errors
        errors1 = mod(curAngle1 + 180, 360) - 180;
        errors2 = mod(curAngle2 + 180, 360) - 180;

        % Remove NaNs
        errors1 = errors1(~isnan(errors1));
        errors2 = errors2(~isnan(errors2));

        % Skip if too few trials
        if numel(errors1) < 5 || numel(errors2) < 5
            warning('Subject %d, condition %d has too few trials.', sbj, curCond);
            continue;
        end

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

    end

    fprintf('Finished subject %d (%d/%d)\n', sbj, subjRow, nSubjs);

end

cond1test1 = dprime1(:,1);
cond2test1 = dprime1(:,2);
cond3test1 = dprime1(:,3);
cond4test1 = dprime1(:,4);

cond1test2 = dprime2(:,1);
cond2test2 = dprime2(:,2);
cond3test2 = dprime2(:,3);
cond4test2 = dprime2(:,4);

nSubjs = numel(subjIDs);

finD1 = [cond1test1; cond2test1; cond3test1; cond4test1];
finD2 = [cond1test2; cond2test2; cond3test2; cond4test2];

subjIDs_long = repmat(subjIDs, 4, 1);

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

save('imperil4_TCC_subjectwise_dprime.mat', "finalMatrix")