%% Imperil or Protect 7 - Condition Matrix Generator
% Coded by A.Y.

% Conception: 21.04.2026
% v1 - 23.04.2026: Design alpha
% v2 - 25.04.2026: Design beta. Change of design: Mem load 3 -> 2

nTrials = 660; % Can be 480, 600, 720 or 900

%% Relevant DIRs
% Get the folder where this script is located
experimentRoot = fileparts(mfilename('fullpath'));
cd(experimentRoot);

% Add all subfolders to MATLAB path
addpath(genpath(experimentRoot));

imageLocation = '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6';

stimuliDIR = fullfile(imageLocation, 'TestObjectsTransparentExp6');
trainingStimuliDIR = fullfile(imageLocation, 'trainingStimuliExp6');

% Total number of repetition series to generate based on desired trial
% count. 720 total -> 120 series, nSeriesMain trials -> nSeriesMain series
% But always add 10 to the nSeriesMain. The extra 10 rep series is for the training.

%% ===================== BASIC COUNTS =====================

if nTrials == 720
    nSeriesMain = nTrials / 6;  
    nTrialsPCond = nTrials/6/2;
elseif nTrials == 660
    nSeriesMain = nTrials / 6; 
     nTrialsPCond = nTrials/6/2;
elseif nTrials == 480
    nSeriesMain = nTrials / 6; 
     nTrialsPCond = nTrials/6/2;
elseif nTrials == 900
    nSeriesMain = nTrials / 6;
    nTrialsPCond = nTrials/6/2;
else
    error('Unexpected nTrials value. nTrials must be 480, 600, 720 or 900');
end

nTrialsTrain = 60;
nSeriesTrain = nTrialsTrain / 6;

nTrialsTotal = nTrials + nTrialsTrain;
nSeriesTotal = nSeriesMain + nSeriesTrain;

nTrainingImages = 14;

rng('shuffle');

for condFile = 1:1

    %% ===================== REPETITION SEQUENCE =====================

    seriesSequence = (1:6)'; 
    longSequence = repmat(seriesSequence, nSeriesTotal, 1); 
  
    conditionMatrix = NaN(nTrialsTotal, 10); 
    conditionMatrix(:,1) = longSequence;

    %% ===================== CONTEXT CHANGE VALUES =====================

    nRep1 = sum(longSequence == 1);
    nRep5 = sum(longSequence == 5);

    rep1conds = [repmat(0, nRep1/2, 1); repmat(1, nRep1/2, 1)];
    rep5conds = [repmat(0, nRep5/2, 1); repmat(1, nRep5/2, 1)];

    rep1random = rep1conds(randperm(nRep1));
    rep5random = rep5conds(randperm(nRep5));

    rep1idx = find(longSequence == 1);
    rep5idx = find(longSequence == 5);

    conditionMatrix(rep1idx, 2) = rep1random;
    conditionMatrix(rep5idx, 2) = rep5random;

    % JavaScript doesn't like NaNs. So, switch them out for 9s.
    conditionMatrix(isnan(conditionMatrix(:,2)), 2) = 9;
    
    %% Colour-hue generation
%
% Criterion 1: the nColorsPerSeries hues within a streak are pairwise at
%              least colorOffset apart (circular distance on the hue wheel).
% Criterion 2: the first two hues of a streak are at least colorOffset from
%              BOTH the first and the last hue of the preceding streak
%              (4 distances per boundary).
%
% Unlike the original, criterion 2 is enforced at *every* streak boundary,
% not only within pairs of columns. If you deliberately want the constraint
% to reset every second column, set chainAllStreaks = false below.

rng('shuffle');

%% Parameters
hueRange             = 360;                 % full circle; hues live in 1..360
colorOffset          = 45;                  % minimum separation, in degrees
nCoupleColors        = 1;
nMainColorsPerSeries = 6;
nColorsPerSeries     = nCoupleColors + nMainColorsPerSeries;   % 7
nStreaks             = nSeriesTotal;
maxAttempts          = 1000;
chainAllStreaks      = true;

