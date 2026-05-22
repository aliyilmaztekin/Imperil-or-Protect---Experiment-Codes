%% Set kappa
kappa = 0.03; % fixed decay rate
kappaNoise = 0.03;
rng(1);  % makes simulation reproducible

%% Load and accumulate angular errors
dataDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4';
angle1 = [];
angle1idx = [];
angle1resp = [];

for sbj = 13:101

    % Build the filename dynamically
    curSbj = sprintf('imperil4dataID%d.mat', sbj);
    
    % Build the full path
    fileToLoad = fullfile(dataDest, curSbj);
    
    % Load it
    load(fileToLoad);  % loads outputMatrix

    % Select trials and angular errors
    curAngle1 = outputMatrix((outputMatrix(:,19) == 3), 10);
    % angle1true = outputMatrix((outputMatrix(:,31) == 4), 12);
    % respAngle1 = outputMatrix((outputMatrix(:,31) == 4), 20);

    % Accumulate
    angle1 = [angle1; curAngle1];
    % angle1idx = [angle1idx; angle1true];
    % angle1resp = [angle1resp; respAngle1];
end

%% Wrap angular errors to [-180, 180]
angle1_wrapped = mod(angle1 + 180, 360) - 180;

% Remove NaNs
angle1_wrapped = angle1_wrapped(~isnan(angle1_wrapped));

% SD of wrapped angular errors
sd_angle1 = std(angle1_wrapped, 'omitnan');
fprintf('SD of angular errors = %.4f\n', sd_angle1);

%% Plot frequency distribution
edges = -180:1:180;
[counts, edges] = histcounts(angle1_wrapped, edges);

binCenters = edges(1:end-1) + diff(edges)/2;

figure;
plot(binCenters, counts, 'LineWidth', 1.5)

xlabel('Angular error')
ylabel('Frequency')
title('Frequency distribution of angular errors')

%% Plot smooth observed density
errorAxis = -180:180;

% Adjust bandwidth input to how jagged you'd tolerate the figure to be. 10
% makes it pretty smooth.
[xDensity, xValues] = ksdensity(angle1_wrapped, errorAxis, 'Bandwidth', 10);

figure;
plot(xValues, xDensity, 'LineWidth', 2)

xlabel('Angular error')
ylabel('Density')
title('Smoothed density of angular errors')

%% Create and plot psychophysical similarity function
% Similarity magnitudes 
simMag = psychoSim(kappa);

figure;
plot(errorAxis, simMag, 'LineWidth', 2)

xlabel('Angular error')
ylabel('Psychological similarity')
title('Psychophysical similarity function')

%% Plot observed density and scaled psychosim together 
% For easier visualization, scale similarity magnitudes to the height of ...
% the actual data.  
simMag2scale = simMag .* max(xDensity) ./ max(simMag);

% Overlay the figures on top of each other
figure;
plot(xValues, xDensity, 'LineWidth', 2)
hold on
plot(errorAxis, simMag2scale, 'LineWidth', 2)

xlabel('Angular error')
ylabel('Density')
title('Observed density and scaled psychophysical similarity')
legend({'Observed density', 'Scaled psychosim'})

%% Create memory signal from psychosim
dprime = 1; % temporary placeholder

simMag = psychoSim(kappa);

memSignal = dprime .* simMag; % d(x) = d'*simMag (Schurgin et al., 2020)

figure;
plot(errorAxis, memSignal, 'LineWidth', 2)

xlabel('Angular error')
ylabel('Memory signal')
title('Memory signal = dprime × psychophysical similarity')

%% Add noise to the memory signals
% one last ingredient that goes into memory match signals 
% is correlated noise. each memory signal has to contain ..
% a degree of noise. the most straightforward way would be ...
% to draw random numbers from a normal distribution. but ...
% feature values close to each other should also have ...
% correlated noise. 

%% Add correlated noise and simulate TCC responses

errorAxis = -180:180;
nChannels = numel(errorAxis);

% Build correlated noise covariance matrix
Sigma = zeros(nChannels, nChannels);

for i = 1:nChannels
    for j = 1:nChannels

        dist = abs(errorAxis(i) - errorAxis(j));
        dist = min(dist, 360 - dist);

        Sigma(i,j) = exp(-kappaNoise .* dist);

    end
end

