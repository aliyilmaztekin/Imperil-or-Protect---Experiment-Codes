%% A data wrangling script to conduct a mixture model analysis (Zhang & Luck, 2008)
% Coded by A.Y. - 28.04.2026

% Participant IDs
subIDs = 13:101;
nSubs  = numel(subIDs);

% Data file DIR template
filename = ['/Users/ali/Desktop/visual imperil project/imperil4materials/' ...
        'behavioral_data_exp4/imperil4dataID']; 

allResults = cell(nSubs, 1);

parpool(7)

% 1: Filter to rep 1 and 5; 2: All repetitions
analysis = 2;
 
if analysis == 1
    tic
    
    parfor subj = 1:nSubs
    
        subID = subIDs(subj);
    
        if subID == 62
            continue;
        end
    
        subResults = table();
    
        % load data
        fileName = [filename num2str(subID) '.mat'];
        dataSet = load(fileName);
        data = dataSet.outputMatrix;
    
        localRow = 1;
    
        for test = 1:2
            for rep = [1 5]
                for context = 0:1
    
                    if test == 1
                        angDisp = 10;
                        RT = 13;
                    else
                        angDisp = 14;
                        RT = 17;
                    end
    
                    filteredData = (data(:,5) == rep) & ...
                                   (data(:,6) == context) & ...
                                   isfinite(data(:,angDisp)) & ...
                                   (data(:,RT) >= 0.3);
    
                    angError = data(filteredData, angDisp);
                    angError = mod(angError + 180, 360) - 180;
    
                    try
                        fit = MemFit(angError, StandardMixtureModel(), 'Verbosity', 0);
    
                        subResults.subject(localRow,1)    = subID;
                        subResults.test(localRow,1)       = test;
                        subResults.repetition(localRow,1) = rep;
                        subResults.context(localRow,1)    = context;
                        subResults.g(localRow,1)          = fit.maxPosterior(1);
                        subResults.SD(localRow,1)         = fit.maxPosterior(2);
                        subResults.nTrials(localRow,1)    = numel(angError);
    
                        localRow = localRow + 1;
    
                    catch ME
                        disp(getReport(ME, 'extended'))
                        continue
                    end
                end
            end
        end
    
        allResults{subj} = subResults;
    
        fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);
    
    end
    
    % Trim out the outlier cell
    allResults(50) = [];

    results = vertcat(allResults{:});
    
    results.subject    = categorical(results.subject);
    results.test       = categorical(results.test);
    results.repetition = categorical(results.repetition);
    results.context    = categorical(results.context);
    
    save_dest = "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/mixture_modelling";

    writetable(results, fullfile(save_dest,'mixture_parameters_rep1_rep5.csv'));
    
    toc

    % Shut down the parallel processing pool
    delete(gcp("nocreate"))
end
    

if analysis == 2    
    % Participant IDs
    subIDs = 13:101;
    nSubs  = numel(subIDs);
    
    % Data file DIR template
    filename = ['/Users/ali/Desktop/visual imperil project/imperil4materials/' ...
            'behavioral_data_exp4/imperil4dataID'];
    
    % Repetition levels to analyze
    repLevels = 1:6;
    
    % Store one table per subject
    allResults = cell(nSubs, 1);
    
    % Start parallel pool if one is not already open
    if isempty(gcp('nocreate'))
        parpool(7)
    end

    tic

    parfor subj = 1:nSubs
    
        subID = subIDs(subj);
    
        % skip outlier participant
        if subID == 62
            continue;
        end
    
        subResults = table();
    
        % load data
        fileName = [filename num2str(subID) '.mat'];
        dataSet = load(fileName);
        data = dataSet.outputMatrix;
    
        localRow = 1;
    
        for test = 1:2
            for rep = repLevels
    
                if test == 1
                    angDisp = 10;
                    RT = 13;
                else
                    angDisp = 14;
                    RT = 17;
                end
    
                % Ignore context completely: only filter by repetition, valid error, and RT
                filteredData = (data(:,5) == rep) & ...
                               isfinite(data(:,angDisp)) & ...
                               (data(:,RT) >= 0.3);
    
                angError = data(filteredData, angDisp);
    
                % Keep signed errors in -180 to 180 range
                angError = mod(angError + 180, 360) - 180;
    
                if numel(angError) < 10
                    continue
                end
    
                if std(angError) < 1e-6
                    continue
                end
    
                try
                    fit = MemFit(angError, StandardMixtureModel(), 'Verbosity', 0);
    
                    subResults.subject(localRow,1)    = subID;
                    subResults.test(localRow,1)       = test;
                    subResults.repetition(localRow,1) = rep;
    
                    subResults.g(localRow,1)       = fit.maxPosterior(1);
                    subResults.SD(localRow,1)      = fit.maxPosterior(2);
                    subResults.nTrials(localRow,1) = numel(angError);
    
                    localRow = localRow + 1;
    
                catch ME
                    disp(getReport(ME, 'extended'))
                    continue
                end
            end
        end
    
        allResults{subj} = subResults;
    
        fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);
    
    end
    
    allResults(50) = [];
    results = vertcat(allResults{:});
    
    results.subject    = categorical(results.subject);
    results.test       = categorical(results.test);
    results.repetition = categorical(results.repetition);

    save_dest = "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/mixture_modelling";
    
    writetable(results, fullfile(save_dest, 'mixture_parameters_all_repetitions.csv'));
    
    toc

    % Shut down the parallel processing pool
    delete(gcp("nocreate"))
end