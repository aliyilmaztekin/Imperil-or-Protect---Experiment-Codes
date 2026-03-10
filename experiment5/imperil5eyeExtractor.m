%% Imperil or Protect - Experiment 5 
% Extraction code
% Fixation durations and saccade lengths to encoding items
% Created by A.Y.
% First created: 2.1.2026

load("eye15.mat");
load("imperil5dataID15.mat");

% Initiate storage lists for encoding and testing screen timestamps.
encodingOnsets = NaN(length(events.Messages.time), 1);
delayOnsets = NaN(length(events.Messages.time), 1);

% Extract encoding and testing onset times based on EyeLink triggers
for curTrigger = 1:length(events.Messages.info)   
    if strcmp(events.Messages.info{curTrigger}, "ENCODING_ON")
        encodingOnsets(curTrigger) = events.Messages.time(curTrigger);
    end

    if strcmp(events.Messages.info{curTrigger}, "DELAY_ON")
        delayOnsets(curTrigger) = events.Messages.time(curTrigger);
    end
end

% Clean all the NaNs (they mark time for other trial events)
encodingOnsets = encodingOnsets(~isnan(encodingOnsets));
delayOnsets  = delayOnsets(~isnan(delayOnsets));

% Encoding times sum up to total trial count
nTrial = numel(encodingOnsets);

%% Encoding site locations
% Cartesian coordinates of the left-lateralized encoding site
encodingSites.leftHalf.left = 586;
encodingSites.leftHalf.right = 686;
encodingSites.leftHalf.top = 490;
encodingSites.leftHalf.bottom = 590;

% Cartesian coordinates of the right-lateralized encoding site
encodingSites.rightHalf.left = 1234;
encodingSites.rightHalf.right = 1334;
encodingSites.rightHalf.top = 490;
encodingSites.rightHalf.bottom = 590;

% Since we're recording both eyes, most occulomotor events in the data 
% are duplicated. Left and right eye almost always perform the same thing.
% So, filter the events down to one eye only. 
isLeftFix = strcmp(events.Efix.eye, 'LEFT');
isBothFix = strcmp(events.Efix.eye, 'BOTH'); % Pretty much means left only or right only.  

% Store the start and end times of all fixation instances
fixationStart = events.Efix.start(isLeftFix | isBothFix);
fixationEnd = events.Efix.end(isLeftFix | isBothFix);
nFixation = numel(fixationStart); % or fixationEnd, doesn't matter.

% These are the Cartesian coordinates of where all the fixation ended. 
% We need those values to analyze only the fixation that were made to the
% target item. 
fixationXCo = events.Efix.posX((isLeftFix | isBothFix));
fixationYCo = events.Efix.posY((isLeftFix | isBothFix));

% Get only the left eye saccades
isLeftSaccade = strcmp(events.Esacc.eye, 'LEFT');
isBothSaccade = strcmp(events.Esacc.eye, 'BOTH'); % Pretty much means left only or right only.

% Find the number of saccade events
saccadeStart = events.Esacc.start(isLeftSaccade | isBothSaccade);
saccadeEnd = events.Esacc.end(isLeftSaccade | isBothSaccade);
nSaccade = numel(saccadeStart);

% Get the Cartesian coordinates of the start and end points of all saccades
saccadeXStart = events.Esacc.posX((isLeftSaccade | isBothSaccade));
saccadeYStart = events.Esacc.posY((isLeftSaccade | isBothSaccade));
saccadeXEnd = events.Esacc.posXend((isLeftSaccade | isBothSaccade));
saccadeYEnd = events.Esacc.posYend((isLeftSaccade | isBothSaccade));

% Some storage caches for our DVs of interest
encodingFixDurations = cell(nTrial,1);   % individual fixation durations
encodingFixTotal     = NaN(nTrial,1);    % summed dwell time

% We only want fixations that were made to where the target item was
% presented. We have the coordinates defined above that tell us where the
% items could have been presented. But it's the behavioral data 
% that tells us which of these two locations was used in a given trial.  
encodingLateralization = outputMatrix(:,8); 

% To store occulomotor events that pass the rejection criteria specified
% below. 
goodFixations = NaN(nFixation,6);
goodSaccades = NaN(nSaccade,9);

