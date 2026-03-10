

% =========================================================
% Mixture-model parameter extraction for R (long format)
% =========================================================

% participant IDs
subIDs = 13:62;
nSubs  = numel(subIDs);

% storage table (long format)
results = table();

row = 1;

for i = 1:nSubs

    subID = subIDs(i);

    % build filename
    fileName = ['/Users/ali/Desktop/visual imperil project/imperil4materials/' ...
        'behavioral_data_exp4/imperil4dataID' num2str(subID) '.mat'];

    if ~isfile(fileName)
        warning('File missing for subject %d', subID);
        continue
    end

    % load data
    dataSet = load(fileName);
    M = dataSet.outputMatrix;

    % loop over factors
    for test = 1:2           % test 1 / test 2
        for rep = [1 5]      % repetition 1 / 5
            for context = 0:1  % no change / change

                % select error column
                if test == 1
                    errCol = 10;
                else
                    errCol = 14;
                end

                % define condition
                cond = (M(:,5) == rep) & (M(:,6) == context);
                err  = M(cond, errCol);

                % sanity check
                if numel(err) < 10
                    warning('Too few trials: sub %d, test %d, rep %d, ctx %d', ...
                        subID, test, rep, context);
                    continue
                end

                % fit mixture model (no prompts)
                fit = MemFit(err, StandardMixtureModel(), 'Verbosity', 0);

                % store results
                results.subject(row)    = subID;
                results.test(row)       = test;
                results.repetition(row) = rep;
                results.context(row)    = context;

                results.g(row)  = fit.maxPosterior(1);
                results.SD(row) = fit.maxPosterior(2);

                row = row + 1;

            end
        end
    end

    fprintf('Finished subject %d (%d/%d)\n', subID, i, nSubs);

end

% convert to categorical-friendly format
results.subject    = categorical(results.subject);
results.test       = categorical(results.test);
results.repetition = categorical(results.repetition);
results.context    = categorical(results.context);

% save for R
writetable(results, ...
    'mixture_parameters_rep1_rep5_test1_test2.csv');

disp('Done. CSV ready for R.');
