%% A data wrangling script to conduct a mixture model analysis (Zhang & Luck, 2008)
% Coded by A.Y. - 28.04.2026

% Participant IDs
subIDs = 13:101;
nSubs  = numel(subIDs);

% Storage table
results = table();

% Data file DIR template
filename = ['/Users/ali/Desktop/visual imperil project/imperil4materials/' ...
        'behavioral_data_exp4/imperil4dataID']; 

row = 1;
for subj = 1:nSubs

    subID = subIDs(subj);

    % skip outlier participant
    % (determined a priori and harcoded here)
    % (but the outlier criterion is average test 1 error collapsed across
    % condition => 45°). 

    if subID == 62
        continue;
    end

    % build filename
    fileName = [filename num2str(subID) '.mat'];

    % load data
    dataSet = load(fileName);

    table = dataSet.outputMatrix;

    % loop over factors
    for test = 1           % Memory test 1 (WM item) and 2 (LTM item)
        for rep = [1 5]      % Filter to critical repetitions only: 1 and 5
            for context = 0:1  % Look for context change commands: 0 and 1

                % select error column
                if test == 1
                    angDisp = 10; % Angular disparity values stored here
                    RT = 13; % Reaction time in test1
                else
                    angDisp = 14; % Same values for the LTM item
                    RT = 17; % Reaction time in test2
                end

                % Outlier rejection and trimming:

                % My only criteria are:

                % 1) Filter out these where RT is unreasonably fast (shorter
                % than 300 ms).

                % 2) Filter trials where error is exactly 0 (because my
                % analysis, Gamma GLMM, can't work with zeros).

                % 3) Filter out trials where error is NaN (test missed).

                filteredData = (table(:,5) == rep) & ...
                       (table(:,6) == context) & ...
                       isfinite(table(:,10)) & ...
                       (table(:,13) >= 0.3);

                % Extract errors from the clean output
                angError = table(filteredData, angDisp);

                % Apply modulo once, just for good measure. 
                % In all likelihood though, it is redundant. 
                angError = mod(angError + 180, 360) - 180;

                % Skip conditions where very few trials remain, as they may
                % break the analysis.
                if numel(angError) < 10
                    warning('Too few valid trials: sub %d, test %d, rep %d, ctx %d (n=%d)', ...
                        subID, test, rep, context, numel(angError));
                    continue
                end

                % Skip conditions where very variance is very little, as
                % they may also break the analysis.
                if std(angError) < 1e-6
                    warning('Near-zero variance: sub %d, test %d, rep %d, ctx %d', ...
                        subID, test, rep, context);
                    continue
                end

                % Fit mixture model over the dataset using MemFit toolbox. 
                try
                    fit = MemFit(angError, StandardMixtureModel(), 'Verbosity', 0);

                    % store results
                    results.subject(row,1)    = subID;
                    results.test(row,1)       = test;
                    results.repetition(row,1) = rep;
                    results.context(row,1)    = context;

                    results.g(row,1)  = fit.maxPosterior(1); % Guessing rate estimate
                    results.SD(row,1) = fit.maxPosterior(2); % SD/Precision estimate
                    results.nTrials(row,1) = numel(angError); % Trial count per condition

                    row = row + 1;

                catch ME
                    
                    % Some model fits may fail. In this case, continue
                    % fiting over the next person. 
                        disp(getReport(ME, 'extended'))
                    continue
                end
            end
        end
    end

    fprintf('Subject finished %d (%d/%d)\n', subID, subj, nSubs);

end

% convert to categorical-friendly format
if ~isempty(results)
    results.subject    = categorical(results.subject);
    results.test       = categorical(results.test);
    results.repetition = categorical(results.repetition);
    results.context    = categorical(results.context);
end

% save for R
writetable(results, 'mixture_parameters_rep1_rep5_test1_test2.csv');