% Epoch of interest: The encoding screen (60-600). 
% Notice it doesn't start from time zero. That's because
% in eye studies, the first 50-100 ms are usually left out
% since they may reflect adaptation to perceptual changes from
% having just switched to the encoding screen. 
encodingBuffer = 60;

% We have the coordinates to the encoding items, but obviously
% a fixation that's not exactly on the image itself but a little 
% bit on the surround is fine too. So, bump up the allowed space a bit. 
locationBump = 25;

% Fixations and saccades are not the same size. So, they need 
% to be checked spearately

% Counter to keep track of and append good and bad fixations 
fixAccepted = 1;
nonTargetFixation = 0;

for fixation = 1:nFixation
    
    % Temporal info of the current fixation
    curFixStart = fixationStart(fixation);
    curFixEnd = fixationEnd(fixation);

    % Spatial info of the current fixation
    curFixXCO = fixationXCo(fixation);
    curFixYCO = fixationYCo(fixation);
    
    % Check the current fixation for the epoch of each trial.
    for epoch = 1:nTrial
        
        % Define epoch bounds in the current trial
        epochStart = encodingOnsets(epoch) + encodingBuffer;
        epochEnd   = delayOnsets(epoch);

        % Overlap here indexes exactly how much time is spent 
        % maintaining a fixation within the epoch bounds
        overlapStart = max(curFixStart, epochStart);
        overlapEnd   = min(curFixEnd, epochEnd);

        % Get the current encoding lateralization
        curLat = encodingLateralization(epoch);

        % The current fixation time points are first compared to the epoch
        % bounds of the current trial. This is just to see whether the
        % current fixation was made in the current trial. 
        
        %% Rejection criteria:
        % 1) A valid fixation has to be within the bounds of the
        % encoding item in space. 

        if overlapEnd > overlapStart
            % If fixation is within the epoch, proceed to:

            %% 2) A valid fixation has to be within the spatial bounds of the
            % encoding item.  
            
            % If encoding was lateralized to the left half
            if curLat == 0

                % Check if the fixation is within the image bounds
                % Bump up the area of interest a bit as discussed above. 
                if curFixXCO >= (encodingSites.leftHalf.left - locationBump) && ...
                        curFixXCO <= (encodingSites.leftHalf.right + locationBump) && ...
                        curFixYCO >= (encodingSites.leftHalf.top - locationBump) && ...
                        curFixYCO <= (encodingSites.leftHalf.bottom + locationBump)

                    % Fixation is both temporally and spatially valid.
                    % Accept it.

                    % Save fixation info
                    goodFixations(fixAccepted, 1) = epoch;
                    goodFixations(fixAccepted, 2) = overlapStart;
                    goodFixations(fixAccepted, 3) = overlapEnd;
                    goodFixations(fixAccepted, 4) = goodFixations(fixAccepted,3) ...
                        - goodFixations(fixAccepted,2); % Compute fixation durations
                    goodFixations(fixAccepted, 5) = curFixXCO;
                    goodFixations(fixAccepted, 6) = curFixYCO;

                    % Index for navigating goodFixations
                    fixAccepted = fixAccepted + 1;

                    % Move on with the next fixation event.
                    break;

                else
                    % Save to calculate fixation proportions 
                    nonTargetFixation = nonTargetFixation + 1;

                    % Temporal criterion is met but not the spatial.
                    % Thus, the current fixation was not made to the
                    % target. Move along with the next fixation. 
                    break;
                end
            
            % If the encoding site was the right half
            elseif curLat == 1

                % If the fixation occurred around the image 
                if curFixXCO >= (encodingSites.rightHalf.left - locationBump) && ...
                        curFixXCO <= (encodingSites.rightHalf.right + locationBump) && ...
                        curFixYCO >= (encodingSites.rightHalf.top - locationBump)  && ...
                        curFixYCO <= (encodingSites.rightHalf.bottom + locationBump)

                    % Save fixation information
                    goodFixations(fixAccepted, 1) = epoch;
                    goodFixations(fixAccepted, 2) = overlapStart;
                    goodFixations(fixAccepted, 3) = overlapEnd;
                    goodFixations(fixAccepted, 4) = goodFixations(fixAccepted,3) ...
                        - goodFixations(fixAccepted,2); % Compute fixation durations
                    goodFixations(fixAccepted, 5) = curFixXCO;
                    goodFixations(fixAccepted, 6) = curFixYCO;

                    % Index for navigating goodFixations
                    fixAccepted = fixAccepted + 1;

                    % Move on with the next fixation event. 
                    break;

                else
                    % Save to calculate fixation proportions 
                    nonTargetFixation = nonTargetFixation + 1;

                    % Temporal criterion is met but not the spatial.
                    % Thus, the current fixation was not made to the
                    % target. Move along with the next fixation.

                    break;
                end
            end
        else
            % The temporal check failed. 
            % This is not the right trial for the current fixation
            % Move on to the next epoch.
            continue;
        end 
    end
