% participant IDs
subIDs = 13:97;
nSubs  = numel(subIDs);

% storage table (long format)
results = table();

row = 1;

for i = 1:nSubs

    subID = subIDs(i);

    % skip outlier participant
    if subID == 62
        continue;
    end

    % build filename
    fileName = ['/Users/ali/Desktop/visual imperil project/imperil4materials/' ...
        'behavioral_data_exp4/imperil4dataID' num2str(subID) '.mat'];

    if ~isfile(fileName)
        warning('File missing for subject %d', subID);
        continue
    end

    % load data
    dataSet = load(fileName);

    if ~isfield(dataSet, 'outputMatrix')
        warning('outputMatrix missing for subject %d', subID);
        continue
    end

    M = dataSet.outputMatrix;

    % loop over factors
    for test = 1           % test 1 / test 2
        for rep = [1 5]      % repetition 1 / 5
            for context = 0:1  % no change / change

                % select error column
                if test == 1
                    errCol = 10;
                else
                    errCol = 14;
                end

                % define condition + RT filter
                cond = (M(:,5) == rep) & ...
                       (M(:,6) == context) & ...
                       isfinite(M(:,10)) & ...
                       (M(:,13) >= 0.3);

                % extract errors
                err = M(cond, errCol);

                % remove NaN / Inf errors
                err = err(isfinite(err));

                % wrap to circular error range
                err = mod(err + 180, 360) - 180;

                % skip tiny cells
                if numel(err) < 10
                    warning('Too few valid trials: sub %d, test %d, rep %d, ctx %d (n=%d)', ...
                        subID, test, rep, context, numel(err));
                    continue
                end

                % skip near-zero variance cells
                if std(err) < 1e-6
                    warning('Near-zero variance: sub %d, test %d, rep %d, ctx %d', ...
                        subID, test, rep, context);
                    continue
                end

                % fit mixture model safely
                try
                    fit = MemFit(err, StandardMixtureModel(), 'Verbosity', 0);

                    % store results
                    results.subject(row,1)    = subID;
                    results.test(row,1)       = test;
                    results.repetition(row,1) = rep;
                    results.context(row,1)    = context;

                    results.g(row,1)  = fit.maxPosterior(1);
                    results.SD(row,1) = fit.maxPosterior(2);
                    results.nTrials(row,1) = numel(err);

                    row = row + 1;

                catch ME
                    warning('Fit failed: sub %d, test %d, rep %d, ctx %d | %s', ...
                        subID, test, rep, context, ME.message);
                    continue
                end

            end
        end
    end

    fprintf('Finished subject %d (%d/%d)\n', subID, i, nSubs);

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

disp('Done. CSV ready for R.');