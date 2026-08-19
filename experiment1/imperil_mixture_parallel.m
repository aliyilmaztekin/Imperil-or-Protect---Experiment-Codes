%% A data wrangling script to conduct a mixture model analysis (Zhang & Luck, 2008)
% Coded by A.Y. - 28.04.2026

% Experiment handle
exp = 3;
% Analysis handle
mode = 2; % 1 = only the 1st and 5th reps; 2 = all reps, 1st and 5th reps collapsed across conds

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

if exp == 1
    errCol = 13; % col 5 is abs transformed error, 13 is raw error 
elseif exp == 2 || exp == 3
    errCol = 12;
end

minTrials  = 1;  

% mode 1: Filter to rep 1 and 5; mode 2: All repetitions
if mode == 1

    tic

    parfor subj = 1:nSubs
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

        for rep = [1 5]
            for context = 0:1
                for interference = 0:1
                    
                    % Locate relevant trials & fetch error values
                    mask = thirdpass(:, subCol)     == subID ...
                         & thirdpass(:, repCol)     == rep ...
                         & thirdpass(:, contextCol) == context ...
                         & thirdpass(:, interfCol)  == interference;
                    angError = thirdpass(mask, errCol);

                    if numel(angError) < minTrials
                        continue;
                    end

                    % Fit SMM over data
                    try
                        fit = MemFit(angError, StandardMixtureModel(), 'Verbosity', 0);
                        subResults.subject(localRow,1)      = subID;
                        subResults.repetition(localRow,1)   = rep;
                        subResults.context(localRow,1)      = context;
                        subResults.interference(localRow,1) = interference;
                        subResults.g(localRow,1)            = fit.maxPosterior(1);
                        subResults.SD(localRow,1)           = fit.maxPosterior(2);
                        subResults.nTrials(localRow,1)      = numel(angError);
                        localRow = localRow + 1;
                    catch ME
                        fprintf('skip subj %d rep %d ctx %d intf %d: %s\n', ...
                                subID, rep, context, interference, ME.identifier);
                        continue
                    end
                end
            end
        end

        allResults{subj} = subResults;
        fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);
    end

    results = vertcat(allResults{:});
    results.subject      = categorical(results.subject);
    results.repetition   = categorical(results.repetition);
    results.context      = categorical(results.context);
    results.interference = categorical(results.interference);

    save_dest = sprintf("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/mixture_modelling/param_out", exp);
    writetable(results, fullfile(save_dest, sprintf('exp_%d_mixture_parameters_rep1_rep5.csv', exp)));
    toc

    % Shut down the parallel processing pool
    delete(gcp("nocreate"))
end
    

if mode == 2    
   
    % Repetition levels to analyze
    repLevels = 1:6;
    
    % Store one table per subject
    allResults = cell(nSubs, 1);
    
    tic

     parfor subj = 1:nSubs
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
    
            for rep = repLevels
    
              % Locate relevant trials & fetch error values
                    mask = thirdpass(:, subCol)     == subID ...
                         & thirdpass(:, repCol)     == rep ...
 

                    angError = thirdpass(mask, errCol);

                    if numel(angError) < minTrials
                        continue;
                    end
    
                try
                    fit = MemFit(angError, StandardMixtureModel(), 'Verbosity', 0);
    
                    subResults.subject(localRow,1)    = subID;
                    subResults.repetition(localRow,1) = rep;
                    subResults.g(localRow,1)       = fit.maxPosterior(1);
                    subResults.SD(localRow,1)      = fit.maxPosterior(2);
                    subResults.nTrials(localRow,1) = numel(angError);
    
                    localRow = localRow + 1;
    
                catch ME
                    fprintf('skip subj %d rep %d ctx %d intf %d: %s\n', ...
                                subID, rep, ME.identifier);
                    continue
                end
            end
        
    
        allResults{subj} = subResults;
    
        fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);
    
    end
    
    results = vertcat(allResults{:});
    
    results.subject    = categorical(results.subject);
    results.repetition = categorical(results.repetition);

    save_dest = sprintf("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/mixture_modelling/param_out", exp);
    writetable(results, fullfile(save_dest, sprintf('exp_%d_mixture_parameters_all_reps.csv', exp)));
    toc

    % Shut down the parallel processing pool
    delete(gcp("nocreate"))
end