end

% Set up some counters
saccadeAccepted = 1;
nonTargetSaccades = 0;
allSaccadeTrial = NaN(nSaccade,1);

for saccade = 1:nSaccade
    
    % Temporal info of the current saccade
    curSaccadeStart = saccadeStart(saccade);
    curSaccadeEnd = saccadeEnd(saccade);

    % Spatial info of the current saccade
    curSaccadeXStart = saccadeXStart(saccade);
    curSaccadeYStart = saccadeYStart(saccade);
    curSaccadeXEnd = saccadeXEnd(saccade);
    curSaccadeYEnd = saccadeYEnd(saccade);
  
    % Check the current saccade for the epoch of each trial.
    for epoch = 1:nTrial
        
        % Define epoch bounds in the current trial
        epochStart = encodingOnsets(epoch) + encodingBuffer;
        epochEnd   = delayOnsets(epoch);

        % Overlap here indexes exactly how much time is spent 
        % during a fixation within the epoch bounds
        overlapStart = max(curSaccadeStart, epochStart);
        overlapEnd   = min(curSaccadeEnd, epochEnd);

        % Get the current encoding lateralization
        curLat = encodingLateralization(epoch);

        % The current saccade time points are first compared to the epoch
        % bounds of the current trial. This is just to see whether the
        % current saccade was made in the current trial. 
        
        %% Rejection criteria:
        % 1) A valid saccade has to be within the bounds of the
        % encoding item in space. 

        if overlapEnd > overlapStart

            allSaccadeTrial(saccade) = epoch;

            % If saccade is within the epoch, proceed to:

            %% 2) A valid saccade has to be within the spatial bounds of the
            % encoding item.  
            
            % If encoding was lateralized to the left half
            if curLat == 0

                % Check if the saccade endpoint is within the image bounds
                % Bump up the area of interest a bit as discussed above. 
                if curSaccadeXEnd >= (encodingSites.leftHalf.left - locationBump) && ...
                        curSaccadeXEnd <= (encodingSites.leftHalf.right + locationBump) && ...
                        curSaccadeYEnd >= (encodingSites.leftHalf.top - locationBump) && ...
                        curSaccadeYEnd <= (encodingSites.leftHalf.bottom + locationBump)

                    % Saccade is both temporally and spatially valid.
                    % Accept it.

                    % Save saccade info
                    goodSaccades(saccadeAccepted, 1) = epoch;
                    goodSaccades(saccadeAccepted, 2) = overlapStart;
                    goodSaccades(saccadeAccepted, 3) = overlapEnd;
                    goodSaccades(saccadeAccepted, 4) = goodSaccades(saccadeAccepted,3) ...
                        - goodSaccades(saccadeAccepted,2); % Compute saccade durations
                    goodSaccades(saccadeAccepted, 5) = curSaccadeXStart;
                    goodSaccades(saccadeAccepted, 6) = curSaccadeYStart;
                    goodSaccades(saccadeAccepted, 7) = curSaccadeXEnd;
                    goodSaccades(saccadeAccepted, 8) = curSaccadeYEnd;
                    goodSaccades(saccadeAccepted,9) = hypot(goodSaccades(saccadeAccepted,7) ...
                        - goodSaccades(saccadeAccepted,5), ...
                        goodSaccades(saccadeAccepted,8) ...
                        - goodSaccades(saccadeAccepted,6)); % Compute saccade lengths

                    % Index for navigating goodSaccades
                    saccadeAccepted = saccadeAccepted + 1;

                    % Move on with the next saccade event.
                    break;

                else
                    % Count to calculate proportion of saccades to the
                    % target later. 
                    nonTargetSaccades = nonTargetSaccades + 1;

                    % Temporal criterion is met but not the spatial.
                    % Thus, the current saccade was not made to the
                    % target. Move along with the next saccade. 

                    break;
                end
            
            % If the encoding site was the right half
            elseif curLat == 1

                if curSaccadeXEnd >= (encodingSites.rightHalf.left - locationBump) && ...
                        curSaccadeXEnd <= (encodingSites.rightHalf.right + locationBump) && ...
                        curSaccadeYEnd >= (encodingSites.rightHalf.top - locationBump) && ...
                        curSaccadeYEnd <= (encodingSites.rightHalf.bottom + locationBump)

                    % Save saccade info
                    goodSaccades(saccadeAccepted, 1) = epoch;
                    goodSaccades(saccadeAccepted, 2) = overlapStart;
                    goodSaccades(saccadeAccepted, 3) = overlapEnd;
                    goodSaccades(saccadeAccepted, 4) = goodSaccades(saccadeAccepted,3) ...
                        - goodSaccades(saccadeAccepted,2); % Compute saccade durations
                    goodSaccades(saccadeAccepted, 5) = curSaccadeXStart;
                    goodSaccades(saccadeAccepted, 6) = curSaccadeYStart;
                    goodSaccades(saccadeAccepted, 7) = curSaccadeXEnd;
                    goodSaccades(saccadeAccepted, 8) = curSaccadeYEnd;
                    goodSaccades(saccadeAccepted,9) = hypot(goodSaccades(saccadeAccepted,7) ...
                        - goodSaccades(saccadeAccepted,5), ...
                        goodSaccades(saccadeAccepted,8) ...
                        - goodSaccades(saccadeAccepted,6)); % Compute saccade lengths

                    % Index for navigating goodSaccades
                    saccadeAccepted = saccadeAccepted + 1;
                   
                    % Move on with the next fixation event. 
                    break;

                else
                    % Count to calculate proportion of saccades to the
                    % target later. 
                    nonTargetSaccades = nonTargetSaccades + 1;

                    % Temporal criterion is met but not the spatial.
                    % Thus, the current saccade was not made to the
                    % target. Move along with the next saccade. 

                    break;
                end
            end
        else
            % The temporal check failed. 
            % This is not the right trial for the current saccade
            % Move on to the next epoch.
            continue;
        end 
    end
