%% A data wrangling script to conduct a swap model analysis (Bays et al., 2009)
% Coded by A.Y. - 28.04.2026
% Revised - swap model fit

% Experiment handle. Currently only works with Exp. 3
exp = 3;

mode = 1; % 1: Rep 1 % 5 only, split into conds; 2: All reps, collapsed across conds.

% Data file DIR template
filename = sprintf('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/mixture_modelling/combinedData_thirdpass%d.mat', exp, exp);
load(filename)

% Sample characteristics
outlierSbjs = setdiff(1:max(unique(thirdpass(:,1))), unique(thirdpass(:,1)), "stable");

% Participant IDs
subIDs = 1:max(unique(thirdpass(:,1)));
nSubs  = numel(subIDs);

% Pre-allocated results matrix
allResults = cell(nSubs, 1);

% Prep to parallel-process for speed
if isempty(gcp('nocreate')); parpool(7); end

% Value indices
subCol     = 1;
repCol     = 3;
contextCol = 10;
interfCol  = 11;
errCol = 13;
nonTargetErrCol = 14;

% To avoid empty / degenerate cells.
% NOTE: raised from 1 - a 3-parameter mixture (g, B, sd) cannot be
% estimated meaningfully from a handful of trials. Set to a defensible
% floor for your per-cell trial counts.
minTrials  = 10;

if mode == 1

    tic

    % Iterate over each participant
    parfor subj = 1:nSubs
    
    % Get current subject's ID
        subID = subIDs(subj);
    
    % skip subjects that don't appear in the data
    if ismember(subID, outlierSbjs)
    continue;
    end
    
    % Promote singular-matrix warnings to errors so a degenerate fit
    % aborts immediately instead of looping and printing forever.
        warning('error', 'MATLAB:nearlySingularMatrix');
        warning('error', 'MATLAB:singularMatrix');
        warning('error', 'MATLAB:illConditionedMatrix');
    
        subResults = table();
        localRow = 1;
    
    % loop over conditions
    for rep = [1 5]
    for context = 0:1
    for interference = 0:1
    
    % Locate relevant trials & fetch error values
                        mask = thirdpass(:, subCol)     == subID ...
                             & thirdpass(:, repCol)     == rep ...
                             & thirdpass(:, contextCol) == context ...
                             & thirdpass(:, interfCol)  == interference;
    
                        angError = thirdpass(mask, errCol);
                        nonTargetError = thirdpass(mask, nonTargetErrCol);
    
    if numel(angError) < minTrials
    continue;
    end
    
    % Build the data struct SwapModel expects:
    %   .errors      - 1 x nTrials, response error relative to the target
    %   .distractors - (nItems-1) x nTrials, response error relative to
    %                  each non-target. Here there is one non-target, so 1 x nTrials.
    % Columns must line up trial-for-trial with .errors.
                        data = struct();
                        data.errors      = angError(:)';
                        data.distractors = nonTargetError(:)';
    
    try
    % Fit the actual swap model. Parameter order is [g, B, sd]:
    %   g  - guess rate
    %   B  - swap (misbinding) rate, in [0,1]  <-- the quantity of interest
    %   sd - precision
                        fit = MemFit(data, SwapModel(), 'Verbosity', 0);
    
                        subResults.subject(localRow,1)      = subID;
                        subResults.repetition(localRow,1)   = rep;
                        subResults.context(localRow,1)      = context;
                        subResults.interference(localRow,1) = interference;
                        subResults.g(localRow,1)            = fit.maxPosterior(1);
                        subResults.swap(localRow,1)         = fit.maxPosterior(2);
                        subResults.SD(localRow,1)           = fit.maxPosterior(3);
                        subResults.nTrials(localRow,1)      = numel(angError);
                        localRow = localRow + 1;
    
    % If the model fit fails, inform and move on
    catch ME
                            fprintf('skip subj %d rep %d ctx %d intf %d: %s\n', ...
                                subID, rep, context, interference, ME.identifier);
    continue
    end
    end
    end
    end
    
    % Store the model params and continue with the next subject
        allResults{subj} = subResults;
        fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);
    end
    
    results = vertcat(allResults{:});
    results.subject      = categorical(results.subject);
    results.repetition   = categorical(results.repetition);
    results.context      = categorical(results.context);
    results.interference = categorical(results.interference);
    
    save_dest = sprintf("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/swap_model/param_out", exp);
    writetable(results, fullfile(save_dest, sprintf('exp_%d_swap_full_model.csv', exp)));
    
    toc
    
    % Shut down the parallel processing pool
    delete(gcp("nocreate"))

elseif mode == 2

    tic

    % Iterate over each participant
    parfor subj = 1:nSubs

        % Get current subject's ID
        subID = subIDs(subj);

        % skip subjects that don't appear in the data
        if ismember(subID, outlierSbjs)
            continue;
        end

        % Promote singular-matrix warnings to errors so a degenerate fit
        % aborts immediately instead of looping and printing forever.
        warning('error', 'MATLAB:nearlySingularMatrix');
        warning('error', 'MATLAB:singularMatrix');
        warning('error', 'MATLAB:illConditionedMatrix');

        subResults = table();
        localRow = 1;

        % loop over conditions
        for rep = 1:6

                    % Locate relevant trials & fetch error values
                    mask = thirdpass(:, subCol)     == subID ...
                        & thirdpass(:, repCol)     == rep;

                    angError = thirdpass(mask, errCol);
                    nonTargetError = thirdpass(mask, nonTargetErrCol);

                    if numel(angError) < minTrials
                        continue;
                    end

                    % Build the data struct SwapModel expects:
                    %   .errors      - 1 x nTrials, response error relative to the target
                    %   .distractors - (nItems-1) x nTrials, response error relative to
                    %                  each non-target. Here there is one non-target, so 1 x nTrials.
                    % Columns must line up trial-for-trial with .errors.
                    data = struct();
                    data.errors      = angError(:)';
                    data.distractors = nonTargetError(:)';

                    try
                        % Fit the actual swap model. Parameter order is [g, B, sd]:
                        %   g  - guess rate
                        %   B  - swap (misbinding) rate, in [0,1]  <-- the quantity of interest
                        %   sd - precision
                        fit = MemFit(data, SwapModel(), 'Verbosity', 0);

                        subResults.subject(localRow,1)      = subID;
                        subResults.repetition(localRow,1)   = rep;
                        subResults.g(localRow,1)            = fit.maxPosterior(1);
                        subResults.swap(localRow,1)         = fit.maxPosterior(2);
                        subResults.SD(localRow,1)           = fit.maxPosterior(3);
                        subResults.nTrials(localRow,1)      = numel(angError);
                        localRow = localRow + 1;

                        % If the model fit fails, inform and move on
                    catch ME
                        fprintf('skip subj %d rep %d: %s\n', ...
                            subID, rep, ME.identifier);
                        continue
                    end
        end

        % Store the model params and continue with the next subject
        allResults{subj} = subResults;
        fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);
    end

    results = vertcat(allResults{:});
    results.subject      = categorical(results.subject);
    results.repetition   = categorical(results.repetition);

    save_dest = sprintf("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/swap_model/param_out", exp);
    writetable(results, fullfile(save_dest, sprintf('exp_%d_swap_reps_only.csv', exp)));

    toc

    % Shut down the parallel processing pool
    delete(gcp("nocreate"))
end