%% Protect or Imperil - Experiment 4 Code 
% Coded by A.Y.
% Finalized - 07.10.2025 - v1.0
% Further refinements - 08.10.2025 - v1.1
% A couple of more touches - 09.10.2025 - v1.2

%% Runing on what? Mark true:
aliscomputer = false;
experimentcomputer = true;

% Relevant directories given the computer handle
if aliscomputer && ~(experimentcomputer)
    condFiles = '/Users/ali/Desktop/visual imperil project/imperil4materials/imperil4ConditionFiles';
    stimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil4materials/testObjectsTransparent'; 
    trainingStimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil4materials/trainingStimuli';
    outputDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/outputFiles';
    workspaceDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/experimentWorkspace';
    subjectCountDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/';
elseif ~aliscomputer && experimentcomputer
    condFiles = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials\imperil4conditionFiles';
    stimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials\testObjectsTransparent';
    trainingStimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials\trainingStimuli';
    outputDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials\outputFiles';
    workspaceDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials\experimentWorkspace';
    subjectCountDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials';
end

%%%%%%%%Participant Number Input%%%%%%%%
addpath(genpath('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\'))
% Load the last participant number (if the file exists)
if exist('imperil4subjectcount.mat', 'file')
    load('imperil4subjectcount.mat', 'lastParticipantNumber');
else
    lastParticipantNumber = 0;  % Start from 0 if no file exists
end

% Display the last used number
fprintf('Last participant number used: %d\n', lastParticipantNumber);

% Get input
participantNumber = input('Enter participant number (or 999 to reset): ');

% Special reset code
if participantNumber == 999
    lastParticipantNumber = 0;
    save('imperil4subjectcount.mat', 'lastParticipantNumber');
    error('Participant counter reset to 0. Please restart the script and enter a new number.');
end

% Check that new number is not smaller than last
if participantNumber <= lastParticipantNumber
    error('Participant number must be greater than the last used (%d).', lastParticipantNumber);
end

% Save the new participant number for next time
lastParticipantNumber = participantNumber;
save(fullfile(subjectCountDest, 'imperil4subjectcount.mat'), 'lastParticipantNumber');

%%%%%%%%Participant Number Input%%%%%%%%


%%%%%%%%Engage Next Condition File%%%%%%%%

currentConditionNumber = mod(lastParticipantNumber - 1, 15) + 1;


% Build the filename dynamically
currentCond = sprintf('imperil4cond%d.mat', currentConditionNumber);

% Build the full path
fileToLoad = fullfile(condFiles, currentCond);

% Load it
load(fileToLoad);  % This will load whatever variables are inside

% First and foremost, I believe in the ultimate randomness of the universe
rng('shuffle');

%% SCREEN PARAMETERS

% Open the window with the specified dimensions
Screen('Preference', 'SkipSyncTests', 0)
monitor = max(Screen('Screens'));
[window, windowRect] = Screen('OpenWindow', monitor, [128 128 128]); 

% That's for image transparency 
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
alphaInterference = 255; % Transparency

% For flip scheduling
ifi = Screen('GetFlipInterval', window); %measure refresh rate

% To hide the cursor throughout the experiment
HideCursor(window);

% To get the screen resolution
centerX = round(windowRect(3)/2);
centerY = round(windowRect(4)/2);

% Color wheel dimensions
colorWheel.radius = 225;
colorWheel.rect = CenterRect([0 0 colorWheel.radius*2 colorWheel.radius*2], windowRect);
stim.size = 256;
stimRect = CenterRect([0 0 stim.size stim.size], windowRect);

% Set up the coordinate space
screenHeight=windowRect(4);
screenWidth=windowRect(3);
yAxis = 1:screenHeight - stim.size;
xAxis = 1:screenWidth - stim.size;

% Make each image this big
imageSize = [256 256];

% Parameters for drawing text on the feedback display & break screen
textSize = 30;
Screen('TextSize', window, textSize);
textColorPostResponse = [0 0 0];
instructionsTextColor = [255 255 255];
lineSpacing = 40;

% Define keys to allow keypresses
% Hold ESC down for at least 2 seconds during testing to quit PTB
KbName('UnifyKeyNames');
escStartTime = NaN;

%% Training Matrix Generation
% Before proceeding to further modify the condition matrix, first trim off
% the bit that's going to serve as condition matrix for training. 

trainingMaxLength = 60;

totalTrialCount = (length(finalMatrix) - trainingMaxLength);
upperLim = length(finalMatrix);

if totalTrialCount == 720
    trialPerBlock = 48; %15 Blocks
elseif totalTrialCount == 480
    trialPerBlock = 30; %16 Blocks
end

totalBlock = totalTrialCount/trialPerBlock;

trainingMatrix = zeros(trainingMaxLength,8);
trainingImageMatrix = cell(trainingMaxLength,2);
trainingMatrix(:,1) = finalMatrix((totalTrialCount + 1):upperLim,1); 
trainingMatrix(:,2:4) = finalMatrix((totalTrialCount + 1):upperLim,2:4);

% Erase the training matrix from the finalMatrix. 
finalMatrix((totalTrialCount + 1):upperLim, :) = [];

% Get list of all PNG files in that folder
stimuliFiles = dir(fullfile(stimuliDIR, '*.png'));

% Make a cell array of full file paths
stimuliPaths = fullfile({stimuliFiles.folder}, {stimuliFiles.name});

% The stimuli pool contains 396 images. [totalTrialCount/6] will serve as primary images. 
% Begin by randomly picking the primary images:

nStimuli = numel(stimuliPaths);  % total number available
nSelect  = totalTrialCount/6;                 % number you want to select

primaryImageFiles = randperm(nStimuli, nSelect);  % randomly sample unique indices
primaryImagePaths = stimuliPaths(primaryImageFiles);

% --- RANDOMIZE INITIAL ORDER ---
primaryImagePaths = primaryImagePaths(randperm(numel(primaryImagePaths)));

% Suppose primaryImageFiles is your 120×1 cell array
combinedPrimaryPaths = repelem(primaryImagePaths(:), 6, 1);

% {nStimuli-[totalTrialCount/6]} images remain. We need [totalTrialCount] secondary images. Some will have to
% repeat
keepMask = true(size(stimuliPaths));
keepMask(primaryImageFiles) = false;  % mark selected ones as false

% Make a new pool with remaining stimuli
remainingPaths = stimuliPaths(keepMask);

% --- BUILD SECONDARY POOL (totalTrialCount total) ---
extraCount = (totalTrialCount) - numel(remainingPaths);
extraIdx   = randperm(numel(remainingPaths), extraCount);
extraPaths = remainingPaths(extraIdx);

combinedSecondaryPaths = [remainingPaths, extraPaths];
combinedSecondaryPaths = combinedSecondaryPaths(:); % make column vector
combinedSecondaryPaths = combinedSecondaryPaths(randperm(numel(combinedSecondaryPaths))); % shuffle

% --- CHECK & FIX BLOCK DUPLICATES ---
nBlocks = totalBlock;
blockSize = trialPerBlock;

% --- ENSURE NO DUPLICATES IN ANY BLOCK (ITERATIVE) ---
maxIterations = 1000;
iteration = 0;
changed = true;

while changed && iteration < maxIterations
    changed = false;
    iteration = iteration + 1;

    for b = 1:nBlocks
        blockIdx   = (b-1)*blockSize + (1:blockSize);
        blockPaths = combinedSecondaryPaths(blockIdx);

        [uniquePaths, ~, ic] = unique(blockPaths); % find unique images
        dupCounts = histcounts(ic, 1:max(ic)+1);
        dups = uniquePaths(dupCounts > 1);

        for d = 1:numel(dups)
            dupIndices = find(strcmp(blockPaths, dups{d}));

            for k = 2:numel(dupIndices) % keep first, swap others
                swapIdx = blockIdx(dupIndices(k));
                outsideIdx = setdiff(1:numel(combinedSecondaryPaths), blockIdx);
                candidates = outsideIdx(~strcmp(combinedSecondaryPaths(outsideIdx), dups{d}));

                if ~isempty(candidates)
                    chosenIdx = candidates(randi(numel(candidates)));
                    tmp = combinedSecondaryPaths(swapIdx);
                    combinedSecondaryPaths(swapIdx) = combinedSecondaryPaths(chosenIdx);
                    combinedSecondaryPaths(chosenIdx) = tmp;
                    changed = true;
                end
            end
        end
    end
end

% fprintf('Duplicate-fixing finished after %d iterations.\n', iteration);

% --- SANITY CHECK AGAIN ---
% fprintf('Sanity check results:\n');
for b = 1:nBlocks
    blockIdx   = (b-1)*blockSize + (1:blockSize);
    blockPaths = combinedSecondaryPaths(blockIdx);
    nUnique = numel(unique(blockPaths));
    nDup    = blockSize - nUnique;
    % fprintf('Block %d: %d duplicates found.\n', b, nDup);
end

% Lastly, combine the primary and secondary images paths into a single
% matrix

imageMatrix = cell(totalTrialCount, 2);
imageMatrix(:,1) = combinedPrimaryPaths;   % fill column 1
imageMatrix(:,2) = combinedSecondaryPaths; % fill column 2

% % Take a subset of colors from the output for training and leave them out
% trainingColorsPrimary = primaryImageColors(end-12:end);
% trainingColorsSecondary = secondaryImageColors(end-12:end);

executiveMatrix.finalMatrix = finalMatrix;
executiveMatrix.imageMatrix = imageMatrix;

% Convert finalMatrix into a table with meaningful column names
executiveMatrix.finalMatrix = table( ...
    finalMatrix(:,1), ... % Repetition
    finalMatrix(:,2), ... % Context Change Values
    finalMatrix(:,3), ... % Primary Image Color Index
    finalMatrix(:,4), ... % Secondary Image Color Index
    'VariableNames', { ...
        'Repetition', ...
        'ContextChange', ...
        'PrimaryImageColorIndex', ...
        'SecondaryImageColorIndex', ....
        });

% Convert imageMatrix (cell array) into a table with column names
executiveMatrix.imageMatrix = cell2table(imageMatrix, ...
    'VariableNames', {'PrimaryImageName','SecondaryImageName'});

% SETTINGS
minColorDistance = 40;
minRowDistance = 60;

% Extract SecondaryImageNames and Color Indices for convenience
secondaryNames = executiveMatrix.imageMatrix.SecondaryImageName;
colorIndices = executiveMatrix.finalMatrix.SecondaryImageColorIndex;

% Find duplicates
[uniqueNames, ~, nameIndices] = unique(secondaryNames);
nameCounts = accumarray(nameIndices, 1);
duplicateNames = uniqueNames(nameCounts > 1);

% We will iterate until no violations or max iterations reached
maxIterations = 100;
iteration = 0;

while iteration < maxIterations
    iteration = iteration + 1;
    % fprintf('🔄 Iteration %d of fixing violations\n', iteration);
    
    violationFound = false;
    
    % Refresh these each iteration
    secondaryNames = executiveMatrix.imageMatrix.SecondaryImageName;
    colorIndices = executiveMatrix.finalMatrix.SecondaryImageColorIndex;
    
    % Refresh duplicates info
    [uniqueNames, ~, nameIndices] = unique(secondaryNames);
    nameCounts = accumarray(nameIndices, 1);
    duplicateNames = uniqueNames(nameCounts > 1);
    
    for i = 1:length(duplicateNames)
        thisName = duplicateNames{i};
        
        % All rows where this duplicate image occurs
        rowMatches = find(strcmp(secondaryNames, thisName));
        
        % Check all pairs of occurrences
        for j = 1:length(rowMatches)-1
            row1 = rowMatches(j);
            for k = j+1:length(rowMatches)
                row2 = rowMatches(k);
                
                color1 = colorIndices(row1);
                color2 = colorIndices(row2);
                colorDiff = abs(color1 - color2);
                rowDiff = abs(row1 - row2);
                
                % Check color violation
                if colorDiff < minColorDistance || rowDiff < minRowDistance
                    violationFound = true;
                    % fprintf('⚠️ Violation for "%s" at rows %d & %d: colorDiff=%d, rowDiff=%d\n', ...
                    %     thisName, row1, row2, colorDiff, rowDiff);
                    
                    % Replacement candidate pool = all rows with duplicate images except current rows
                    duplicateRows = find(ismember(secondaryNames, duplicateNames));
                    candidateRows = duplicateRows(duplicateRows ~= row2 & abs(duplicateRows - row1) >= minRowDistance);
                    
                    % Shuffle candidates
                    candidateRows = candidateRows(randperm(length(candidateRows)));
                    
                    replacementFound = false;
                    
                    for candidateRow = candidateRows'
                        candidateName = secondaryNames{candidateRow};
                        candidateColor = colorIndices(candidateRow);
                        
                        % Ensure candidate differs enough in color and not same image to prevent loops
                        if abs(candidateColor - color1) >= minColorDistance && ~strcmp(candidateName, thisName)
                            % Make the replacement
                            % fprintf('➡️ Replacing row %d image "%s" with "%s" from row %d\n', ...
                            %     row2, thisName, candidateName, candidateRow);
                            
                            executiveMatrix.imageMatrix.SecondaryImageName{row2} = candidateName;
                            replacementFound = true;
                            break;
                        end
                    end
                    
                    if ~replacementFound
                        % warning('❌ No valid replacement found for row %d ("%s")', row2, thisName);
                    end
                end
            end
        end
    end
    
    % If no violations found this iteration, break early
    if ~violationFound
        % fprintf('✅ No violations detected on iteration %d — fixing complete.\n', iteration);
        break;
    end
end

if violationFound
    % warning('⚠️ Maximum iterations reached but some violations may remain.');
end

% === Final Sanity Check ===
tooCloseColorCount = 0;
tooCloseRowCount = 0;

secondaryNames = executiveMatrix.imageMatrix.SecondaryImageName;
colorIndices = executiveMatrix.finalMatrix.SecondaryImageColorIndex;

[uniqueNames, ~, nameIndices] = unique(secondaryNames);
nameCounts = accumarray(nameIndices, 1);
duplicateNames = uniqueNames(nameCounts > 1);

for i = 1:length(duplicateNames)
    thisName = duplicateNames{i};
    rows = find(strcmp(secondaryNames, thisName));
    
    for j = 1:length(rows)-1
        for k = j+1:length(rows)
            row1 = rows(j);
            row2 = rows(k);
            
            color1 = colorIndices(row1);
            color2 = colorIndices(row2);
            rowDiff = abs(row1 - row2);
            colorDiff = abs(color1 - color2);
            
            if colorDiff < minColorDistance
                tooCloseColorCount = tooCloseColorCount + 1;
                % fprintf('❌ Color too close for "%s" at rows %d & %d (∆ = %d)\n', ...
                %     thisName, row1, row2, colorDiff);
            end
            
            if rowDiff < minRowDistance
                tooCloseRowCount = tooCloseRowCount + 1;
                % fprintf('❌ Row distance too close for "%s" at rows %d & %d (∆ = %d)\n', ...
                %     thisName, row1, row2, rowDiff);
            end
        end
    end
end

assert(height(executiveMatrix.imageMatrix) == height(executiveMatrix.finalMatrix), ...
    '❌ imageMatrix and finalMatrix row counts don’t match');
assert(all(~cellfun(@isempty, secondaryNames)), '❌ Empty image name(s) in SecondaryImageName');

% fprintf('\n✅ Sanity check complete!\n');
% fprintf('🔁 Duplicate image names checked: %d\n', numel(duplicateNames));
% fprintf('🎨 Too-close color index pairs: %d\n', tooCloseColorCount);
% fprintf('📏 Too-close row distance pairs: %d\n\n', tooCloseRowCount);

if tooCloseColorCount == 0 && tooCloseRowCount == 0
    % disp('🎉 All constraints satisfied. Your image matrix is clean.');
else
    % warning('⚠️ Some violations remain after fixing. Consider manual review.');
end

% The training phase images will be selected from the rejected
% images pool. 
trainingStimuliFiles = dir(fullfile(trainingStimuliDIR, '*.png'));
trainingStimuliPaths = fullfile({trainingStimuliFiles.folder}, {trainingStimuliFiles.name});

% Unique image indecies available. Is constant by design.  
trainingImageCount = 35;

% Randomize the training stimuli set
trainingStimuli = trainingStimuliPaths(:, randperm(trainingImageCount));

executiveMatrix.trainingMatrix = trainingMatrix;
executiveMatrix.trainingImageMatrix = trainingImageMatrix;

% Convert finalMatrix into a table with meaningful column names
executiveMatrix.trainingMatrix = table( ...
    trainingMatrix(:,1), ... % Repetition
    trainingMatrix(:,2), ... % Context Change Values
    trainingMatrix(:,3), ... % Primary Image Color Index
    trainingMatrix(:,4), ... % Secondary Image Color Index
    'VariableNames', { ...
        'Repetition', ...
        'ContextChange', ...
        'PrimaryImageColorIndex', ...
        'SecondaryImageColorIndex', ...
        });

% === Step 1: Copy existing imageMatrix ===
executiveMatrix.trainingImageMatrix = cell2table(trainingImageMatrix, ...
    'VariableNames', {'PrimaryImageName','SecondaryImageName'});

% === Step 2: Identify original primary and secondary images ===
originalPrimaryIndices = [1 7 13 19 25];
originalPrimaryImages = trainingStimuli(originalPrimaryIndices);

% Assign original primary images to first 30 rows, repeated 6x
trainingPrimaryImageNames = repelem(originalPrimaryImages, 6)';
executiveMatrix.trainingImageMatrix.PrimaryImageName(1:30) = trainingPrimaryImageNames;

% Define original secondary images (trainingStimuli with original primaries removed)
originalSecondaryImages = setdiff(trainingStimuli, originalPrimaryImages, 'stable');

% Assign them directly to rows 1–30 in SecondaryImageName
executiveMatrix.trainingImageMatrix.SecondaryImageName(1:30) = originalSecondaryImages';

% === Step 3: Fill remaining 30 rows (31:60) ===

% -- PRIMARY IMAGES: pick 5 random from original SECONDARY images --
rng('shuffle'); % for randomness
newPrimaryPool = originalSecondaryImages;
newPrimaryImages = datasample(newPrimaryPool, 5, 'Replace', false);
newPrimaryRepeated = repelem(newPrimaryImages, 6)';
executiveMatrix.trainingImageMatrix.PrimaryImageName(31:60) = newPrimaryRepeated;

% -- SECONDARY IMAGES: use remaining 25 secondary + 5 from original primaries --
remainingSecondaryPool = setdiff(originalSecondaryImages, newPrimaryImages, 'stable');
% Confirm there are 25 left
assert(numel(remainingSecondaryPool) == 25, 'Expected 25 secondary images left');

% Select 5 images from original primary set to fill up to 30
extraSecondaryImages = datasample(originalPrimaryImages, 5, 'Replace', false);

% Combine and shuffle
finalSecondaryPool = [remainingSecondaryPool, extraSecondaryImages];
finalSecondaryShuffled = finalSecondaryPool(randperm(numel(finalSecondaryPool)));

% Assign to SecondaryImageName (rows 31–60)
executiveMatrix.trainingImageMatrix.SecondaryImageName(31:60) = finalSecondaryShuffled;

trainingContext = [0 NaN NaN NaN 1 NaN 1 NaN NaN NaN 0 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
    1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN]';

executiveMatrix.trainingMatrix.ContextChange(1:60) = trainingContext(:)';


%% Now, all is set up and we can kick it off with training:
% EXPERIMENT PARAMETERS

% Background colors:
greenBackground = [135 174 116];
redBackground = [165 127 151];
backgroundColors = [greenBackground; redBackground];

trainingBackgroundIndex = randi([1,2]);

interTrialIntervalDuration = 0.300;

% Event durations (training):
encodingDurationTraining = 1.000;
retentionDurationTraining = 1.000;
testingDurationTraining = 4.000;
postResponseDurationTraining = 0.500;
interProbeDurationTraining = 1.000;
haltDurationTraining = 0;

% Event durations (practice):
encodingDurationPractice = 0.400;
retentionDurationPractice = 0.600;
testingDurationPractice = 4.000;
postResponseDurationPractice = 0.300;
interProbeDurationPractice = 0.600;
haltDurationPractice = 0;

% Practice Task Parameters
trainingAverageError = [];
errorPair = zeros(1,2);
passOnToExperiment = false;

instructionsMainTask = ['Welcome to the experiment!\n\n' ...
                'You will now see an object with a random color\n' ...
                'Please keep the object and its color in mind.\n\n' ...
                'When the object reappears in black and white\n' ...
                'Indicate its color by moving the mouse around the image\n' ...
                'You will have a few seconds to make your selection\n\n' ...
                'You will also receive feedback on your performance after your response\n' ...
                'Right after, another image will follow and be tested in the same way\n\n' ...
                'Press SPACE to start.'];

instructionsContextChange = ['Sometimes, the background color may also change.\n\n' ...
                'Your task is still to report the color of the images.\n\n' ...
                'Press SPACE to continue.'];

instructionsPractice = ['Well done!\n\n' ...
                'Lastly, you will go through another series at the speed of the actual experiment.\n\n' ...
                'If your average angular error is too high, you will need to repeat this part.\n\n' ...
                'Press SPACE to start the practice.'];

instructionsRepeatPractice = ['Your average angular error is too high!\n\n' ...
                'Press SPACE to repeat practice'];

instructionsMainPhaseStarts = ['Excellent!\n\n' ...
                'Training is over. You may begin with the actual experiment now.\n\n' ...
                'Good luck!\n\n' ...
                'Press SPACE to start the experiment.'];

probeTimeOut = 'Please respond quicker!';

breakTime1 = 'You have completed this block!';

breakTime2 = 'You can now take a break.';

breakTime3 = 'Press SPACE to move on to the next block';

terminateExperiment = ['You have reached the end of the experiment.\n\n' ... 
                        'Thank your for your participation.\n\n' ...
                        'Please notify the experimenter.\n\n'];

% Check true if you want to skip training
skipTraining = false;

if ~(skipTraining)    
    %% THE TRAINING 
    % Initialize the trial counters
    practice = 1;
    trainingTrial = 1;
    
    while trainingTrial <= 60
       
        if trainingTrial == 1
            % Draw formatted text, centered both horizontally and vertically
            Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
            DrawFormattedText(window, instructionsMainTask, 'center', 'center', instructionsTextColor);
        
            % Flip to show it
            Screen('Flip', window);
        
            % Wait for space key
            waitForSpace();
    
        elseif mod(trainingTrial, 6) == 1  || mod(trainingTrial,6) == 5
            
            if executiveMatrix.trainingMatrix.ContextChange(trainingTrial) == 1
                % If on a 5th repeititon, shift the context index to change the
                % background
                if trainingBackgroundIndex == 1
                    trainingBackgroundIndex = 2;
                elseif trainingBackgroundIndex == 2
                    trainingBackgroundIndex = 1;
                end
            end

            if trainingTrial == 5 
                Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
                % Draw formatted text, centered both horizontally and vertically
                DrawFormattedText(window, instructionsContextChange, 'center', 'center', instructionsTextColor);
            
                % Flip to show it
                Screen('Flip', window);
            
                % Wait for space key
                waitForSpace();
    
            elseif trainingTrial == 13
                % Draw formatted text, centered both horizontally and vertically
                Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
                DrawFormattedText(window, instructionsPractice, 'center', 'center', instructionsTextColor);
        
                % Flip to show it
                Screen('Flip', window);
        
                % If the training is over and the practice is beginning, engage the
                % new event durations. 
        
                encodingDurationTraining = encodingDurationPractice;
                retentionDurationTraining = retentionDurationPractice;
                testingDurationTraining = testingDurationPractice;
                postResponseDurationTraining = postResponseDurationPractice;
                interProbeDurationTraining = interProbeDurationPractice;
                haltDurationTraining = haltDurationPractice;
        
                % Wait for space key
                waitForSpace();
            end
        end
    
        %% FRAME 1: MEMORY DISPLAY 1
    
        % First, lay down a background     
        trainingBackground = backgroundColors(trainingBackgroundIndex, 1:3);
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
       
        % Then, make the current primary image into a texture
        [primaryImageLoad, ~ , primaryImageAlphaChannel] = imread(executiveMatrix.trainingImageMatrix.PrimaryImageName{trainingTrial});
    
        primaryImageLoad = imresize(primaryImageLoad, imageSize);
    
        currentPrimaryImageColorCode = executiveMatrix.trainingMatrix.PrimaryImageColorIndex(trainingTrial);
        
        % Convert the image to LAB only once to speed up color rotations:
        savedLab = colorspace('rgb->lab', primaryImageLoad);
    
        % Fetch the colour 
        currentPrimaryImageColorAsRGB = RotateImage(savedLab, currentPrimaryImageColorCode);
    
        primaryImageAlphaChannel = imresize(primaryImageAlphaChannel, [size(currentPrimaryImageColorAsRGB,1), size(currentPrimaryImageColorAsRGB,2)]);
    
        % Combine the color and the alpha channel
        currentPrimaryImageColorAsRGB(:,:,4)= primaryImageAlphaChannel;
    
        primaryImageAlphaChannel = imresize(primaryImageAlphaChannel, imageSize);
    
        % Project the colour onto the target     
        primaryImageColored = Screen('MakeTexture', window, currentPrimaryImageColorAsRGB);
    
        % Draw the selected texture to the screen
        Screen('DrawTexture', window, primaryImageColored, [], stimRect);
        
        % The moment the primary image is presented
        memoryDisplay1OnsetTraining = Screen('Flip', window);
    
        % Calculate when the image should be taken off the screen
        memoryDisplay1OffsetTraining = memoryDisplay1OnsetTraining + encodingDurationTraining - ifi / 2; 
    
        %% FRAME 2: RETENTION DISPLAY
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
    
        [~, retentionDisplay1OnsetTraining] = Screen('Flip', window, memoryDisplay1OffsetTraining);
        retentionDisplay1OffsetTraining = retentionDisplay1OnsetTraining + retentionDurationTraining - ifi / 2; 
    
        %% FRAME 3: MEMORY DISPLAY 2
        
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
    
        % Then, make the current primary image into a texture
        [secondaryImageLoad, ~ , secondaryImageAlphaChannel] = imread(executiveMatrix.trainingImageMatrix.SecondaryImageName{trainingTrial});
    
        secondaryImageLoad = imresize(secondaryImageLoad, imageSize);
    
        currentSecondaryImageColorCode = executiveMatrix.trainingMatrix.SecondaryImageColorIndex(trainingTrial);
        
        % Convert the image to LAB only once to speed up color rotations:
        savedLab = colorspace('rgb->lab', secondaryImageLoad);
    
        % Fetch the colour 
        currentSecondaryImageColorAsRGB = RotateImage(savedLab, currentSecondaryImageColorCode);
    
        secondaryImageAlphaChannel = imresize(secondaryImageAlphaChannel, [size(currentSecondaryImageColorAsRGB,1), size(currentSecondaryImageColorAsRGB,2)]);
    
        % Combine the color and the alpha channel
        currentSecondaryImageColorAsRGB(:,:,4)= secondaryImageAlphaChannel;
    
        secondaryImageAlphaChannel = imresize(secondaryImageAlphaChannel, imageSize);
    
        % Project the colour onto the target     
        secondaryImageColored = Screen('MakeTexture', window, currentSecondaryImageColorAsRGB);
    
        % Draw the selected texture to the screen
        Screen('DrawTexture', window, secondaryImageColored, [], stimRect);
    
        [~, memoryDisplay2OnsetTraining] = Screen('Flip', window, retentionDisplay1OffsetTraining);
        memoryDisplay2OffsetTraining = memoryDisplay2OnsetTraining + encodingDurationTraining - ifi / 2; 
       
        %% FRAME 4: RETENTION DISPLAY 2
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
    
        [~, retentionDisplay2OnsetTraining] = Screen('Flip', window, memoryDisplay2OffsetTraining);
        retentionDisplay2OffsetTraining = retentionDisplay2OnsetTraining + retentionDurationTraining - ifi / 2; 
    
        %% FRAME 5: PROBE DISPLAY
        for probeDisplay = 1:2
            
            if probeDisplay == 1
                % Increment the color wheel position by a random degree
                temp = Shuffle(0:45:315);
                randomAddition = temp(1);
            elseif probeDisplay == 2
                temp(1) = [];
                randomAddition = temp(1);
            end
        
            % Select which image to test
            if probeDisplay == 1
    
                errorPair = zeros(1,2);
               
                % If this is the first testing, test for the secondary image
                % Show in grayscale:
                    
                % Convert the image to LAB only once to speed up color rotations:
                savedLab = colorspace('rgb->lab', secondaryImageLoad);
    
                secondaryImageGray = repmat(mean(secondaryImageLoad,3), [1 1 3]);
                secondaryImageGray(:,:,4)=secondaryImageAlphaChannel;
    
                currentAlpha = secondaryImageAlphaChannel;
    
                curTexture = Screen('MakeTexture', window, secondaryImageGray);
    
                toBeTestedColorDegree = currentSecondaryImageColorCode;
    
                % If it is the first test, tie in from the pre-testing retention offset
                flipWhen = retentionDisplay2OffsetTraining;
                
            else
    
                % Convert the image to LAB only once to speed up color rotations:
                savedLab = colorspace('rgb->lab', primaryImageLoad);
    
                primaryImageGray = repmat(mean(primaryImageLoad,3), [1 1 3]);
                primaryImageGray(:,:,4)=primaryImageAlphaChannel;
    
                currentAlpha = primaryImageAlphaChannel;
    
                curTexture = Screen('MakeTexture', window, primaryImageGray);
                
                toBeTestedColorDegree = currentPrimaryImageColorCode;
          
                % If it is the second test, tie in from the inter-probe
                % retention offset
                flipWhen = interProbeIntervalOffsetTraining;
            end
            
            % Draw initial screen
            Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, curTexture, [], stimRect);
            Screen('FrameOval', window, [0 0 0], colorWheel.rect);
            
            % Show the probe in greyscale, mark the time
            [~, greyscaleOnset] = Screen('Flip', window, flipWhen);
            
            % Testing limit spans three seconds from probe onset  
            testingLimit = greyscaleOnset + testingDurationTraining;
            
            % Prepare for color selection
            SetMouse(centerX, centerY, window);
            [curX, curY] = GetMouse(window);
        
            % The probe stays grey in color until mouse onset. 
            % If timed out, the following color selection part will never kick off 
            while curX == centerX && curY == centerY && GetSecs < testingLimit
                [curX, curY] = GetMouse(window);
            end
        
            curAngle = NaN;  % store selection angle
            buttons = [];
        
            % Enter color-selection phase if still within time window
            while GetSecs < testingLimit && ~any(buttons)
                [curX, curY, buttons] = GetMouse(window);
                curAngle = GetPolarCoordinates(curX, curY, centerX, centerY);
                [dotX1, dotY1] = polar2xy(curAngle, colorWheel.radius-5, centerX, centerY);
                [dotX2, dotY2] = polar2xy(curAngle, colorWheel.radius+20, centerX, centerY);
        
                if (curAngle ~= toBeTestedColorDegree) && round(curAngle) ~= 0
                    newRgb = RotateImage(savedLab, round(curAngle) + randomAddition);
                    newRgb(:, :, 4) = currentAlpha;
                    Screen('Close', curTexture);
                    curTexture = Screen('MakeTexture', window, newRgb);
                end
        
                Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
                Screen('FrameOval', window, [0, 0, 0], colorWheel.rect);
                Screen('DrawLine', window, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
                Screen('DrawTexture', window, curTexture, [], stimRect);
                Screen('Flip', window);
                
                % --- Inside your main loop ---
                [~, ~, keys] = KbCheck;
                escKey = keys(KbName('ESCAPE'));
                
                if escKey
                    if isnan(escStartTime)
                        escStartTime = GetSecs; % mark when first pressed
                    elseif GetSecs - escStartTime >= 1  % held for at least 1 second
                        sca;
                        error('User quit');
                    end
                else
                    escStartTime = NaN; % reset if released
                end
            end
        
            % Close the probe texture
            Screen('Close', curTexture);

            % Set haltUntil as default for both cases
            haltUntil = testingLimit - ifi / 2;

            % If response is made before time-out, 
            % the post response screen will show feedback at time testing limit. 
            if any(buttons) && GetSecs < testingLimit

                % Marks the exact moment a mouse click is made
                decisionMade = GetSecs;

                % If selection is made before time-out, 
                % make sure the post response screen is not shown until teseting limit.   
                haltUntil = testingLimit - ifi / 2;
                
                % Wait for button release
                while any(buttons), [~, ~, buttons] = GetMouse(window); end

                %% FRAME 5.2: HALT SCREEN
                % If decision is made before the time limit, clear the
                % screen of the probe display until it's time to show the
                % feedback when the maximum test duration is reached. No
                % need for flip scheduling, as feedback is scheduled to
                % happen when the testingLimit is up. 

                Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
                Screen('Flip', window);

                %% FRAME 6: FEEDBACK 
    
                % Wrap angles to [0,360)
                toBeTestedColorDegree = mod(toBeTestedColorDegree, 360);
                curAngle = mod(curAngle + randomAddition, 360);
        
                % Compute angular disparity ([-180,180) range)
                angularDisparity = mod((toBeTestedColorDegree - curAngle) + 180, 360) - 180;
    
                errorPair(1,probeDisplay) = abs(angularDisparity);
        
                % Plaster the current background on the screen for the feedback
                Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
        
                % First line: Angular Disparity Rate
                disparityText = ['Angular Disparity Rate: ' num2str(round(abs(angularDisparity)))];
                % Measure the text bounding box
                textBounds = Screen('TextBounds', window, disparityText);
                
                % Compute width of the text
                textWidth = textBounds(3) - textBounds(1);
                
                % Adjust x position to center the text
                xCentered = centerX - textWidth / 2;

                % Adjust y position to center the text vertically (centerY)
                yCentered = centerY - (textBounds(4) - textBounds(2)) / 2;  % Use text height for centering
                
                % Now draw the text centered horizontally
                Screen('DrawText', window, disparityText, xCentered, (yCentered - 20), textColorPostResponse);
        
                % Second line: Feedback message
                if abs(angularDisparity) <= 5
                    feedbackText = 'Excellent!';
                elseif abs(angularDisparity) <= 15
                    feedbackText = 'Great!';
                elseif abs(angularDisparity) <= 25
                    feedbackText = 'Nice!';
                elseif abs(angularDisparity) <= 35
                    feedbackText = 'Not Bad';
                else
                    feedbackText = 'Could be better';
                end
        
                % Measure the text bounding box
                textBounds = Screen('TextBounds', window, feedbackText);
                
                % Compute width of the text
                textWidth = textBounds(3) - textBounds(1);
                
                % Adjust x position to center the text
                xCentered = centerX - textWidth / 2;

                % Adjust y position to center the text vertically (centerY)
                yCentered = centerY - (textBounds(4) - textBounds(2)) / 2;  % Use text height for centering
                
                % Now draw the text centered horizontally
                Screen('DrawText', window, feedbackText, xCentered, (yCentered + 20), textColorPostResponse);
        
                % Show feedback at time testing limit and keep it for 300 ms.
                [~, postResponseOnsetTraining] = Screen('Flip', window, haltUntil);
                postResponseOffsetTraining = postResponseOnsetTraining + postResponseDurationTraining - ifi / 2;
            
            else
                % If testing times out, the post response screen will show a 
                % time-out warning at time testing limit. 
    
                % No angular disp value could have been assigned. 
                angularDisparity = NaN;
                errorPair(1,probeDisplay) = abs(angularDisparity);
    
                % Put on the current background for the warning message. 
                Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);

                % Measure the text bounding box
                textBounds = Screen('TextBounds', window, probeTimeOut);
                
                % Compute width of the text
                textWidth = textBounds(3) - textBounds(1);
                
                % Adjust x position to center the text
                xCentered = centerX - textWidth / 2;

                % Adjust y position to center the text vertically (centerY)
                yCentered = centerY - (textBounds(4) - textBounds(2)) / 2;  % Use text height for centering
                
                % Now draw the text centered horizontally
                Screen('DrawText', window, probeTimeOut, xCentered, yCentered, textColorPostResponse);
    
                % Show the time-out warning at time testing limit for 300 ms. 
                [~, postResponseOnsetTraining] = Screen('Flip', window, max(0, haltUntil));
                postResponseOffsetTraining = postResponseOnsetTraining + postResponseDurationTraining - ifi / 2;
            end
      
            %% FRAME 7: INTER-PROBE INTERVAL 

            if probeDisplay == 1
                % If it's the first probe, commence the second probing. 
                Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
                [~, interProbeIntervalOnsetTraining] = Screen('Flip', window, postResponseOffsetTraining);
                interProbeIntervalOffsetTraining = interProbeIntervalOnsetTraining + interProbeDurationTraining - ifi / 2;      
            end
        end
    
        if practice >= 12 && practice <= 18
             
            % Store all error values in practice phase
            trainingAverageError(end+1:end+2) = errorPair(1,:);
    
            if practice == 18
                
                % How many probe screens was failed in practice? 
                numNaNs = sum(isnan(errorPair), 'all');
    
                % At the end of practice, take the mean of errors (ignore the
                % NaNs). 
                practiceAverageError = mean(trainingAverageError, 'omitnan');
    
                % If at least two probe tests were failed or the average error is above 30
                % Repeat practice
    
                if numNaNs >= 2 || practiceAverageError >= 30
    
                    Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
                    DrawFormattedText(window, instructionsRepeatPractice, 'center', 'center', instructionsTextColor);
                    
                    % Flip to show it
                    Screen('Flip', window);
                
                    % Wait for space key
                    waitForSpace();
    
                    % Rewind the trial flow back to the start of practice
                    practice = 13;
                    trainingTrial = trainingTrial + 1;      
                    trainingAverageError = [];
    
                    % Restart practice with an ITI
                    Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
                    Screen('Flip', window);
                    WaitSecs(interTrialIntervalDuration);
             
                    continue;
    
                elseif numNaNs < 2 && (practiceAverageError) <= 30
                    % If the average is below 30 with no more than two misses,
                    % we're good to move on to the main phase.

                    passOnToExperiment = true;
                end
            end
        end
    
        % If given the nod, break out of training. 
        if passOnToExperiment
           break;
        end
    
        % Increment the trial counter
        practice = practice + 1;

        % This counter is not reeled back to the beginning of the practice
        % unlike the other two, as this is a counter for the training cond.
        % matrix. 
        trainingTrial = trainingTrial + 1;
    
        %% FRAME 8: INTER-TRIAL INTERVAL
    
        % At the very end of the trial, close the generated textures for a
        % smoother script execution.
    
        Screen('Close', primaryImageColored);
        Screen('Close', secondaryImageColored);
    
        % At Probe 2 post screen offset, move on to the next trial through ITI.  
        Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
        Screen('Flip', window, postResponseOffsetTraining);
        WaitSecs(interTrialIntervalDuration);
        
    end
end

%% Set up main phase parameters

% Experiment Trial Count
numTrials = totalTrialCount;

% Event durations:
encodingDuration = 0.400;
retentionDuration = 0.600;
testingDuration = 4.000;
postResponseDuration = 0.300;
interTrialIntervalDuration = 0.300; 
interProbeDuration = 0.600;
haltDuration = 0;

% Pick an initial background
currentBackgroundIndex = randi([1,2]);

% Data to save:
participantNumber = zeros(totalTrialCount,1);
conditionUsed = zeros(totalTrialCount,1);

blockNumber = zeros(totalTrialCount,1);
trialCount = zeros(totalTrialCount,1);
repetition = zeros(totalTrialCount,1);

contextChangeValue = zeros(totalTrialCount,1);
currentContext = zeros(totalTrialCount,1);
primaryImageColor = zeros(totalTrialCount,1);
secondaryImageColor = zeros(totalTrialCount,1);

accuracyPerBlock = NaN(totalTrialCount,2);

accuracy1 = zeros(totalTrialCount,1);
mouseOnset1 = zeros(totalTrialCount,1);
decisionRT1 = zeros(totalTrialCount,1);
totalRT1 = zeros(totalTrialCount,1);

accuracy2 = zeros(totalTrialCount,1);
mouseOnset2 = zeros(totalTrialCount,1);
decisionRT2 = zeros(totalTrialCount,1);
totalRT2 = zeros(totalTrialCount,1);

breakTaken = NaN(totalTrialCount,1);
experimentalConditions = NaN(totalTrialCount, 1);

% Define the data matrix and preallocate some of the columns
outputMatrix = NaN(totalTrialCount,19);

        outputMatrix(:,1) = repmat(lastParticipantNumber,totalTrialCount,1); % 1st column: ID
        outputMatrix(:,2) = repmat(currentConditionNumber, totalTrialCount,1); % 2nd column: Cond File
        outputMatrix(:,3) = repelem((1:totalBlock)', trialPerBlock); % 3rd column: Block Num
        outputMatrix(:,4) = (1:totalTrialCount)'; % 4rd column: trial counter
        outputMatrix(:,5) = executiveMatrix.finalMatrix.Repetition(:);  % 5th column: repetition counter
        outputMatrix(:,6) = executiveMatrix.finalMatrix.ContextChange(:);  % 6th column: context change 
        % 7th column: Current Context RGB (only the first number) 
        % (added inside the trial loop).
        outputMatrix(:,8) = executiveMatrix.finalMatrix.PrimaryImageColorIndex(:); % 8th column: 1st image color index
        outputMatrix(:,9) = executiveMatrix.finalMatrix.SecondaryImageColorIndex(:); % 9th column: 2nd image color index
        % 10th column: Accuracy for Probe 1
        % 11th column: Mouse Onset time for Probe 1
        % 12th column: Decision Time for Probe 1
        % 13th column: Total RT (combined) for Probe 1
        % 14th column: Accuracy for Probe 2
        % 15th column: Mouse Onset time for Probe 2
        % 16th column: Decision Time for Probe 2
        % 17th column: Total RT (combined) for Probe 2
        outputMatrix(:,18) = breakTaken; % 18th column: Break time
        % (updated inside the loop)

        % Extract relevant columns for the exp. conditions column 
        repetition     = outputMatrix(:,5);
        contextChange  = outputMatrix(:,6);
        
        % Assign values based on specified conditions
        experimentalConditions(repetition == 1 & contextChange == 0) = 1;
        experimentalConditions(repetition == 1 & contextChange == 1) = 2;
        experimentalConditions(repetition == 5 & contextChange == 0) = 3;
        experimentalConditions(repetition == 5 & contextChange == 1) = 4;
        
        outputMatrix(:,19) = experimentalConditions; % 19th: Experimental Conditions 
        % (1: Rep 1, No Change; 2: Rep 1, Change; 3: Rep 5, No Change; 4: Rep 5, Change; NaN)


% Put this BEFORE your main loop so it is only defined once
escStartTime = NaN;

% Lead the participant into the actual experiment
Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
DrawFormattedText(window, instructionsMainPhaseStarts, 'center', 'center', instructionsTextColor);

% Flip to show it
Screen('Flip', window);

% Wait for space key
waitForSpace();

% Start the trial flow
for trial = 1:totalTrialCount
    
    %% FRAME 0: BREAK TIME / END OF BLOCK
     
    % If this is a block end
    if trial >= 2 && (outputMatrix(trial,3) ~= outputMatrix((trial-1),3))

        % Save the data in each block intermission. 

        % Save the data
        currentLabel = sprintf('imperil4dataID%d.mat', lastParticipantNumber);
        fullPath = fullfile(outputDest, currentLabel);
        save(fullPath, 'outputMatrix');

        % Save the workspace
        currentLabel = sprintf('imperil4workspaceID%d.mat', lastParticipantNumber);
        fullPath = fullfile(workspaceDest, currentLabel);
        save(fullPath);
        
        remainingBlocks = totalBlock - (outputMatrix((trial-1),3));
        averageBlockError = mean(accuracyPerBlock(:), 'omitnan'); 
        
        % Set the duration of the countdown in seconds
        countdownDuration = 180; 
        
        % Get the starting time
        startTimeBreak = GetSecs;
        
        % Main loop
        while GetSecs - startTimeBreak < countdownDuration
            
            % Check for key press
            [~, ~, keyCode] = KbCheck;
            
            % Only accept SPACE key to break
            if keyCode(KbName('space'))
            
                % Store how much break was taken
                outputMatrix(trial, 18) = (countdownDuration - timeRemaining);
            
                % Reset these parameters
                accuracyPerBlock = NaN(totalTrialCount,2);
                averageBlockError = 0;
            
                % Small pause before continuing
                WaitSecs(1);
            
                % Break out of the loop / move to next block
                break;
            end
        
            % Calculate remaining break time
            timeRemaining = countdownDuration - (GetSecs - startTimeBreak);
            
            % Convert time remaining to minutes and seconds
            minutesRemaining = floor(timeRemaining / 60);
            secondsRemaining = mod(floor(timeRemaining), 60);

            % Put up a grey background
            Screen('FillRect', window, [128 128 128], [0 0 screenWidth screenHeight]);

            % Draw formatted text, centered both horizontally and vertically
            DrawFormattedText(window, breakTime1, 'center', (centerY - 3 * lineSpacing), instructionsTextColor);
            
            DrawFormattedText(window, breakTime2, 'center', (centerY - 2 * lineSpacing), instructionsTextColor);

            DrawFormattedText(window, ...
                ['Average Error in This Block: ' num2str(averageBlockError, '%.0f') ' degrees'], ...
                'center', 'center', instructionsTextColor);
            
            DrawFormattedText(window, ['Remaining Blocks: ' num2str(remainingBlocks)], 'center', (centerY + lineSpacing), instructionsTextColor);

            DrawFormattedText(window, sprintf('Remaining Break Time: %02d:%02d', minutesRemaining, secondsRemaining), 'center', (centerY + 2 * lineSpacing), instructionsTextColor);
            
            DrawFormattedText(window, breakTime3, 'center', (centerY + 4 * lineSpacing), instructionsTextColor);
                
            % Flip screen
            Screen('Flip', window);
        end
    end

    %% FRAME 1: MEMORY DISPLAY 1
    
    % First, lay down a background of the chosen color
     
    % If this is not a context change trial, go on with the current context

    if executiveMatrix.finalMatrix.ContextChange(trial) ~= 1
        
        currentBackground = backgroundColors(currentBackgroundIndex, 1:3);
        currentContext(trial,1) = currentBackground(1);

        Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);

    % If this is a context change trial, switch over to the other
    % background
    else

        if currentBackgroundIndex == 1
            currentBackgroundIndex = 2;
        elseif currentBackgroundIndex == 2
            currentBackgroundIndex = 1;
        end

        currentBackground = backgroundColors(currentBackgroundIndex, 1:3);
        currentContext(trial,1) = currentBackground(1);

        Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
    end

    % Then, make the current primary image into a texture
    [primaryImageLoad, ~ , primaryImageAlphaChannel] = imread(executiveMatrix.imageMatrix.PrimaryImageName{trial});

    % Resize the image to the set size
    primaryImageLoad = imresize(primaryImageLoad, imageSize);

    currentPrimaryImageColorCode = executiveMatrix.finalMatrix.PrimaryImageColorIndex(trial);
    
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', primaryImageLoad);

    % Fetch the colour 
    currentPrimaryImageColorAsRGB = RotateImage(savedLab, currentPrimaryImageColorCode);

    % Resize the alpha channel
    primaryImageAlphaChannel = imresize(primaryImageAlphaChannel, [size(currentPrimaryImageColorAsRGB,1), size(currentPrimaryImageColorAsRGB,2)]);

    % Combine the color and the alpha channel
    currentPrimaryImageColorAsRGB(:,:,4)= primaryImageAlphaChannel;

    primaryImageAlphaChannel = imresize(primaryImageAlphaChannel, imageSize);

    % Project the colour onto the target     
    primaryImageColored = Screen('MakeTexture', window, currentPrimaryImageColorAsRGB);

    % Draw the selected texture to the screen
    Screen('DrawTexture', window, primaryImageColored);
    
    % Show the memory display
    memoryDisplay1Onset = Screen('Flip', window);
    % disp(GetSecs);

    memoryDisplay1Offset = memoryDisplay1Onset + encodingDuration - ifi / 2; 

    %% FRAME 2: RETENTION DISPLAY

    Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);

    [~, retentionDisplay1Onset] = Screen('Flip', window, memoryDisplay1Offset);
    % fprintf('Retention 1 %.3f seconds\n', retentionDisplay1Onset);

    retentionDisplay1Offset = retentionDisplay1Onset + retentionDuration - ifi / 2; 

    %% FRAME 3: MEMORY DISPLAY 2

    % Then, make the current primary image into a texture
    [secondaryImageLoad, ~ , secondaryImageAlphaChannel] = imread(executiveMatrix.imageMatrix.SecondaryImageName{trial});

    % Resize the secondary image to the set size
    secondaryImageLoad = imresize(secondaryImageLoad, imageSize);

    currentSecondaryImageColorCode = executiveMatrix.finalMatrix.SecondaryImageColorIndex(trial);
    
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', secondaryImageLoad);

    % Fetch the colour 
    currentSecondaryImageColorAsRGB = RotateImage(savedLab, currentSecondaryImageColorCode);

    % Resize the alpha channel
    secondaryImageAlphaChannel = imresize(secondaryImageAlphaChannel, [size(currentSecondaryImageColorAsRGB,1), size(currentSecondaryImageColorAsRGB,2)]);

    % Combine the color and the alpha channel
    currentSecondaryImageColorAsRGB(:,:,4)= secondaryImageAlphaChannel;

    % Resize again
    secondaryImageAlphaChannel = imresize(secondaryImageAlphaChannel, imageSize);

    % Project the colour onto the target     
    secondaryImageColored = Screen('MakeTexture', window, currentSecondaryImageColorAsRGB);

    % Draw the selected texture to the screen
    Screen('DrawTexture', window, secondaryImageColored);
  
    [~, memoryDisplay2Onset] = Screen('Flip', window, retentionDisplay1Offset);
    % fprintf('Memory 2 %.3f seconds\n', memoryDisplay2Onset);

    memoryDisplay2Offset = memoryDisplay2Onset + encodingDuration - ifi / 2; 
    
    %% FRAME 4: RETENTION DISPLAY 2
    Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);

    [~, retentionDisplay2Onset] = Screen('Flip', window, memoryDisplay2Offset);
    % fprintf('Retention 2 %.3f seconds\n', retentionDisplay2Onset);

    retentionDisplay2Offset = retentionDisplay2Onset + retentionDuration - ifi / 2; 

    %% FRAME 5: PROBE DISPLAY
    for probeDisplay = 1:2
        
        % Increment the color wheel position by a random degree
        temp=Shuffle(0:45:315);
        randomAddition=temp(1);
    
         % Select which image to test
        if probeDisplay == 1

            % If this is the first testing, test for the secondary image
            % Show in grayscale:
                
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', secondaryImageLoad);

            secondaryImageGray = repmat(mean(secondaryImageLoad,3), [1 1 3]);
            secondaryImageGray(:,:,4)=secondaryImageAlphaChannel;

            currentAlpha = secondaryImageAlphaChannel;

            curTexture = Screen('MakeTexture', window, secondaryImageGray);

            toBeTestedColorDegree = currentSecondaryImageColorCode;

            % If it is the first test, tie in from the pre-testing retention offset
            flipWhen = retentionDisplay2Offset;

        else

            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', primaryImageLoad);

            primaryImageGray = repmat(mean(primaryImageLoad,3), [1 1 3]);
            primaryImageGray(:,:,4)=primaryImageAlphaChannel;

            currentAlpha = primaryImageAlphaChannel;

            curTexture = Screen('MakeTexture', window, primaryImageGray);
            
            toBeTestedColorDegree = currentPrimaryImageColorCode;
 
            % If it is the second test, tie in from the inter-probe
            % retention offset
            flipWhen = interProbeIntervalOffset;
        end

        % Draw initial screen
        Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, curTexture, [], stimRect);
        Screen('FrameOval', window, [0 0 0], colorWheel.rect);
        
        % Show the probe in greyscale, mark the time
        [~, greyscaleOnset] = Screen('Flip', window, flipWhen);
        % fprintf('Grey %.3f seconds\n', greyscaleOnset);

        % Testing limit spans three seconds from probe onset  
        testingLimit = greyscaleOnset + testingDuration;
        
        % Prepare for color selection
        SetMouse(centerX, centerY, window);
        [curX, curY] = GetMouse(window);
   
        % The probe stays grey in color until mouse onset. 
        % If timed out, the following color selection part will never kick off 
        while curX == centerX && curY == centerY && GetSecs < testingLimit
            [curX, curY] = GetMouse(window);
        end
    
        % If not timed out, the first mouse movement has been made.
        if GetSecs < testingLimit
            % TIMESTAMP: The participant has made the first mouse movement. 
            firstMouseMovement = GetSecs();
            % fprintf('Mouse Onset %.3f seconds\n', firstMouseMovement);

            if probeDisplay == 1
                mouseOnset1(trial) = (firstMouseMovement - greyscaleOnset);
            elseif probeDisplay == 2
                mouseOnset2(trial) = (firstMouseMovement - greyscaleOnset);
            end
        else
            if probeDisplay == 1
                accuracy1(trial) = NaN;
                accuracyPerBlock(trial,1) = NaN;
                mouseOnset1(trial) = NaN;
                decisionRT1(trial) = NaN;
                totalRT1(trial) = NaN;
            elseif probeDisplay == 2
                accuracy2(trial) = NaN;
                accuracyPerBlock(trial,2) = NaN;
                mouseOnset2(trial) = NaN;
                decisionRT2(trial) = NaN;
                totalRT2(trial) = NaN;
            end
        end

        % Show object in correct color for current angle and wait for click:
        buttons = [];

        % Enter color-selection phase if still within time window
        while GetSecs < testingLimit && ~any(buttons)
            [curX, curY, buttons] = GetMouse(window);
            curAngle = GetPolarCoordinates(curX, curY, centerX, centerY);
            [dotX1, dotY1] = polar2xy(curAngle, colorWheel.radius-5, centerX, centerY);
            [dotX2, dotY2] = polar2xy(curAngle, colorWheel.radius+20, centerX, centerY);
    
            if (curAngle ~= toBeTestedColorDegree) && round(curAngle) ~= 0
                newRgb = RotateImage(savedLab, round(curAngle) + randomAddition);
                newRgb(:, :, 4) = currentAlpha;
                Screen('Close', curTexture);
                curTexture = Screen('MakeTexture', window, newRgb);
            end
    
            Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
            Screen('FrameOval', window, [0, 0, 0], colorWheel.rect);
            Screen('DrawLine', window, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
            Screen('DrawTexture', window, curTexture, [], stimRect);
            Screen('Flip', window);
    
            % --- Inside your main loop ---
            [~, ~, keys] = KbCheck;
            escKey = keys(KbName('ESCAPE'));
            
            if escKey
                if isnan(escStartTime)
                    escStartTime = GetSecs; % mark when first pressed
                elseif GetSecs - escStartTime >= 1  % held for at least 1 second
                    sca;
                    error('User quit');
                end
            else
                escStartTime = NaN; % reset if released
            end
        end
        
        % Close the probe texture
        Screen('Close', curTexture);
  
        % If response is made before time-out, 
        % the post response screen will show feedback at time testing limit. 
        if any(buttons) && GetSecs < testingLimit
            
            % Wait for button release
            while any(buttons), [~, ~, buttons] = GetMouse(window); end

            % TIMESTAMP: MOUSE CLICK - RESPONSE IS MADE
            % Marks the exact moment a mouse click is made
            decisionMade = GetSecs;
            % fprintf('Decision Made: %.3f seconds\n', decisionMade);

            % If selection is made before time-out, 
            % make sure the post response screen is not shown until teseting limit.   
            haltUntil = testingLimit - ifi / 2;

            %% FRAME 5.2: HALT SCREEN
            % If decision is made before the time limit, clear the
            % screen of the probe display until it's time to show the
            % feedback when the maximum test duration is reached. No
            % need for flip scheduling, as feedback is scheduled to
            % happen when the testingLimit is up. 

            Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
            [~, haltAt] = Screen('Flip', window);
            % fprintf('Halted At: %.3f seconds\n', haltAt);
    
            %% FRAME 6: FEEDBACK 

            % Wrap angles to [0,360)
            toBeTestedColorDegree = mod(toBeTestedColorDegree, 360);
            curAngle = mod(curAngle + randomAddition, 360);
    
            % Compute angular disparity ([-180,180) range)
            angularDisparity = mod((toBeTestedColorDegree - curAngle) + 180, 360) - 180;
            if probeDisplay == 1
                accuracy1(trial) = angularDisparity;
                accuracyPerBlock(trial,1) = abs(angularDisparity);
                decisionRT1(trial) = (decisionMade - firstMouseMovement);
                totalRT1(trial) = (decisionMade - greyscaleOnset);
            else
                accuracy2(trial) = angularDisparity;
                accuracyPerBlock(trial,2) = abs(angularDisparity);
                decisionRT2(trial) = (decisionMade - firstMouseMovement);
                totalRT2(trial) = (decisionMade - greyscaleOnset);
            end
    
            % Plaster the current background on the screen for the feedback
            Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
    
            % First line: Angular Disparity Rate
            disparityText = ['Angular Disparity Rate: ' num2str(round(abs(angularDisparity)))];
            % Measure the text bounding box
            textBounds = Screen('TextBounds', window, disparityText);
            
            % Compute width of the text
            textWidth = textBounds(3) - textBounds(1);
            
            % Adjust x position to center the text
            xCentered = centerX - textWidth / 2;
            
            % Adjust y position to center the text vertically (centerY)
            yCentered = centerY - (textBounds(4) - textBounds(2)) / 2;  % Use text height for centering
            
            % Now draw the text centered horizontally
            Screen('DrawText', window, disparityText, xCentered, (yCentered - 20), textColorPostResponse);
    
            % Second line: Feedback message
            if abs(angularDisparity) <= 5
                feedbackText = 'Excellent!';
            elseif abs(angularDisparity) <= 15
                feedbackText = 'Great!';
            elseif abs(angularDisparity) <= 25
                feedbackText = 'Nice!';
            elseif abs(angularDisparity) <= 35
                feedbackText = 'Not Bad';
            else
                feedbackText = 'Could be better';
            end

            % Measure the text bounding box
            textBounds = Screen('TextBounds', window, feedbackText);
            
            % Compute width of the text
            textWidth = textBounds(3) - textBounds(1);
            
            % Adjust x position to center the text
            xCentered = centerX - textWidth / 2;

            % Adjust y position to center the text vertically (centerY)
            yCentered = centerY - (textBounds(4) - textBounds(2)) / 2;  % Use text height for centering
            
            % Now draw the text centered horizontally
            Screen('DrawText', window, feedbackText, xCentered, (yCentered + 20), textColorPostResponse);
    
            % Show feedback at time testing limit and keep it for 300 ms.
            [~, postResponseOnset] = Screen('Flip', window, haltUntil);
            % fprintf('Post Response: %.3f seconds\n', postResponseOnset);
            postResponseOffset = postResponseOnset + postResponseDuration - ifi / 2;
        
        else
            % If testing times out, the post response screen will show a 
            % time-out warning at time testing limit. 

            if probeDisplay == 1
                accuracy1(trial) = NaN;
                accuracyPerBlock(trial,1) = NaN;
                decisionRT1(trial) = NaN;
                totalRT1(trial) = NaN;
            elseif probeDisplay == 2
                accuracy2(trial) = NaN;
                accuracyPerBlock(trial,2) = NaN;
                decisionRT2(trial) = NaN;
                totalRT2(trial) = NaN;
            end

            % Put on the current background for the warning message. 
            Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
            
            % Measure the text bounding box
            textBounds = Screen('TextBounds', window, probeTimeOut);
            
            % Compute width of the text
            textWidth = textBounds(3) - textBounds(1);
            
            % Adjust x position to center the text
            xCentered = centerX - textWidth / 2;

            % Adjust y position to center the text vertically (centerY)
            yCentered = centerY - (textBounds(4) - textBounds(2)) / 2;  % Use text height for centering
            
            % Now draw the text centered horizontally
            Screen('DrawText', window, probeTimeOut, xCentered, yCentered, textColorPostResponse);

            % Show the time-out warning at time testing limit for 300 ms. 
            [~, postResponseOnset] = Screen('Flip', window, max(0, haltUntil));
            % fprintf('Post Response: %.3f seconds\n', postResponseOnset);

            postResponseOffset = postResponseOnset + postResponseDuration - ifi / 2;
        end
        
        %% FRAME 7: INTER-PROBE INTERVAL 
        if probeDisplay == 1
            % If it's the first probe, commence the second probing. 
            Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
            [~, interProbeIntervalOnset] = Screen('Flip', window, postResponseOffset);
            % fprintf('IPI: %.3f seconds\n', interProbeIntervalOnset);

            interProbeIntervalOffset = interProbeIntervalOnset + interProbeDuration - ifi / 2;      
        end
    end

    % Save the trial-by-trial data before ITI
    outputMatrix(trial, 7) = currentContext(trial);
    outputMatrix(trial, 10:17) = [accuracy1(trial) mouseOnset1(trial) decisionRT1(trial) totalRT1(trial) ...
        accuracy2(trial) mouseOnset2(trial) decisionRT2(trial) totalRT2(trial)]; 
    
    %% FRAME 8: INTER-TRIAL INTERVAL

    % At the very end of the trial, close the generated textures for
    % smoother script execution.

    Screen('Close', primaryImageColored);
    Screen('Close', secondaryImageColored);

    % At Probe 2 post screen offset, move on to the next trial through ITI.  
    Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
    Screen('Flip', window, postResponseOffset);
    % disp(GetSecs);
    WaitSecs(interTrialIntervalDuration);
   
    % Save the last block data before ending the experiment
    if trial == totalTrialCount    
            % Save the data
            currentLabel = sprintf('imperil4dataID%d.mat', lastParticipantNumber);
            fullPath = fullfile(outputDest, currentLabel);
            save(fullPath, 'outputMatrix');

            % Save the workspace
            currentLabel = sprintf('imperil4workspaceID%d.mat', lastParticipantNumber);
            fullPath = fullfile(workspaceDest, currentLabel);
            save(fullPath);
    end

    % Time to loop back onto the next trial
end

Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
% Terminate the experiment
DrawFormattedText(window, terminateExperiment, 'center', 'center', instructionsTextColor);
% Flip to show it
Screen('Flip', window);
% Wait for space key
waitForSpace();
sca;




%% IN THE FINAL VERSION OF THE EXPERIMENT, THE SURPRISE PHASE HAS BEEN SCRAPPED

% % Lead the participant into the surprise task
% DrawFormattedText(window, leadInToSurprise, 'center', 'center', [128 128 128]);
% 
% % Flip to show it
% Screen('Flip', window);
% 
% % Wait for space key
% waitForSpace();
% 
% % Lead the participant into the surprise task
% DrawFormattedText(window, surpriseInstructions, 'center', 'center', [128 128 128]);
% 
% % Flip to show it
% Screen('Flip', window);
% 
% % Wait for space key
% waitForSpace();
% 
% for surpriseTrial = 1:120
% 
%     %% FRAME 0: IMAGE RANDOMIZATION
%     surpriseTargetImage = 0;
%     surpriseFoilImage = 0;
% 
%     % Position the images based on a random index. 
%     % 1 = position on the left 
%     % 2 = position on the right
%     surpriseDuo = [surpriseTargetImage surpriseFoilImage];           % two elements
%     surpriseLottery = randi(2);          % randomly pick 1 or 2 
% 
%     leftImageTexture = surpriseDuo(surpriseLottery);                   % chosen element
%     rightImageTexture = surpriseDuo(3 - (surpriseLottery));          % the unchosen element
% 
%     % When the positions are assigned, start drawing them on the screen
% 
%     Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);
%     Screen('DrawTexture', window, leftImageTexture, [], leftImagePosition);
%     Screen('DrawTexture', window, rightImageTexture, [], rightImagePosition);
% 
%     Screen('Flip', window);
% 
%     %% FRAME 1: RECOGNITION TASK
% 
%     % Lock down a response loop around the images until a response keyed in
%     while true
%     [keyIsDown, ~, keyCode] = KbCheck;
%         if keyIsDown
%             if keyCode(leftKey)
%                 if leftImageTexture == surpriseTargetImage
%                     trueOrFalse(surpriseTrial) = 1; % correct
%                 else
%                     trueOrFalse(surpriseTrial) = 2; % incorrect
%                     Screen('FillRect', window, [255 255 255]);
%                     DrawFormattedText(window, surpriseWarning, 'center', 'center', [255 0 0]);
%                     Screen('Flip', window);
%                     WaitSecs(2.5);
%                 end
% 
%                 break; % exit loop after left key handled
% 
%             elseif keyCode(rightKey)
%                 if rightImageTexture == surpriseTargetImage
%                     trueOrFalse(surpriseTrial) = 1; % correct
%                 else
%                     trueOrFalse(surpriseTrial) = 2; % incorrect
%                     Screen('FillRect', window, [255 255 255]);
%                     DrawFormattedText(window, surpriseWarning, 'center', 'center', [255 0 0]);
%                     Screen('Flip', window);
%                     WaitSecs(2.5);
%                 end
% 
%                 break; % exit loop after right key handled
%             end
%         end
%     end
% 
%     %% FRAME 2: PROBE DISPLAY
% 
%     % Increment the color wheel position by a random degree
%     temp=Shuffle(0:45:315);
%     randomAddition=temp(1);
% 
% 
% 
%     % Get the color degree of the probe image
%     toBeTestedColorDegree = 0;
% 
%     Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);
% 
%     curTexture = texHandlesThrice();
% 
%     Screen('DrawTexture', window, curTexture, [], stimRect);
% 
%     % Show color report circle:
% 
%     Screen('FrameOval', window, [0 0 0], colorWheel.rect);
% 
%     % TIMESTAMP: The probe display has appeared in greyscale.  
%     [~, greyscaleOnset] = Screen('Flip', window, retentionDisplay2Offset);
% 
%     % Center mouse
%     SetMouse(centerX,centerY,window);
% 
%     % Convert the image to LAB only once to speed up color rotations:
%     savedLab = colorspace('rgb->lab', originalImg);
% 
%     % Wait until the mouse moves:
%     [curX,curY] = GetMouse(window);
%     while (curX == centerX && curY == centerY)
%       [curX,curY] = GetMouse(window);
%     end
% 
%     % TIMESTAMP: The participant has made the first mouse movement. 
%     firstMouseMovement = GetSecs();
% 
%     % Show object in correct color for current angle and wait for click:
%     buttons = [];
% 
%     while ~any(buttons)  
% 
%       [curX,curY, buttons] = GetMouse(window);
%       curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
%       [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
%       [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
% 
% 
%       if (curAngle ~= toBeTestedColorDegree) && round(curAngle) ~= 0 
%         newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
%         newRgb(:,:,4)=alpha;
%         Screen('Close', curTexture);
%         curTexture = Screen('MakeTexture', window, newRgb);
%       end
% 
%       % Show stimulus:
% 
%       Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);
% 
%       % Draw frame and dot
%       Screen('FrameOval', window, [0,0,0], colorWheel.rect);
%       Screen('DrawLine', window, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
% 
%       Screen('DrawTexture', window, curTexture, [], stimRect);   
% 
%       Screen('Flip', window);
% 
%       % Allow user to quit on each frame:
%       [~,~,keys]=KbCheck;
%       if keys(KbName('q')) && keys(KbName('7'))
%         sca; error('User quit');
%       end
% 
%     end
% 
%     % TIMESTAMP: MOUSE CLICK - RESPONSE IS MADE
%     responseEnd = GetSecs;
% 
%     Screen('Close', curTexture);
% 
%     % Wait for release of mouse button
%     while any(buttons), [~,~,buttons] = GetMouse(window); end
% 
%     % Wrap angles to [0,360)
%     toBeTestedColorDegree = mod(toBeTestedColorDegree, 360);
%     curAngle = mod(curAngle + randomAddition, 360);
% 
%     % Compute angular disparity
%     angular_disparity = toBeTestedColorDegree - curAngle;
%     % Wrap to [-180,180)
%     angular_disparity = mod(angular_disparity + 180, 360) - 180;
%     angularDisparity(trial) = angular_disparity;
% 
%     % Time from probe onset to first movement
%     mouseOnsetDuration = mouseOnset - greyscaleOnset;
%     mouseOnset(trial) = mouseOnsetDuration;
% 
%     % Time from first movement to click
%     movementDuration = responseEnd - mouseOnset;
%     decisionTime(trial) = movementDuration;
% 
%     % Full response time (onset → click)
%     totalResponseTime = responseEnd - greyscaleOnset;
%     RTActual(trial) = totalResponseTime;
% 
% 
%     %% FRAME 3: FEEDBACK
%     Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);
% 
%     % First line: Angular Disparity Rate
%     disparityText = ['Angular Disparity Rate: ' num2str(round(abs(angular_disparity)))];
%     bounds = Screen('TextBounds', window, disparityText);
%     xPos = centerX - (bounds(3)-bounds(1))/2;
%     yPos = centerY - 100;  % start above center
%     Screen('DrawText', window, disparityText, xPos, yPos, textColor);
% 
%     % Second line: Feedback message
%     if abs(angular_disparity) <= 5
%         feedbackText = 'Excellent!';
%     elseif abs(angular_disparity) > 5 && abs(angular_disparity) <= 15
%         feedbackText = 'Great!';
%     elseif abs(angular_disparity) > 15 && abs(angular_disparity) <= 25
%         feedbackText = 'Nice!';
%     elseif abs(angular_disparity) > 25 && abs(angular_disparity) <= 35
%         feedbackText = 'Not Bad';
%     else
%         feedbackText = 'Could be better';
%     end
% 
%     bounds = Screen('TextBounds', window, feedbackText);
%     xPos = centerX - (bounds(3)-bounds(1))/2;
%     yPos = yPos + lineSpacing;  % below the first line
%     Screen('DrawText', window, feedbackText, xPos, yPos, textColor);
% 
%     [~, feedbackOnset] = Screen('Flip', window);
%     feedbackOffset = feedbackOnset + feedbackDuration - ifi / 2; 
% 
% 
% 
% end




















%%%%%%%%%%%%FUNTIONS USED%%%%%%%%%%%%%%

% ----------------------------------------------------------
function newRgb = RotateImage(lab, r)
    x = lab(:,:,2);
    y = lab(:,:,3);
    v = [x(:)'; y(:)'];
    vo = [cosd(r) -sind(r); sind(r) cosd(r)] * v;
    lab(:,:,2) = reshape(vo(1,:), size(lab,1), size(lab,2));
    lab(:,:,3) = reshape(vo(2,:), size(lab,1), size(lab,2));
    newRgb = (colorspace('lab->rgb', lab) .* 255);
end
% ----------------------------------------------------------
function [angle, radius] = GetPolarCoordinates(h,v,centerH,centerV)
  % get polar coordinates
  hdist   = h-centerH;
  vdist   = v-centerV;
  radius     = sqrt(hdist.*hdist + vdist.*vdist)+eps;
  
  % determine angle using cosine (hyp will never be zero)
  angle = acos(hdist./radius)./pi*180;
  
  % correct angle depending on quadrant
  angle(hdist == 0 & vdist > 0) = 90;
  angle(hdist == 0 & vdist < 0) = 270;
  angle(vdist == 0 & hdist > 0) = 0;
  angle(vdist == 0 & hdist < 0) = 180;
  angle(hdist < 0 & vdist < 0)=360-angle(hdist < 0 & vdist < 0);
  angle(hdist > 0 & vdist < 0)=360-angle(hdist > 0 & vdist < 0);
end

% ----------------------------------------------------------
function [x, y] = polar2xy(angle,radius,centerH,centerV)  
  x = round(centerH + radius.*cosd(angle));
  y = round(centerV + radius.*sind(angle));
end

%%%%%%%%%%%%FUNTIONS USED%%%%%%%%%%%%%%