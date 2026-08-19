addpath(genpath('/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/delta_mouse_data'));
addpath(genpath('/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_delta_output'));

mouseDataDest = '/Users/ali/Desktop/imperil6_delta_mouse_data';
trajFiles = dir(mouseDataDest);
trajFiles = trajFiles(~ismember({trajFiles.name}, {'.', '..', '.DS_Store'}));
nSbj = size(trajFiles, 1);

behDataDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_delta_output';
outDest = '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta';

% Parameters
centerX = 1920/2;
centerY = 1080/2;
nSamplesTarget = 60; % To standardize the size of mouse trajectory paths
nTrials = 900;
nSubjects = nSbj;
nProbe = 3;
nCond = 4;
nExpTrial = nTrials/6*2;
nTrialNovelProbe = 30;
nTrialRepeatedProbe = 45;
missingSbj = 17;
angError = NaN(nTrials, nSubjects);
mouseFinal = NaN(nSamplesTarget, nTrials, nProbe, nSubjects);
condFinal = NaN(nSamplesTarget, nTrials, nProbe, nSubjects);
% sampleLen = [];

%% Analyses
% Select experimental condition
analysisItem = 2; % 1 = novel item, 2 = repeated items (combined)

% Compute area under the curve?
auc = true;

for sbj = 1:nSubjects

    % Skip over missing subjects
    if ismember(sbj,missingSbj)
        continue;
    end

    % Build the filename dynamically
    curSbjFile = sprintf('imperil6DeltaDataMouseID%d.mat', sbj);
    curSbjBehFile = sprintf('imperil6DeltaDataID%d.mat', sbj);

    % Load current participant data
    fileToLoad = fullfile(mouseDataDest, curSbjFile);
    fileToLoadBeh = fullfile(behDataDest, curSbjBehFile);
    load(fileToLoad);  
    load(fileToLoadBeh);  

    % Fetch the performance metrics
    % Absolute angular error
    angError(:, sbj) = outputMatrix(:,15);

        % Scan through each trial
        for curTrial = 1:nTrials

            curTraj = trackingData{curTrial};
    
            % Extract time info and x-y coords in each sample
            time = curTraj(:, 1);
            x    = curTraj(:, 2);
            y    = curTraj(:, 3);
            validIdx = isfinite(time) & isfinite(x) & isfinite(y);
            
            % Remove samples with missing values
            time = time(validIdx);
            x    = x(validIdx);
            y    = y(validIdx);
            
            % Distance from the center (in x-y coordinates)
            dx = x - centerX;
            dy = y - centerY;

            % Distance from the center (in radians)
            radius = sqrt(dx.^2 + dy.^2);
            
            % Remove samples within too small of a radius
            validRadius = radius > 50;
            
            % Store values
            time = time(validRadius);
            x    = x(validRadius);
            y    = y(validRadius);
            dx   = dx(validRadius);
            dy   = dy(validRadius);

            % Mouse angle in screen/mouse space
            mouseAngleRaw = atan2d(dy, dx);  % Signed distance (-180:180)
            mouseAngle     = mod(mouseAngleRaw, 360); % Circular distance (0:360)

            % Correct for sudden jumps in trajectory caused by wrapping
            % around 360 degs.
            mouseAngle_unwrapped = rad2deg(unwrap(deg2rad(mouseAngleRaw)));
            
            % Get random increments applied to the color wheel at each test
            % Also, the memory color indices, so that we can compute
            % angular difference. 

            % Find which memory image was probed
            % 1 = LTM1, 2 = LTM2, 3 = Novel
            curProbe = outputMatrix(curTrial,13);

            if curProbe == 1
                wheelOffset = outputMatrix(curTrial, 21);
                targetColor = outputMatrix(curTrial, 9);
            elseif curProbe == 2
                wheelOffset = outputMatrix(curTrial, 21);
                targetColor = outputMatrix(curTrial, 10);
            elseif curProbe == 3
                wheelOffset = outputMatrix(curTrial, 21);
                targetColor = outputMatrix(curTrial, 12);
            end
            
            %% We now transition from physical space to color space. 
            % Now the angle is no longer physical location on the screen (in
            % units of angles), but the position along the color spectrum. 
            mouseColor = mod(mouseAngle + wheelOffset, 360);

            % Angular disparity (error)
            % Target colors are already in color space.
            instAngDisp = mod(mouseColor - targetColor + 180, 360) - 180;

            instAngDisp_unwrapped = rad2deg(unwrap(deg2rad(instAngDisp)));
            
            %% Interpolation
            % Each mouse trajectory contains varying number of samples
            % To make the trajectories comparable, we need to infer missing
            % samples in short trajs, and cut down the longer ones. 

            nSamplesTrue = linspace(0, 1, length(instAngDisp_unwrapped));
            % sampleLen = [sampleLen;size(nSamplesTrue,2)];
            nSamplesFiltered = linspace(0, 1, nSamplesTarget);

            % Exclude trials with too few samples
            shortTraj = length(nSamplesTrue) <= 25;

            % Apply linear interpolation
            if ~shortTraj
                mouseAngleInt = interp1(nSamplesTrue, instAngDisp_unwrapped, nSamplesFiltered, "linear");
            else
                continue;
            end

            % %% Normalized distance
            % % Required to average mouse trajectory across trials
            % 
            % normAngle = (mouseAngle - mean(mouseAngle))./std(mouseAngle, 0);

            %% Store everything
            % Mouse data
            mouseFinal(:, curTrial, curProbe, sbj) = mouseAngleInt;
            % Condition triggers
            condFinal(:, curTrial, curProbe, sbj) = outputMatrix(curTrial,23);
        end