end

% Squeeze out the empty rows
goodFixations = goodFixations(~isnan(goodFixations(:,1)), :);
goodSaccades = goodSaccades(~isnan(goodSaccades(:,1)), :);
allSaccadeTrial = allSaccadeTrial(~isnan(allSaccadeTrial));

%% Rejection of blinks (and other undesirable events) 
%% before calculating mean measurements: 

% Fixation events shorter than 60 ms are likely the outcomes of blinks,
% epoch clipping issues, etc. It's not that possible to pinpoint exactly
% what they are, but regardless, most studies simply filter them out.

% Fixation durations are usually filtered from these artifacts with a
% minimum time threshold. A reasonable convention is 60 ms. 

% Fixations shorter than this cut-off are not worth keeping.
goodFixations(goodFixations(:,4) <= 60, :) = [];

%% Saccade rejection
% Blink-contamination in saccade events show up as unreasonably high amplitudes
% and lengths. 

% On the contrary, the extremely smaller counterpart of these metrics
% are usually micro-saccades, which could be thrown away or stored as a DV
% on its own, all depending on the phenomenon you're studying. 

% Blink lengths shorter than this cut-off could be stored away outside the
% dataset, as they may be micro-saccades that could be valuable data. 

pixelCutOff = 20.3569;
degCutOff = 0.5;

isMicro = goodSaccades(:,9) < pixelCutOff;
microSaccades = goodSaccades(isMicro,9);
goodSaccades(isMicro, :) = [];

saccTrialIdx = goodSaccades(:,1);
saccadeLengths = goodSaccades(:,9);
firstSaccIdx = [true; diff(saccTrialIdx) ~= 0];

% You should convert the saccade lengths to visual degrees as is the
% convention in cog. psyc. papers. Anything that is measured in distance is
% usually converted into visual degrees as a form of metric
% standardization. 

% Relevant parameters: 
screenWidthPixels = 1920;
screenHeightPixels = 1080;
screenWidthCM = 53.5;
screenHeightCM = 30;
viewingDistance = 65;
pixelPCM = screenWidthCM/screenWidthPixels;