% Wrap into 1..hueRange. NOTE: the original used mod(x-1,359)+1, which makes
% the wheel 359 wide and leaves a 44-degree gap across the wrap point.
wrapHue  = @(x) mod(x - 1, hueRange) + 1;

% Circular distance: the shorter way round the wheel. Replaces the
% "a:b" colon ranges, which silently produce [] whenever a > b after wrapping.
circDist = @(a,b) min(mod(a - b, hueRange), mod(b - a, hueRange));

% Evenly spaced candidate hues, exactly colorOffset apart.
nLattice = floor(hueRange / colorOffset);            % 8 for offset 45
lattice  = @(s) wrapHue(s + colorOffset * (0:nLattice-1));

assert(nColorsPerSeries <= nLattice, ...
    'Cannot fit %d hues at >= %d deg apart on a %d deg wheel (max %d).', ...
    nColorsPerSeries, colorOffset, hueRange, nLattice);

allHues   = 1:hueRange;
colorsMat = NaN(nColorsPerSeries, nStreaks);         % correct preallocation

%% Generation
prevFirst = [];
prevLast  = [];

for k = 1:nStreaks

    if isempty(prevFirst)
        % ---- Unconstrained streak: first one, or a reset boundary --------
        startDeg = randi(hueRange);
        pool     = lattice(startDeg);
        pool     = pool(2:end);                      % everything but startDeg
        pool     = pool(randperm(numel(pool)));
        % Truncating the shuffled pool IS the "spare" removal, and it can
        % never remove one of the two anchor hues.
        streak   = [startDeg, pool(1:nColorsPerSeries-1)];

    else
        % ---- Constrained streak: honour criterion 2 ----------------------
        okStart = allHues(circDist(allHues, prevFirst) >= colorOffset & ...
                          circDist(allHues, prevLast)  >= colorOffset);
        assert(~isempty(okStart), 'No legal start hue at streak %d.', k);

        found = false;
        for attempt = 1:maxAttempts
            startDeg = okStart(randi(numel(okStart)));

            pool = lattice(startDeg);
            pool = pool(2:end);                      % excludes startDeg

            % Candidates for the SECOND hue, which must also clear both
            % anchors of the previous streak.
            freeDegs = pool(circDist(pool, prevFirst) >= colorOffset & ...
                            circDist(pool, prevLast)  >= colorOffset);
            if isempty(freeDegs)
                continue                             % try another start hue
            end

            pairDeg  = freeDegs(randi(numel(freeDegs)));
            remDegs  = setdiff(pool, pairDeg, 'stable');
            remDegs  = remDegs(randperm(numel(remDegs)));

            streak = [startDeg, pairDeg, remDegs(1:nColorsPerSeries-2)];
            found  = true;
            break
        end
        assert(found, 'Failed to build streak %d in %d attempts.', k, maxAttempts);
    end

    colorsMat(:,k) = streak(:);

    if chainAllStreaks || mod(k,2) == 1
        prevFirst = streak(1);
        prevLast  = streak(end);
    else
        prevFirst = [];                              % reset every second column
        prevLast  = [];
    end
end

%% Verification
assert(~any(isnan(colorsMat(:))), 'Unfilled entries in colorsMat.');

