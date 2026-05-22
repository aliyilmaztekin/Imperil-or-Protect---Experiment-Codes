%% A data wrangling script to conduct a swap model analysis (Bays et al., 2009)
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
    for test = 1:2
    
        if test == 1
            angDisp = 10;
            RT = 13;
    
            targetCol = 9;
            nonTargetCol = 8;
    
        else
            angDisp = 14;
            RT = 17;
    
            targetCol = 8;
            nonTargetCol = 9;
        end
    
        responseAngle = mod((table(:,targetCol) - table(:,angDisp)) + 180, 360) - 180;
    
        nonTargetDisp = mod((table(:,nonTargetCol) - responseAngle) + 180, 360) - 180;
    
        for rep = [1 5]
            for context = 0:1
    
                filteredData = (table(:,5) == rep) & ...
                               (table(:,6) == context) & ...
                               isfinite(table(:,angDisp)) & ...
                               isfinite(nonTargetDisp) & ...
                               (table(:,RT) >= 0.3) & ...
                               (table(:,angDisp) ~= 0);
    
                angError = table(filteredData, angDisp);
                angErrorNonTarget = nonTargetDisp(filteredData);
    
                angError = mod(angError + 180, 360) - 180;
                angErrorNonTarget = mod(angErrorNonTarget + 180, 360) - 180;
    
                if numel(angError) < 10
                    warning('Too few valid trials: sub %d, test %d, rep %d, ctx %d (n=%d)', ...
                        subID, test, rep, context, numel(angError));
                    continue
                end
    
                if std(angError) < 1e-6
                    warning('Near-zero variance: sub %d, test %d, rep %d, ctx %d', ...
                        subID, test, rep, context);
                    continue
                end
    
                try
                    data = struct();
                    data.errors = angError(:)';
                    data.distractors = angErrorNonTarget(:)';
                
                    fit = MemFit(data, SwapModel(), 'Verbosity', 0);
                
                    results.subject(row,1)    = subID;
                    results.test(row,1)       = test;
                    results.repetition(row,1) = rep;
                    results.context(row,1)    = context;
                
                    results.g(row,1)    = fit.maxPosterior(1);
                    results.swap(row,1) = fit.maxPosterior(2);
                    results.SD(row,1)   = fit.maxPosterior(3);
                
                    results.nTrials(row,1) = numel(angError);
                
                    row = row + 1;
                
                catch ME
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
writetable(results, 'swap_parameters_rep1_rep5_test1_test2.csv');