% A function to convert pixels to visual degrees
visual_deg = @(saccadeLengthPx) ...
    2 .* atan( ...
        (saccadeLengthPx .* pixelPCM) ./ (2 .* viewingDistance) ...
    ) .* (180 ./ pi);

saccadeLengthsDeg = visual_deg(saccadeLengths);

totalSaccadeLength = accumarray(saccTrialIdx, saccadeLengths, [nTrial 1], @sum);
meanSaccadeLength = accumarray(saccTrialIdx, saccadeLengths, [nTrial 1], @mean);
totalSaccadeLengthDeg = accumarray(saccTrialIdx, saccadeLengthsDeg, [nTrial 1], @sum);
meanSaccadeLengthDeg = accumarray(saccTrialIdx, saccadeLengthsDeg, [nTrial 1], @mean);

%% So far, we have stored individual fixation and saccade durations, 
% as well as individual saccade lenghts. From these values, we need to
% derive: 

% Total fixation duration (Dwell time)
% Mean fixation duration
% The duration of the first fixation 
% Proportion of saccades to the target
% Total saccade length
% Mean saccade length

trialIdx = goodFixations(:,1);
fixationDurations = goodFixations(:,4);

dwellTime = accumarray(trialIdx, fixationDurations, [nTrial 1], @sum);
meanFixDuration = accumarray(trialIdx, fixationDurations, [nTrial 1], @mean);

firstFixIdx = [true; diff(trialIdx) ~= 0];
firstFixDurations = NaN(nTrial,1);   % trial-aligned, NaN = no fixation
firstFixDurations(trialIdx(firstFixIdx)) = fixationDurations(firstFixIdx);

% Replace 0s in the outputs with a NaN
dwellTime(dwellTime(:) == 0) = NaN;
meanFixDuration(meanFixDuration(:) == 0) = NaN;
firstFixDurations(firstFixDurations(:) == 0) = NaN;
totalSaccadeLength(totalSaccadeLength(:) == 0) = NaN;
meanSaccadeLength(meanSaccadeLength(:) == 0) = NaN;
totalSaccadeLengthDeg(totalSaccadeLengthDeg(:) == 0) = NaN;
meanSaccadeLengthDeg(meanSaccadeLengthDeg(:) == 0) = NaN;

%% Proportion of saccades made to the target item
targetSaccCount = accumarray( ...
    goodSaccades(:,1), ...   % trial index
    1, ...
    [nTrial 1], ...
    @sum, ...
    NaN);

totalSaccCount = accumarray( ...
    allSaccadeTrial, ...
    1, ...
    [nTrial 1], ...
    @sum, ...
    NaN);

pSaccadeToTarget = targetSaccCount ./ totalSaccCount;
pSaccadeToTarget = pSaccadeToTarget * 100;

% Putting it all together
resultsMatrix = NaN(576, 12);