% Criterion 1
for k = 1:nStreaks
    c = colorsMat(:,k);
    assert(numel(unique(c)) == nColorsPerSeries, ...
        'Duplicate hue in streak %d.', k);
    D = circDist(c, c.');
    D(1:nColorsPerSeries+1:end) = Inf;               % ignore the diagonal
    assert(all(D(:) >= colorOffset), ...
        'Criterion 1 violated in streak %d (min %g).', k, min(D(:)));
end

% Criterion 2
for k = 2:nStreaks
    if ~chainAllStreaks && mod(k,2) == 1
        continue
    end
    p = colorsMat([1 end], k-1);                     % first & last of previous
    n = colorsMat([1 2],   k);                       % first two of current
    d = circDist(repmat(n(:),2,1), reshape(repmat(p(:).',2,1),[],1));
    assert(all(d >= colorOffset), ...
        'Criterion 2 violated at boundary %d-%d (min %g).', k-1, k, min(d));
end

fprintf('OK: %d streaks x %d hues, both criteria satisfied.\n', ...
    nStreaks, nColorsPerSeries);

    % Extract the first 6 colors in each column, designate them as main
    % experiment color hues, and flatten back into a column-vector for
    % image assignment below
    colorsMatMain = reshape(colorsMat((nCoupleColors + 1):end, :), nTrialsTotal, 1);


  %% ===================== MAIN IMAGE ASSIGNMENT =====================

stimuliFiles = dir(fullfile(stimuliDIR, '*.png'));
stimuliPaths = fullfile({stimuliFiles.folder}, {stimuliFiles.name});

nStimuli = numel(stimuliPaths);

nMem1PerSeries = 1;     % Decreased from 2 repeated items
nTrialsPerSeries = 6;   % 6-trial streak/miniblock

nSelectMain = nSeriesMain * nMem1PerSeries;

%% Repeated item image name population

% Randomly select images for the main phase of the experiment
mem1ImageFiles = randperm(nStimuli, nSelectMain);
mem1ImagePaths = stimuliPaths(mem1ImageFiles);

% Randomize order before assigning to streaks.
mem1ImagePaths = mem1ImagePaths(randperm(numel(mem1ImagePaths)));

% Repeat each image name for six times. 
combinedMem1ImagePaths = repelem( ...
    reshape(mem1ImagePaths, nSeriesMain, nMem1PerSeries), ...
    nTrialsPerSeries, ...
    1 ...
);


%% Novel item image name population

% Images NOT used as repeated items.
remainingImageFiles = setdiff(1:nStimuli, mem1ImageFiles);
nRemaining = numel(remainingImageFiles);

% First burn through the images that were not used as couple images.
firstPassFiles = remainingImageFiles(randperm(nRemaining));

% Then recycle/reset the entire 450-image pool as many times as needed.
nStillNeeded = nTrials - numel(firstPassFiles);

recycledFiles = [];

while numel(recycledFiles) < nStillNeeded
    recycledFiles = [recycledFiles, randperm(nStimuli)];
end

recycledFiles = recycledFiles(1:nStillNeeded);

% Final novel image pool has exactly one image per trial.
mem2ImageFiles = [firstPassFiles, recycledFiles];
combinedMem2ImagePaths = stimuliPaths(mem2ImageFiles);
combinedMem2ImagePaths = combinedMem2ImagePaths(:);

%% Novel image repeat order shuffling
% Because each trial needs a new novel image, some of them will reoccur
% throughout the experiment. We want them to be placed sufficiently apart
% from one another. 

minGap = 60;
minColorGap = colorOffset;

maxRestarts = 5000;
triesPerImage = 2000;

% Copy the flattened colors matrix
colorsMatMainOnly = colorsMatMain(1:nTrials);

% imgID returns an index vector in which the different occurrences of the
% same element is represented by the same value. counts is the number of
% occurrences for each image. 
[uniqueImgs, ~, imgID] = unique(combinedMem2ImagePaths, 'stable');
counts = accumarray(imgID, 1);

%% Image placement 
% Creates imageMatrix after distributing images into trials with some
% constraints accounted for.
success = false;

for restart = 1:maxRestarts

    newOrder = cell(nTrials, 1);
    emptyPos = 1:nTrials;
    failed = false;

    % Place the most frequent images first because they are hardest to fit.
    [~, sortIdx] = sort(counts, 'descend');
    imageOrder = sortIdx(randperm(numel(sortIdx)));

    for ii = 1:numel(imageOrder)

        imgIdx = imageOrder(ii);
        curImg = uniqueImgs(imgIdx);
        nRep = counts(imgIdx);
        pos = [];

        % Find all repeated/couple positions for this same image.
        % This will be empty for images that were not selected as couple images.
        mem1PositionsForCurImg = find( ...
            strcmp(combinedMem1ImagePaths(:,1), curImg));

        for attempt = 1:triesPerImage

            if numel(emptyPos) < nRep
                break;
            end

            candidate = sort(emptyPos(randperm(numel(emptyPos), nRep)));

            %% Check 1: All occurrences of the same image has to be 
            %% at least minGap trials apart in space.

            if nRep > 1
                positionGapOK = all(diff(candidate) >= minGap);
            else
                positionGapOK = true;
            end

            if ~positionGapOK
                continue;
            end

            %% Check 2: All the occurrences of the same image has to be
            %% sufficiently different in color. 

            % Refer to colors matrix generated earlier. 
            if nRep > 1
                thisColors = colorsMatMainOnly(candidate);

                D = abs(thisColors - thisColors');
                circD = min(D, 360 - D);

                % The diagonal of this color-difference matrix will always
                % be 0, because those are differences of the same color hue
                % subtracted from itself. And because they're 0, they'll
                % always violate the minColorGap check one line below. So,
                % change 0s with Inf. 
                circD(logical(eye(size(circD)))) = Inf;
                colorGapOK = all(circD(:) >= minColorGap);

            else
                colorGapOK = true;
            end

            if ~colorGapOK
                continue;
            end

            %% Check 3: The novel images should not overlap with 
            %% the repeating image in the same streak. 

            miniblockOK = true;

            for cc = 1:numel(candidate)

                curTrial = candidate(cc);

                % Find the 6-trial miniblock containing this trial.
                curSeries = ceil(curTrial / nTrialsPerSeries);

                blockStart = (curSeries - 1) * nTrialsPerSeries + 1;
                blockEnd   = curSeries * nTrialsPerSeries;

                % The two repeated/couple images in this miniblock.
                blockMem1Imgs = combinedMem1ImagePaths(blockStart:blockEnd, :);

                % unique() gives the 2 couple images for this miniblock.
                blockMem1Imgs = unique(blockMem1Imgs(:), 'stable');

                % Current third image must not be one of those 2 couple images.
                if any(strcmp(curImg, blockMem1Imgs))
                    miniblockOK = false;
                    break;
                end
            end

            if ~miniblockOK
                continue;
            end

            %% ---------- Constraint 4: third image must be far from its own couple block ----------

            % This only applies if the current third image was also one of the
            % couple images somewhere in the experiment.
            if ~isempty(mem1PositionsForCurImg)
                mem1Mem2Distances = abs(candidate(:) - mem1PositionsForCurImg(:)');
                mem1Mem2GapOK = all(mem1Mem2Distances(:) >= minGap);
            else
                mem1Mem2GapOK = true;
            end

            if ~mem1Mem2GapOK
                continue;
            end

            %% ---------- If all constraints passed, accept candidate positions ----------

            pos = candidate;
            break;
        end

        if isempty(pos)
            failed = true;
            break;
        end

        newOrder(pos) = repmat(curImg, numel(pos), 1);
        emptyPos = setdiff(emptyPos, pos);
    end

    if failed
        continue;
    end

    combinedMem2ImagePaths = newOrder(:);

    success = true;
    fprintf('Valid MAIN image + color + miniblock + mem1/mem2 spacing solution found at restart %d\n', restart);
    break;
end

if ~success
    error('Could not construct valid MAIN ordering with all constraints.');
end

%% ===================== BUILD FINAL IMAGE MATRIX =====================

imageMatrix = cell(nTrials, 2);

imageMatrix(:,1) = combinedMem1ImagePaths;
imageMatrix(:,2) = combinedMem2ImagePaths;

  %% ===================== TRAINING IMAGES =====================%% ===================== TRAINING IMAGE ASSIGNMENT =====================

trainingStimuliFiles = dir(fullfile(trainingStimuliDIR, '*.png'));
trainingStimuliPaths = fullfile({trainingStimuliFiles.folder}, {trainingStimuliFiles.name});

trainingImageCount = numel(trainingStimuliPaths);

nTrainingSeries = 2;

% With 28 images:
%   4 base series
%   7 images per base series
%       - 1 repeated mem1 images
%       - 6 mem2 images
%
% Then reuse these 4 base series to fill the requested training series.

nBaseTrainingSeries = 2;
nMem1PerTrainingSeries = 1;
nMem2PerTrainingSeries = 6;
nImagesPerTrainingSeries = nMem1PerTrainingSeries + nMem2PerTrainingSeries;

nTrainingBaseImagesNeeded = nBaseTrainingSeries * nImagesPerTrainingSeries;

% Select nTrainingImages images and shuffle their order.
trainingBasePool = trainingStimuliPaths(randperm(trainingImageCount, nTrainingImages));

% Reshape into 2 base training series, each with 7 images.
trainingBasePool = reshape(trainingBasePool, nBaseTrainingSeries, nImagesPerTrainingSeries);

% The first image of each base series is the repeated item.
baseMem1BySeries = trainingBasePool(:, 1:nMem1PerTrainingSeries);

% Last 6 images of each base series are novel items.
baseMem2BySeries = trainingBasePool(:, (nMem1PerTrainingSeries + 1):end);

% Decide which base series is used for each actual training series.
% This preserves 6-trial miniblock structure while allowing reuse.
baseSeriesOrder = repmat(1:nBaseTrainingSeries, 1, ceil(nTrainingSeries / nBaseTrainingSeries));
baseSeriesOrder = baseSeriesOrder(1:nTrainingSeries);
baseSeriesOrder = baseSeriesOrder(randperm(numel(baseSeriesOrder)));

% Columns:
%   1 = repeated item
%   2 = trial-specific novel item
trainingImageMatrix = cell(nTrialsTrain, 2);

for s = 1:nTrainingSeries

    blockStart = (s - 1) * 6 + 1;
    blockEnd   = s * 6;

    curBaseSeries = baseSeriesOrder(s);

    curMem1Imgs = baseMem1BySeries(curBaseSeries, :);
    curMem2Imgs = baseMem2BySeries(curBaseSeries, :);

    % Randomize the order of the six mem2 images within this training
    % miniblock each time the base series is reused.
    curMem2Imgs = curMem2Imgs(randperm(nMem2PerTrainingSeries));

    % Repeat the same repeated item across all 6 trials of this block.
    trainingImageMatrix(blockStart:blockEnd, 1) = repmat(curMem1Imgs, 6, 1);

    % One novel image per trial.
    trainingImageMatrix(blockStart:blockEnd, 2) = curMem2Imgs(:);
end

  %% Store the generated colors

conditionMatrix(:,3) = reshape(repmat(colorsMat(1,:), 6, 1), nTrialsTotal, 1);
conditionMatrix(:,4) = reshape(colorsMat((nCoupleColors + 1):end, :), nTrialsTotal, 1);


    %% Rotation increment for the encoding arrays

    rotations = zeros(nSeriesTotal, 1);
    spatialOffset = 45;
    rotations(1) = randi([1 359]);
    locationSpace = 1:359;
    for theta = 2:nSeriesTotal
        shadedRange = mod(rotations(theta-1)-spatialOffset : rotations(theta-1)+spatialOffset, 360);
        remSpace = setdiff(locationSpace, shadedRange, "stable");
        rotations(theta) = remSpace(randi(numel(remSpace)));
    end
    rotations = repelem(rotations, 6, 1);
    conditionMatrix(:,5) = 90;

    %% Split the training matrix from the main phase matrix

    trainingMatrix = conditionMatrix(end-59:end, :);
    conditionMatrix(end-59:end, :) = [];
    
    %% Re-balance experimental trials in the main phase
    %% After cutting off the training matrix, the context change values 
    %% are no longer evenly shared out among reps 1 & 5. 
    
    conditionMatrix(conditionMatrix(:,1) == 1, 2) = NaN;
    conditionMatrix(conditionMatrix(:,1) == 5, 2) = NaN;
    
    rep1idx = find(conditionMatrix(:,1) == 1);
    rep5idx = find(conditionMatrix(:,1) == 5);
    
    nRep1 = numel(rep1idx);
    nRep5 = numel(rep5idx);
    
    rep1conds = [zeros(nRep1/2, 1); ones(nRep1/2, 1)];
    rep5conds = [zeros(nRep5/2, 1); ones(nRep5/2, 1)];
    
    conditionMatrix(rep1idx, 2) = rep1conds(randperm(nRep1));
    conditionMatrix(rep5idx, 2) = rep5conds(randperm(nRep5));
    
    %% Training matrix context change assignment
    % Is hard-coded/scripted by choice. 
    
    trainingContext = [0 NaN NaN NaN 1 NaN 1 NaN NaN NaN 0 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN]';
    
    trainingMatrix(:,2) = trainingContext;
    trainingMatrix(isnan(trainingMatrix(:,2)), 2) = 9;

    %% TESTING INDEX ASSIGNMENT
    % Constrained randomized allocation:

    % The repeated and novel items should be probed with equal chance at reps 1 & 5.. 
    % 60 trials per condition:
    % 30 trials -> novel item tested
    % 30 trials -> repeated item tested

    mainTestOrder = NaN(nTrials,1);

    novelProb = 0.50;
    repeatedProb = 0.50;

    % Find the trial indices of experimental manipulations
    rep1ctx0 = find(conditionMatrix(:,2) == 0 & conditionMatrix(:,1) == 1);
    rep1ctx1 = find(conditionMatrix(:,2) == 1 & conditionMatrix(:,1) == 1);
    rep5ctx0 = find(conditionMatrix(:,2) == 0 & conditionMatrix(:,1) == 5);
    rep5ctx1 = find(conditionMatrix(:,2) == 1 & conditionMatrix(:,1) == 5);

    priority = randi(2,1);
    if priority == 1
        nTrialsPCondNovel = ceil(nTrialsPCond*novelProb);
        nTrialsPCondRep = floor(nTrialsPCond*repeatedProb);
    elseif priority == 2
        nTrialsPCondNovel = floor(nTrialsPCond*novelProb);
        nTrialsPCondRep = ceil(nTrialsPCond*repeatedProb);
    end

    repItemVals = repmat(1,1,nTrialsPCondRep);
    novelItemVals = repmat(2,1,nTrialsPCondNovel);

    perCond1 = [repItemVals';novelItemVals'];
    perCond2 = [repItemVals';novelItemVals'];
    perCond3 = [repItemVals';novelItemVals'];
    perCond4 = [repItemVals';novelItemVals'];

    % Distribute the generated indices across critical trials at random
    % order
    mainTestOrder(rep1ctx0) = perCond1(randperm(length(perCond1)));
    mainTestOrder(rep1ctx1) = perCond2(randperm(length(perCond2)));
    mainTestOrder(rep5ctx0) = perCond3(randperm(length(perCond3)));
    mainTestOrder(rep5ctx1) = perCond4(randperm(length(perCond4)));

    % Now, the non-critical repetitions (2,3,4 & 6)
    remTrials = nTrials - nTrialsPCond*4;
    remRep = repmat(1,1,remTrials*repeatedProb);
    remNovel = repmat(2,1,remTrials*novelProb);
    
    allRemTestIdx = [remNovel';remRep'];
    allRemTestIdx = allRemTestIdx(randperm(size(allRemTestIdx,1)));

    % Slot the values into places
    for testOrder = 1:nSeriesMain
  
        nonCriticalTrials = [2 3 4 6];

        if testOrder == 1

            curQuad = allRemTestIdx(end-3:end);
            mainTestOrder(nonCriticalTrials) = curQuad;

            allRemTestIdx(end-3:end) = [];

        elseif testOrder >= 2

            curQuad = allRemTestIdx(end-3:end);
   
            mainTestOrder((testOrder-1)*6+2:(testOrder-1)*6+4) = curQuad(1:3);
            mainTestOrder((testOrder-1)*6+6) = curQuad(4);
           
            allRemTestIdx(end-3:end) = [];
        end
    end

    conditionMatrix(:,6) = mainTestOrder;

    %% Testing Assignment for Training
    % Same rules. So simply sample randomly from the main matrix.

    randSliceIdx = randperm(nSeriesMain, nSeriesTrain);   % choose 10 series without replacement
    
    trialIdx = (randSliceIdx(:)-1)*6 + (1:6);   % 10 x 6 matrix of trial indices
    trialIdx = trialIdx(:);                     % convert to 60 x 1 vector
    
    randSlices = mainTestOrder(trialIdx);
    
    trainingMatrix(:,6) = randSlices;

    % %% ===================== FINAL SANITY CHECKS =====================
    % 
    % if size(conditionMatrix,1) ~= nTrials
    %     error('Main conditionMatrix has %d rows, expected %d.', ...
    %         size(conditionMatrix,1), nTrials);
    % end
    % 
    % if size(trainingMatrix,1) ~= nTrialsTrain
    %     error('trainingMatrix has %d rows, expected %d.', ...
    %         size(trainingMatrix,1), nTrialsTrain);
    % end
    % 
    % if size(imageMatrix,1) ~= nTrials
    %     error('Main imageMatrix has %d rows, expected %d.', ...
    %         size(imageMatrix,1), nTrials);
    % end
    % 
    % if size(trainingImageMatrix,1) ~= nTrialsTrain
    %     error('trainingImageMatrix has %d rows, expected %d.', ...
    %         size(trainingImageMatrix,1), nTrialsTrain);
    % end

    %% Rewrite image names 
    % Because JS is too much work with strings

    frontEnd = wildcardPattern + '/';
    imPrefix = "obj";
    imSuffix = "-resized.png";
    imSuffixTrain = "_transparent.png";

    for rewrite = 1:nTrials
        curRow = imageMatrix(rewrite,:);        % check orientation
        curRow2 = imageMatrix(rewrite,:);

        for item = 1:2
            
            objID = erase(curRow{item}, frontEnd);
            curRow{item} = objID;

            objID2 = erase(curRow2{item}, frontEnd); 
            objID2 = erase(objID2, [imPrefix, imSuffix]);

            curRow2{item} = objID2;
        end

        imageMatrix(rewrite,:) = curRow;
    end

    for rewrite = 1:12
        curRow3 = trainingImageMatrix(rewrite,:);
        curRow4 = trainingImageMatrix(rewrite,:);

        for item = 1:2

            objID = erase(curRow3{item}, frontEnd); 
            curRow3{item} = objID;

            objID2 = erase(curRow4{item}, frontEnd); 
            objID2 = erase(objID2, [imPrefix, imSuffixTrain]);

            curRow4{item} = objID2;
        end

        trainingImageMatrix(rewrite,:) = curRow3;
    end

    % %% Training image repetition check
    % 
    %     rep1 = trainingImageMatrix(1,1);
    %     rep2 = trainingImageMatrix(7,1);
    %     novel1 = trainingImageMatrix(1:6,2);
    %     novel2 = trainingImageMatrix(7:12,2);
    % 
    % 
    %     if strcmp(rep1,rep2) || any(strcmp(rep1,novel1)) || any(strcmp(rep2,novel1)) || any(strcmp(rep2,novel1)) || any(strcmp(rep2,novel2))
    %         disp("overlap");
    %     else
    %         disp("all good");
    %     end



    %% Spell out item location coordinates
    %% The x-y coordinates of where the encoding items should appear 

    wheelRadius = 150;
    coords = @(degs) wheelRadius * [cosd(degs), -sind(degs)];   % y-down screen coords
    
    thetas = conditionMatrix(:,5);

    % The distance between the repeated and the novel item is exactly 180
    % To make them orthogonal to each other. 
    % That's specific to design beta. 
    conditionMatrix(:,7:8)   = coords(thetas + 90);
    conditionMatrix(:,9:10) = coords(thetas + 270);

    thetas2 = trainingMatrix(:,5);
    trainingMatrix(:,7:8)   = coords(thetas2 + 90);
    trainingMatrix(:,9:10) = coords(thetas2 + 270);

    conditionMatrix(:,5) = [];
    trainingMatrix(:,5) = [];    

    % %% Shift everything down by one row to accommodate JS's 0-based indexing
    % tempMat = NaN(901, 15);
    % tempMat(2:end, :) = conditionMatrix;
    % conditionMatrix = tempMat;
    % tempMatString = strings(901, 3);
    % tempMatString(2:end, :) = imageMatrix;
    % imageMatrix = tempMatString;

    %% Recombine the training and main matrices. 

    combineMatrix = NaN(nTrials+12, 9);
    combineMatrix(1:12,:) = trainingMatrix(1:12,:);
    combineMatrix(13:end,:) = conditionMatrix;

    combineImageMatrix = cell(nTrials+12,2);
    combineImageMatrix(1:12,:) = trainingImageMatrix(1:12,:);
    combineImageMatrix(13:end,:) = imageMatrix;

    %% Randomize encoding sites
    randomizationIdx = repelem([0; 1], 61, 1);
    randomizationIdx = randomizationIdx(randperm(length(randomizationIdx)));

    for series = 1:nSeriesMain+1
        if randomizationIdx(series) == 0

        elseif randomizationIdx(series) == 1
            combineMatrix(series*6+1:series*6+6,end-3:end) = -1*combineMatrix(series*6+1:series*6+6,end-3:end);

        end
    end


    %% ===================== SAVE =====================
    % 
    % saveFolder = fullfile(experimentRoot, 'imperil7BetaConditionFiles');
    % saveFolderTraining = fullfile(experimentRoot, 'imperil7BetaConditionFilesTraining');
    % 
    % currentLabel = sprintf('imperil7BetaWebcond%d.mat', condFile);
    % currentLabelTrain = sprintf('imperil7BetaWebTrainCond%d.mat', condFile);
    % 
    % fullPath = fullfile(saveFolder, currentLabel);
    % fullPathTrain = fullfile(saveFolderTraining, currentLabelTrain);
    % 
    % save('conditionMatrix', 'imageMatrix');
    % save('trainingMatrix', 'trainingImageMatrix');

    %% Save the results in the JavaScript format
    outDir = '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment7/condFilesBeta';                         % folder in your repo
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    conditionFile  = fullfile(outDir, sprintf('conditionMatrix_%02d.json', condFile));
    imageFile = fullfile(outDir, sprintf('imageMatrix_%02d.json', condFile));

    fid = fopen(conditionFile, 'w', 'n', 'UTF-8');
    if fid == -1, error('Could not open %s for writing', condFile); end
    fprintf(fid, '%s', jsonencode(combineMatrix));
    fclose(fid);

    fid = fopen(imageFile, 'w', 'n', 'UTF-8');
    if fid == -1, error('Could not open %s for writing', imageFile); end
    fprintf(fid, '%s', jsonencode(combineImageMatrix));
    fclose(fid);
    % Output saved to cd
end


%% Cols: 
% CONDITION MATRIX:

% Col 1: Repetition counter
% Col 2: Context change vals
% Col 3: Repeated Item color
% Col 4: Novel Item color
% Col 5: Rotation angle
% Col 6: Probe index
% Col 7: Position 1 x coord
% Col 8: Position 1 y coord
% Col 9: Position 2 x coord
% Col 10: Position 2 y coord

% IMAGE MATRIX:
% Col 1: Repeated Item DIR
% Col 2: Novel Item DIR