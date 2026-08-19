% participant IDs
subIDs = 13:100;
nSubs  = numel(subIDs);

% storage table
results = table();
row = 1;

% VP model
vpModel = VariablePrecisionModel('HigherOrderDist', 'GammaPrecision');

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
    S = load(fileName);

    if ~isfield(S, 'outputMatrix')
        warning('outputMatrix missing for subject %d', subID);
        continue
    end

    M = S.outputMatrix;

    % test 1 only
    errCol = 10;
    rtCol  = 13;

    for rep = [1 5]
        for context = 0:1

            % valid trials
            cond = (M(:,5) == rep) & ...
                   (M(:,6) == context) & ...
                   isfinite(M(:,errCol)) & ...
                   isfinite(M(:,rtCol)) & ...
                   (M(:,rtCol) >= 0.3);

            err = M(cond, errCol);
            err = err(isfinite(err));

            % wrap errors to [-180, 180)
            err = mod(err + 180, 360) - 180;

            % skip sparse cells
            if numel(err) < 10
                warning('Too few valid trials: sub %d, rep %d, ctx %d (n=%d)', ...
                    subID, rep, context, numel(err));
                continue
            end

            % skip degenerate cells
            if std(err) < 1e-6
                warning('Near-zero variance: sub %d, rep %d, ctx %d', ...
                    subID, rep, context);
                continue
            end

            try
                fit = MemFit(err, vpModel, 'Verbosity', 0);

                results.subject(row,1)    = subID;
                results.test(row,1)       = 1;
                results.repetition(row,1) = rep;
                results.context(row,1)    = context;
                results.nTrials(row,1)    = numel(err);

                results.g(row,1)             = fit.maxPosterior(1);
                results.modePrecision(row,1) = fit.maxPosterior(2);
                results.sdPrecision(row,1)   = fit.maxPosterior(3);

                results.g_lo(row,1)             = fit.lowerCredible(1);
                results.modePrecision_lo(row,1) = fit.lowerCredible(2);
                results.sdPrecision_lo(row,1)   = fit.lowerCredible(3);

                results.g_hi(row,1)             = fit.upperCredible(1);
                results.modePrecision_hi(row,1) = fit.upperCredible(2);
                results.sdPrecision_hi(row,1)   = fit.upperCredible(3);

                row = row + 1;

            catch ME
                warning('VP fit failed: sub %d, rep %d, ctx %d | %s', ...
                    subID, rep, context, ME.message);
                continue
            end
        end
    end

    fprintf('Finished subject %d (%d/%d)\n', subID, i, nSubs);
end

% categorical-friendly format
if ~isempty(results)
    results.subject    = categorical(results.subject);
    results.test       = categorical(results.test);
    results.repetition = categorical(results.repetition);
    results.context    = categorical(results.context);
end

% save for R
writetable(results, 'vp_parameters_test1_only.csv');

disp('Done. VP CSV ready for R.');