% Numerical stability for mvnrnd
Sigma = (Sigma + Sigma') ./ 2;
Sigma = Sigma + eye(nChannels) * 1e-6;

% Simulate many TCC trials
nSim = 50000;
predictedErrors = nan(nSim, 1);

for s = 1:nSim

    % Draw noisy memory match strengths
    noisySignal = mvnrnd(memSignal, Sigma);

    % Winner-take-all response
    [~, winnerIdx] = max(noisySignal);

    % Store predicted angular error
    predictedErrors(s) = errorAxis(winnerIdx);

end

% Convert simulated responses into predicted probabilities
predEdges = -180.5:1:180.5;
predCounts = histcounts(predictedErrors, predEdges);
predProb = predCounts ./ sum(predCounts);

% Plot predicted TCC distribution
figure;
plot(errorAxis, predProb, 'LineWidth', 2)
xlabel('Angular error')
ylabel('Predicted probability')
title('TCC predicted response distribution')

predProb_scaled = predProb .* max(xDensity) ./ max(predProb);

figure;
plot(xValues, xDensity, 'LineWidth', 2)
hold on
plot(errorAxis, predProb_scaled, 'LineWidth', 2)

xlabel('Angular error')
ylabel('Density')
title('Observed density and simulated TCC prediction')
legend({'Observed density', 'Simulated TCC'})

%% Convert memory signal into response probabilities
% 
% memSignal_shifted = memSignal - max(memSignal);
% responseProb = exp(memSignal_shifted) ./ sum(exp(memSignal_shifted));
% 
% figure;
% plot(errorAxis, responseProb, 'LineWidth', 2)
% 
% xlabel('Angular error')
% ylabel('Predicted response probability')
% title('Predicted response probability from memory signal')
% 
% 
% %% Estimate dprime using maximum likelihood
% 
% % We estimate only dprime while keeping kappa fixed.
% % logDprime is used so dprime is always positive.
% 
% startDprime = 1;
% startLogDprime = log(startDprime);
% 
% bestLogDprime = fminsearch(@(logDprime) negLogLik_dprimeOnly(logDprime, angle1_wrapped, kappa), ...
%                            startLogDprime);
% 
% dprime_hat = exp(bestLogDprime);
% 
% fprintf('Estimated dprime = %.4f\n', dprime_hat);
% 
% 
% %% Plot fitted dprime model
% 
% simMag = psychoSim(kappa);
% 
% fittedMemSignal = dprime_hat .* simMag;
% 
% fittedMemSignal_shifted = fittedMemSignal - max(fittedMemSignal);
% fittedResponseProb = exp(fittedMemSignal_shifted) ./ sum(exp(fittedMemSignal_shifted));
% 
% % Scale fitted probability to observed density peak for visual comparison
% fittedResponseProb_scaled = fittedResponseProb .* max(xDensity) ./ max(fittedResponseProb);
% 
% figure;
% plot(xValues, xDensity, 'LineWidth', 2)
% hold on
% plot(errorAxis, fittedResponseProb_scaled, 'LineWidth', 2)
% 
% xlabel('Angular error')
% ylabel('Density')
% title('Observed density and fitted dprime-only model')
% legend({'Observed density', 'Fitted model'})


%% Psychophysical similarity function
function simMag = psychoSim(kappa)

    errorAxis = -180:180;
 
    % A memory signal centered at the target feature value spreads out at
    % an exponential decay over other values. (Schurgin et al., 2020)

    % Kappa is the decay multiplier. Best to find it with a maximum
    % likelihood estimation. 
    simMag = exp(-kappa .* abs(errorAxis));
end

%% Negative log likelihood function for dprime-only model

function nll = negLogLik_dprimeOnly(logDprime, angleErrors, kappa)

    % Convert from log scale to real positive dprime
    dprime = exp(logDprime);

    % Possible angular errors
    errorAxis = -180:180;

    % Psychophysical similarity
    simMag = exp(-kappa .* abs(errorAxis));

    % Memory signal
    memSignal = dprime .* simMag;

    % Convert memory signal into response probabilities
    % stable softmax
    memSignal_shifted = memSignal - max(memSignal);
    responseProb = exp(memSignal_shifted) ./ sum(exp(memSignal_shifted));

    % Round observed errors to nearest integer degree
    roundedErrors = round(angleErrors);

    % Keep errors within [-180, 180]
    roundedErrors = max(min(roundedErrors, 180), -180);

    % Convert errors to indices
    % -180 -> 1
    % 0    -> 181
    % 180  -> 361
    errorIdx = roundedErrors + 181;

    % Probability assigned to each observed error
    pObs = responseProb(errorIdx);

    % Avoid log(0)
    pObs = max(pObs, realmin);

    % Negative log likelihood
    nll = -sum(log(pObs));

end

function nll = negLogLik_TCC(logDprime, angleErrors, kappa, Sigma, nSim)

dprime = exp(logDprime);

errorAxis = -180:180;
simMag = exp(-kappa .* abs(errorAxis));
memSignal = dprime .* simMag;

predictedErrors = nan(nSim, 1);

for s = 1:nSim
    noisySignal = mvnrnd(memSignal, Sigma);
    [~, winnerIdx] = max(noisySignal);
    predictedErrors(s) = errorAxis(winnerIdx);
end

edges = -180.5:1:180.5;
predCounts = histcounts(predictedErrors, edges);

% Add small smoothing so no bin has probability 0
predProb = predCounts + 1;
predProb = predProb ./ sum(predProb);

roundedErrors = round(angleErrors);
roundedErrors = max(min(roundedErrors, 180), -180);

errorIdx = roundedErrors + 181;

pObs = predProb(errorIdx);
pObs = max(pObs, realmin);

nll = -sum(log(pObs));

end


%% Parallel grid search for TCC dprime

% Candidate dprime values
dprimeGrid = 1.9:0.01:2.3;
nD = numel(dprimeGrid);

nllVals = nan(size(dprimeGrid));

% Number of simulations per dprime
nSimFit = 500000;

% Make sure Sigma is symmetric/stable
Sigma = (Sigma + Sigma') ./ 2;
Sigma = Sigma + eye(size(Sigma)) * 1e-6;

% Precompute correlated noise ONCE
% This gives an nSimFit × nChannels matrix
fprintf('Generating correlated noise samples...\n');
correlatedNoise = mvnrnd(zeros(1, nChannels), Sigma, nSimFit);

% Precompute observed error indices
roundedErrors = round(angle1_wrapped);
roundedErrors = max(min(roundedErrors, 180), -180);
errorIdx = roundedErrors + 181;

% Open parallel pool with limited workers
nWorkers = 4;

pool = gcp('nocreate');

if isempty(pool)
    parpool('local', nWorkers);
elseif pool.NumWorkers ~= nWorkers
    delete(pool);
    parpool('local', nWorkers);
end

fprintf('Starting parallel grid search with %d workers...\n', nWorkers);


parfor d = 1:nD

    curDprime = dprimeGrid(d);

    % Mean memory signal for this dprime
    simMag = exp(-kappa .* abs(errorAxis));
    memSignal = curDprime .* simMag;

    % Add same correlated noise samples to this dprime's memory signal
    noisySignals = correlatedNoise + memSignal;

    % Winner-take-all response for each simulated trial
    [~, winnerIdx] = max(noisySignals, [], 2);

    % Convert winning indices to predicted angular errors
    predictedErrors = errorAxis(winnerIdx);

    % Convert simulated responses to probability distribution
    predEdges = -180.5:1:180.5;
    predCounts = histcounts(predictedErrors, predEdges);

    % Add small smoothing to avoid zero probabilities
    predProb = predCounts + 1;
    predProb = predProb ./ sum(predProb);

    % Probability assigned to observed errors
    pObs = predProb(errorIdx);

    % Avoid log(0)
    pObs = max(pObs, realmin);

    % Negative log likelihood
    nllVals(d) = -sum(log(pObs));

end

% Find best dprime
[bestNLL, bestIdx] = min(nllVals);
dprime_hat_TCC = dprimeGrid(bestIdx);

fprintf('Best TCC dprime = %.4f\n', dprime_hat_TCC);
fprintf('Best NLL = %.4f\n', bestNLL);



%% Plot fitted TCC prediction using best dprime

% Use the fitted dprime
bestDprime = dprime_hat_TCC;

% Recompute similarity and memory signal for best dprime
simMag_best = exp(-kappa .* abs(errorAxis));
memSignal_best = bestDprime .* simMag_best;

% Use the same precomputed correlated noise samples
noisySignals_best = correlatedNoise + memSignal_best;

% Winner-take-all response
[~, winnerIdx_best] = max(noisySignals_best, [], 2);

% Convert winner indices to predicted angular errors
predictedErrors_best = errorAxis(winnerIdx_best);

% Convert simulated fitted responses to probability distribution
predEdges = -180.5:1:180.5;
predCounts_best = histcounts(predictedErrors_best, predEdges);

% Add smoothing, same as in fitting
predProb_best = predCounts_best + 1;
predProb_best = predProb_best ./ sum(predProb_best);

% Observed histogram as probability, not density
obsCounts = histcounts(angle1_wrapped, predEdges);
obsProb = obsCounts ./ sum(obsCounts);

% Plot observed probability and fitted TCC probability
figure;
plot(errorAxis, obsProb, 'LineWidth', 2)
hold on
plot(errorAxis, predProb_best, 'LineWidth', 2)

xlabel('Angular error')
ylabel('Probability')
title(sprintf('Observed errors and fitted TCC prediction, dprime = %.2f', bestDprime))
legend({'Observed data', 'Fitted TCC'})

%% Put MemToolbox and TCC files on path

addpath(genpath('/path/to/MemToolbox'));
addpath('/path/to/TCCCodeFolder');  % folder containing TCCCorrelated.m and TCCCorrelated_Precomputed.mat

%% Prepare errors

% Example: use your already-computed angular errors
errors = angle1_wrapped;

% Remove NaNs
errors = errors(~isnan(errors));

% Make sure errors are wrapped to [-180, 180]
errors = mod(errors + 180, 360) - 180;

%% Format data for MemToolbox

data.errors = errors;

%% Fit TCC model

model = TCCCorrelated();

fit = MemFit(data, model);



% dataDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data';
% 
% nSbj = 16;
% combineData = [];
% 
% for sbj = 1:nSbj
%     % Build the filename dynamically
%     curSbj = sprintf('imperil6dataID%d.mat', sbj);
% 
%     % Build the full path
%     fileToLoad = fullfile(dataDest, curSbj);
% 
%     % Load it
%     load(fileToLoad);  % This will load whatever variables are inside
% 
%     combineData = [combineData;outputMatrix];
% end
% 
% 
% for testedItem = 1:3
% 
%     cellMat = cell(3, 4, nSbj);
% 
%     for sbj = 1:nSbj
% 
%         curMat = combineData(combineData(:,1) == sbj, :);
% 
%         for cond = 1:4
% 
%             trialIdx = curMat(:,31) == cond & curMat(:,13) == testedItem;
% 
%             adjResp = curMat(trialIdx, 28);
% 
%             color1 = curMat(trialIdx, 9);
%             color2 = curMat(trialIdx, 10);
%             color3 = curMat(trialIdx, 11);
% 
%             angDisp1 = mod((adjResp - color1) + 180, 360) - 180;
%             angDisp2 = mod((adjResp - color2) + 180, 360) - 180;
%             angDisp3 = mod((adjResp - color3) + 180, 360) - 180;
% 
%             cellMat{1,cond,sbj} = angDisp1;
%             cellMat{2,cond,sbj} = angDisp2;
%             cellMat{3,cond,sbj} = angDisp3;
% 
%         end
%     end
% 
%     xGrid = -180:1:180;
% 
%     condToPlot = 3;
% 
%     item1Cells = squeeze(cellMat(1,condToPlot,:));
%     item2Cells = squeeze(cellMat(2,condToPlot,:));
%     item3Cells = squeeze(cellMat(3,condToPlot,:));
% 
%     item1Disp = vertcat(item1Cells{:});
%     item2Disp = vertcat(item2Cells{:});
%     item3Disp = vertcat(item3Cells{:});
% 
%     item1Disp = item1Disp(isfinite(item1Disp));
%     item2Disp = item2Disp(isfinite(item2Disp));
%     item3Disp = item3Disp(isfinite(item3Disp));
% 
%     item1_aug = [item1Disp - 360; item1Disp; item1Disp + 360];
%     item2_aug = [item2Disp - 360; item2Disp; item2Disp + 360];
%     item3_aug = [item3Disp - 360; item3Disp; item3Disp + 360];
% 
%     [xDensity1, xValues1] = ksdensity(item1_aug, xGrid);
%     [xDensity2, xValues2] = ksdensity(item2_aug, xGrid);
%     [xDensity3, xValues3] = ksdensity(item3_aug, xGrid);
% 
%     figure;
%     plot(xValues1, xDensity1, 'LineWidth', 2)
%     hold on
%     plot(xValues2, xDensity2, 'LineWidth', 2)
%     plot(xValues3, xDensity3, 'LineWidth', 2)
% 
%     xlabel('Response displacement relative to memory item')
%     ylabel('Density')
%     title(sprintf('Response distributions when item %d was tested', testedItem))
%     legend({'Compared to item 1', 'Compared to item 2', 'Compared to item 3'})
% 
% end
% 