resultsMatrix(:, 1) = (1:nTrial); % Trial count
resultsMatrix(:, 2) = repmat((1:6)', nTrial/6, 1); % Repetition 
resultsMatrix(:, 3) = outputMatrix(:,6); % Context change value (0, 1)
resultsMatrix(:, 4) = outputMatrix(:,14); % Condition value (1, 2, 3, 4)
resultsMatrix(:, 5) = dwellTime;
resultsMatrix(:, 6) = meanFixDuration;
resultsMatrix(:, 7) = firstFixDurations;
resultsMatrix(:, 8) = totalSaccadeLength;
resultsMatrix(:, 9) = meanSaccadeLength;
resultsMatrix(:, 10) = totalSaccadeLengthDeg;
resultsMatrix(:, 11) = meanSaccadeLengthDeg;
resultsMatrix(:, 12) = pSaccadeToTarget;

%% Proportion of saccades to the target per condition
% Per condition
resultsForP = resultsMatrix;
resultsForP(isnan(resultsMatrix(:,4)), :) = [];
pCond = accumarray(resultsForP(:,4), resultsForP(:,12), [4 1], @(x) mean(x, "omitnan"));

% Per repetition
pRepetition = accumarray(resultsMatrix(:,2), resultsMatrix(:,12), [6 1], @(x) mean(x, 'omitnan'));

%% Behavioral measures
% RT across repetitions
repRT = accumarray(outputMatrix(:,5), outputMatrix(:,13), [6 1], @(x) mean(x, 'omitnan'));

% RT across conditions
outForRT = outputMatrix;
outForRT(isnan(outputMatrix(:,14)),:) = []; 
condRT = accumarray(outForRT(:,14), outForRT(:,13), [4 1], @(x) mean(x, "omitnan"));

% Accuracy across repetitions
repACC = accumarray(outputMatrix(:,5), outputMatrix(:,12), [6 1], @(x) mean(x, "omitnan"));

% Accuracy across conditions
outForACC = outputMatrix;
outForACC(isnan(outputMatrix(:,14)),:) = []; 
condACC = accumarray(outForACC(:,14), outForACC(:,12), [4 1], @(x) mean(x, "omitnan"));

%% Visualization

% Below is a plot of mean saccade lengths over item repetitions.
% First, group mean saccade lengths into item repetitions.

meanDwellOverReps = accumarray(resultsMatrix(:,2), resultsMatrix(:,5), [6 1], @(x) mean(x, 'omitnan'));

repIdx = 1:6;
figure;
bar(repIdx, meanDwellOverReps);
title('Mean dwell time by repetiton')
ylabel('Mean dwell time (ms)')
xticks(1:6);
xticklabels({'Rep 1','Rep 2','Rep 3','Rep 4','Rep 5','Rep 6'});
xtickangle(15);
ylim([0 max(meanDwellOverReps)*1.2]);

meanSaccOverReps = accumarray(resultsMatrix(:,2), resultsMatrix(:,9), [6 1], @(x) mean(x, 'omitnan'));

repIdx = 1:6;
figure;
bar(repIdx, meanSaccOverReps);
title('Mean saccade length by repetition')
ylabel('Mean saccade lengths (pixels)')
xticks(1:6);
xticklabels({'Rep 1','Rep 2','Rep 3','Rep 4','Rep 5','Rep 6'});
xtickangle(15);
ylim([0 max(meanSaccOverReps)*1.2]);

% Now, do it condition-specific

meanSaccRep1NoChange = mean(resultsMatrix(resultsMatrix(:,4) == 1, 9), 'omitnan');
meanSaccRep1Change = mean(resultsMatrix(resultsMatrix(:,4) == 2, 9), 'omitnan');
meanSaccRep5NoChange = mean(resultsMatrix(resultsMatrix(:,4) == 3, 9), 'omitnan');
meanSaccRep5Change = mean(resultsMatrix(resultsMatrix(:,4) == 4, 9), 'omitnan');

meanSaccAcrossConds = [meanSaccRep1NoChange; meanSaccRep1Change; meanSaccRep5NoChange; meanSaccRep5Change];

figure;
bar(meanSaccAcrossConds);
title('Mean saccade length by condition');
ylabel('Mean saccade length (pixels)');
xticks(1:4);
xticklabels({ ...
    'Rep 1 – No change', ...
    'Rep 1 – Change', ...
    'Rep 5 – No change', ...
    'Rep 5 – Change'});
xtickangle(15);
ylim([0 max(meanSaccAcrossConds)*1.2]);

% Now do one condition-specific plot for our second DV of interest: Dwell
% time. Simply repeat the procedure. 

meanDwellRep1NoChange = mean(resultsMatrix(resultsMatrix(:,4) == 1, 5), 'omitnan');
meanDwellRep1Change = mean(resultsMatrix(resultsMatrix(:,4) == 2, 5), 'omitnan');
meanDwellRep5NoChange = mean(resultsMatrix(resultsMatrix(:,4) == 3, 5), 'omitnan');
meanDwellRep5Change = mean(resultsMatrix(resultsMatrix(:,4) == 4, 5), 'omitnan');

meanDwellAcrossConds = [meanDwellRep1NoChange; meanDwellRep1Change; meanDwellRep5NoChange; meanDwellRep5Change];

figure;
bar(meanDwellAcrossConds);
title('Mean dwell time by condition');
ylabel('Mean dwell time (ms)');
xticks(1:4);
xticklabels({ ...
    'Rep 1 – No change', ...
    'Rep 1 – Change', ...
    'Rep 5 – No change', ...
    'Rep 5 – Change'});
xtickangle(15);
ylim([0 max(meanDwellAcrossConds)*1.2]);








%% After that, maybe look into analyzing pupil dilations? 