end

mask2 = mouseFinal(:,:,2,:);
mask2Cond = condFinal(:,:,2,:);
mask3 = mouseFinal(:,:,3,:);
mask3Cond = condFinal(:,:,3,:);
mask2(isnan(mask2)) = mask3(isnan(mask2));
mask2Cond(isnan(mask2Cond)) = mask3Cond(isnan(mask2Cond));

mouseFinal(:,:,2,:) = mask2;
condFinal(:,:,2,:)= mask2Cond;
mouseFinal(:,:,3,:) = [];
condFinal(:,:,3,:) = [];


%% Make mouse trajectory memory-relevant
% mouseFinal is already target-relative, but unwrap may push values outside [-180, 180].
% So wrap it back before computing absolute error.

mouseFinal_wrapped = mod(mouseFinal + 180, 360) - 180;

% Index of distance from the target color value. 
mouseAbsTraj = abs(mouseFinal_wrapped);

% Filter down to critical repetitions
firstReps = 1:6:nTrials;
fifthReps = 5:6:nTrials;
expTrials = sort([firstReps, fifthReps]);

mouseAbsFiltered = mouseAbsTraj(:, expTrials, :, :);
condFinalFiltered = condFinal(:, expTrials, :, :);

if analysisItem == 1
    mouseAbsItem = mouseAbsFiltered(:, :, 2, :);  
elseif analysisItem == 2
    mouseAbsItem = mouseAbsFiltered(:, :, 1, :); 
end

% squeeze down to: 100 x nExpTrial x nSubjects
mouseAbsItem = squeeze(mouseAbsItem);

%% Partition data into conditions
meanCond1 = nan(nSamplesTarget, nSubjects);
meanCond2 = nan(nSamplesTarget, nSubjects);
meanCond3 = nan(nSamplesTarget, nSubjects);
meanCond4 = nan(nSamplesTarget, nSubjects);

% Pre-allocate allCond arrays with correct sizes
if analysisItem == 1  % Novel
    allCond1 = nan(nSamplesTarget, nTrialNovelProbe, nSubjects);
    allCond2 = nan(nSamplesTarget, nTrialNovelProbe, nSubjects);
    allCond3 = nan(nSamplesTarget, nTrialNovelProbe, nSubjects);
    allCond4 = nan(nSamplesTarget, nTrialNovelProbe, nSubjects);
elseif analysisItem == 2  % Repeated
    allCond1 = nan(nSamplesTarget, nTrialRepeatedProbe, nSubjects);
    allCond2 = nan(nSamplesTarget, nTrialRepeatedProbe, nSubjects);
    allCond3 = nan(nSamplesTarget, nTrialRepeatedProbe, nSubjects);
    allCond4 = nan(nSamplesTarget, nTrialRepeatedProbe, nSubjects);
end

allIdxCond = nan(nCond, nExpTrial, nSubjects);

% Map analysisItem to the correct probe index for condition triggers
if analysisItem == 1
    condProbeIdx = 2;  % Novel probe (was 3, now merged into slot 2)
elseif analysisItem == 2
    condProbeIdx = 1;  % Repeated probe
end

for sbj = 1:nSubjects

    idxCond1 = squeeze(condFinalFiltered(1,:,condProbeIdx,sbj)) == 1;
    idxCond2 = squeeze(condFinalFiltered(1,:,condProbeIdx,sbj)) == 2;
    idxCond3 = squeeze(condFinalFiltered(1,:,condProbeIdx,sbj)) == 3;
    idxCond4 = squeeze(condFinalFiltered(1,:,condProbeIdx,sbj)) == 4;
    
    meanCond1(:,sbj) = mean(mouseAbsItem(:, idxCond1, sbj), 2, 'omitnan');
    meanCond2(:,sbj) = mean(mouseAbsItem(:, idxCond2, sbj), 2, 'omitnan');
    meanCond3(:,sbj) = mean(mouseAbsItem(:, idxCond3, sbj), 2, 'omitnan');
    meanCond4(:,sbj) = mean(mouseAbsItem(:, idxCond4, sbj), 2, 'omitnan');

    curCond1 = mouseAbsItem(:, idxCond1, sbj);
    curCond2 = mouseAbsItem(:, idxCond2, sbj);
    curCond3 = mouseAbsItem(:, idxCond3, sbj);
    curCond4 = mouseAbsItem(:, idxCond4, sbj);

    allCond1(:, 1:size(curCond1,2), sbj) = curCond1;
    allCond2(:, 1:size(curCond2,2), sbj) = curCond2;
    allCond3(:, 1:size(curCond3,2), sbj) = curCond3;
    allCond4(:, 1:size(curCond4,2), sbj) = curCond4;
end

% Grand-average across subjects
grandMeanCond1 = mean(meanCond1, 2, 'omitnan');
grandMeanCond2 = mean(meanCond2, 2, 'omitnan');
grandMeanCond3 = mean(meanCond3, 2, 'omitnan');
grandMeanCond4 = mean(meanCond4, 2, 'omitnan');

%% Plot
time = linspace(0, 1, nSamplesTarget);

figure;
plot(time, grandMeanCond1, 'LineWidth', 2)
hold on
plot(time, grandMeanCond2, 'LineWidth', 2)
plot(time, grandMeanCond3, 'LineWidth', 2)
plot(time, grandMeanCond4, 'LineWidth', 2)

xlabel('Trial Span (in tracking samples)')
ylabel('Momentary Distance From the Target Color (°)')
legend({
    'Rep 1 x No Change', ...
    'Rep 1 x Change', ...
    'Rep 5 x No Change', ...
    'Rep 5 x Change'
    }, 'Location', 'best')

if analysisItem == 1
    title('Novel Item: Target-centered mouse trajectory')
elseif analysisItem == 2
    title('Repeated Items: Target-centered mouse trajectory')
end

box off

%% Area under the curve
% Data saved in a long format for an LMM in RStudio

time = linspace(0, 1, nSamplesTarget);
aucOutput = [];

for s = 1:nSubjects
    for tr = 1:length(expTrials)

        % Current trajectory: samples x 1
        curTraj = mouseAbsItem(:, tr, s);  % already probe-combined/selected

        % Current condition trigger
        curCond = condFinalFiltered(1, tr, condProbeIdx, s);  % use condProbeIdx, not analysisItem

        % Skip unusable trials
        if all(isnan(curTraj)) || isnan(curCond)
            continue
        end

        % Compute AUC
        curAUC = trapz(time, curTraj);

        % Decode condition
        if curCond == 1
            curRep = 1; curContext = 0; % No Change
        elseif curCond == 2
            curRep = 1; curContext = 1; % Change
        elseif curCond == 3
            curRep = 5; curContext = 0; % No Change
        elseif curCond == 4
            curRep = 5; curContext = 1; % Change
        else
            continue
        end

        aucOutput(end+1, :) = [s, expTrials(tr), analysisItem, curCond, curRep, curContext, curAUC];
    end
end

%% Save as .mat file

if analysisItem == 1
    outName = sprintf('mouse_auc_novel.mat');
    save(fullfile(outDest, outName), 'aucOutput');
elseif analysisItem == 2
    outName = sprintf('mouse_auc_repeated.mat');
    save(fullfile(outDest, outName), 'aucOutput');
end

%% Save data for cluster-based sample analysis
if analysisItem == 1
    for condition = 1:4
        outname = sprintf("allSamplesNovelCond" + condition);
        save(fullfile(outDest,outname), "allCond" + condition)
    end
elseif analysisItem == 2
    for condition = 1:4
        outname = sprintf("allSamplesRepeatCond" + condition);
        save(fullfile(outDest,outname), "allCond" + condition)
    end
end
