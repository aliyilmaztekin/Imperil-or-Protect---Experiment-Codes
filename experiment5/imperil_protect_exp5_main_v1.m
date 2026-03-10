 %% Imperil or Protect - Experiment 5 - Eye Tracking Experiment Script
% First began: 15.11.2025 
% Coded by A.Y.

% Stage: Alpha - 17.12.2025 
% Stage: Beta - 20.12.2025
% Stage: V1 - 20.12.2025 

addpath('C:\Users\gamalab1\Desktop\Ali Yılmaztekin - Imperil 5');

% Ask for participant number
participantNumber = input('Enter participant number: ');

% Engage a condition matrix. Loop around at every 15th participant. 
currentConditionNumber = mod(participantNumber - 1, 15) + 1;

% Build the filename dynamically
currentCond = sprintf('imperil5cond%d.mat', currentConditionNumber);

% Build the full path
fileToLoad = fullfile(currentCond);

% Load the matrix.
load(fileToLoad);

%% SCREEN PARAMETERS

% Randomize the randomization seeds of every randomization function
% throughout the script
rng('shuffle');

% 0 = don't skip the screen sync tests; 1 = skip them
% Recommendation: to avoid stimulus timing errors, do the sync tests
Screen('Preference', 'SkipSyncTests', 0);

% How many monitors do you have?
monitor = max(Screen('Screens'));

% Open a window and get screen resolution parameters (windowRect) as well
% the window handle (window)
[window, windowRect] = Screen('OpenWindow', monitor);

% Some screen function related to image transparency 
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% To schedule your flips, you need to get your screen's refresh rate
ifi = Screen('GetFlipInterval', window); 

% Hide the cursor in the experiment
HideCursor(window);

% To get the screen resolution
centerX = round(windowRect(3)/2);
centerY = round(windowRect(4)/2);

% Stimulus dimensions
stim.size = 100;
stimRect = CenterRect([0 0 stim.size stim.size], windowRect);

% Define the offset distance from the center (e.g., half of the screen width divided by 2)
% xOffset = round(windowRect(3) / 10); % Quarter of the screen width
% yOffset = round(windowRect(3) / 10); % One sixth of the screen width

xOffset = 324; 
yOffset = 324;

% Horizontal encoding sites
stimRectLeft = CenterRectOnPointd([0 0 stim.size stim.size], centerX - xOffset, centerY);
stimRectRight = CenterRectOnPointd([0 0 stim.size stim.size], centerX + xOffset, centerY);
encodingSites = [stimRectLeft; stimRectRight];

% Vertical testing sites
stimRectUp = CenterRectOnPointd([0 0 stim.size stim.size], centerX, centerY - yOffset);
stimRectDown = CenterRectOnPointd([0 0 stim.size stim.size], centerX, centerY + yOffset);
testingSites = [stimRectUp; stimRectDown];

% The coordinate space
screenHeight=windowRect(4);
screenWidth=windowRect(3);

% Fixation cross
fixationHalfLength = 20;   % Half-length of each line 
fixationWidth = 2;    % Line thickness
fixationColor = [0 0 0]; 
xFixation = [-fixationHalfLength fixationHalfLength 0 0]; % X coordinates
yFixation = [0 0 -fixationHalfLength fixationHalfLength]; % Y coordinates
allCoords = [xFixation; yFixation];

outputDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - Imperil 5\outputFiles';
workspaceDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - Imperil 5\experimentWorkspace';
eyeOutputDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - Imperil 5\eyeData';

%% STIMILUS SELECTION

sketchesDIR = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - Imperil 5\context_images';
skecthesFiles = dir(fullfile(sketchesDIR, '*.png'));
skecthesPaths  = fullfile({skecthesFiles.folder}, {skecthesFiles.name});

% Randomly select training and experimental stimuli from the image pool
stimuliDIR = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - Imperil 5\testObjectsTransparentExp5';
stimuliFiles = dir(fullfile(stimuliDIR, '*.png'));
stimuliPaths = fullfile({stimuliFiles.folder}, {stimuliFiles.name});

nAvailableStimuli = numel(stimuliPaths);

% First, cut the training phase trials out of the condition matrix.

trainingMatrix = zeros(18,8);
trainingMatrix = conditionMatrix(end-17:end, :);

conditionMatrix(end-17:end, :) = [];

totalTrial = length(conditionMatrix);

if totalTrial == 576
    trialPerBlock = 36;
end

totalBlock = totalTrial/trialPerBlock; 

nExperimentalStimuli = totalTrial/6;
nTrainingStimuli = 3; 

% Randomly select experimental stimuli
experimentalStimulusIndices = randperm(nAvailableStimuli, nExperimentalStimuli);
experimentalStimulusPaths = stimuliPaths(experimentalStimulusIndices);

% Repeat each stimulus 6 times
experimentalStimuli = repelem(experimentalStimulusPaths', 6);

% Randomly select training stimuli from the remaining pool
remainingIndices = setdiff(1:nAvailableStimuli, experimentalStimulusIndices);
trainingStimulusIndices = randsample(remainingIndices, nTrainingStimuli);
trainingStimulusPaths = stimuliPaths(trainingStimulusIndices);

% Repeat each stimulus 6 times
trainingStimuli = repelem(trainingStimulusPaths',6);

% Parameters for drawing text on the feedback display & break screen
textSize = 30;
Screen('TextSize', window, textSize);
feedbackTextColor = [0 0 0]; % Black
instructionsTextColor = [255 255 255]; % White
lineSpacing = 40;

% Define keys to allow key presses
% Hold ESC down for at least 2 seconds during testing to quit PTB
KbName('UnifyKeyNames');

% Background colors:
greenContext = [135 174 116];
redContext = [165 127 151];
contextColors = [greenContext; redContext];
contextIndex = randi([1,2]);
currentContext = contextColors(contextIndex,:);

% Background images (for pilot testing)
background_pool = {'bg1.png', 'bg4.png', 'final3.png', 'final4.png'}; 
curBackgroundIndex = randi([1 4]);
% If there's a change command, first retrieve the curBackgroundIndex, then
% engage from the pool one of the two across-category alternatives. 
% So, if curIndex is one, randomly engage background 3 or 4. 
% Then update the current index, and repeat the process at next context
% change. 

% Feedback after probing
timeOutFeedback = 'Please respond quicker!';
wrongAnswerFeedback = 'Incorrect!';
correctAnswerFeedback = 'Correct!';

%% EYE-TRACKER PARAMETERS

% Do you want to use the eye-tracker? (1: yes, 0: no) 
eyeTrack = 1; % parameter to do eye tracking
eyeMode = 2; %(0: chin rest; 1:remote, 5-point calibration, 2: remote, 9-point calibration)

% This tries to establish contact with the eye-tracker. If it fails, the
% script will quit. 
if eyeTrack
    if EyelinkInit()~= 1 ; return ; end
end

% Specific settings for the eye-tracker 
if eyeTrack

    % First, initialize the eye-tracker with the default settings
    el=EyelinkInitDefaults(window); 

    % Second, if you want to change those default settings, enter them
    el.backgroundcolour = [128 128 128];    % The color of the calibration screen background
    el.calibrationtargetcolour = [0 0 0];  % The color of the calibration test targets
    el.msgfontcolour = [0 0 0];        % The color of the texts
    el.imgtitlecolour = [0 0 0];       % The color of the image title

    % Lastly, update the settings to the new ones
    EyelinkUpdateDefaults(el);             

    % Below, you're choosing the type of calibration test.
    
    % If eye mode is 0, you're doing a 9-point calibration test with the
    % chin rest.
    if eyeMode == 0
        Eyelink('command', 'elcl_select_configuration = MTABLER'); % chin rest
        Eyelink('command', 'calibration_type = HV9'); % 9-pt calibration

    % If eye mode is 1, you're doing a 5-point calibration test without the
    % chin rest.
    elseif eyeMode == 1
        Eyelink('command', 'elcl_select_configuration = RTABLER'); % remote mode
        Eyelink('command', 'calibration_type = HV5'); % 5-pt calibration

    % If eye mode is 2, you're doing a 9-point calibration test without the
    % chin rest.
    elseif eyeMode == 2
        Eyelink('command', 'elcl_select_configuration = BTOWER'); % remote mode
        Eyelink('command', 'calibration_type = HV9'); % 9-pt calibration
    end

    % Enter the stamp header that goes into the EDF file
    Eyelink('command', 'add_file_preamble_text','eyeData');

    % Set the eye recording resolutions based on your monitor's properties
    [width, height]=Screen('WindowSize', window);
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

    % Specify the types of data you want to extract from the recording
    % session
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');

    % set link data thtough link_sample_data and link_event_filter
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');

    % proportion commands to adjust size of calibrated area
    Eyelink('command', 'calibration_area_proportion 0.5 0.5')
    Eyelink('command', 'validation_area_proportion 0.5 0.5')

    % get host tracker version
    [v,vs]=Eyelink('GetTrackerVersion');
    
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    fprintf('Running experiment on version ''%d''.\n', v );
    
    % open file to record data to  
    edfFile = ['eye' num2str(participantNumber)];
    Eyelink('Openfile', edfFile);  

    % Allow the eye-tracker to play sounds, otherwise it won't run
    % calibration
    InitializePsychSound(1);
end

%% EVENT DURATIONS

% Trial events
itiDuration = 0.300;
habituationDuration = 1.000;
encodingDuration = 0.600;
delayDuration = 0.900;
testingDuration = 4.000;
feedbackDuration = 0.300;

% Fixation gate parameters
fixRadius = 50;      % fixation radius (in pixels)
holdTime  = 0.3;     % required fixation duration
maxWait = 15.0;      % time-out limit

%% OUTPUT MATRIX LAYOUT

% Define the data matrix and preallocate some of the columns
outputMatrix = NaN(totalTrial,15);
experimentalConditions = NaN(totalTrial,1);

    outputMatrix(:,1) = repmat(participantNumber,totalTrial,1); % 1st column: ID
    outputMatrix(:,2) = repmat(currentConditionNumber,totalTrial,1); % 2nd column: Condition File ID
    outputMatrix(:,3) = repelem((1:totalBlock)', trialPerBlock); % 3rd column: Block Number
    outputMatrix(:,4) = conditionMatrix(:,1);  % 4th column: trial counter
    outputMatrix(:,5) = conditionMatrix(:,2);  % 5th column: repetition counter
    outputMatrix(:,6) = conditionMatrix(:,3);  % 6th column: context change 
    % 7th column: Current Context RGB (only the first number) 
    outputMatrix(:,8) = conditionMatrix(:,4); % 8th column: Encoding site 
    outputMatrix(:,9) = conditionMatrix(:,5); % 9th column: Testing site
    outputMatrix(:,10) = conditionMatrix(:,6); % 10th column: Target angle
    outputMatrix(:,11) = conditionMatrix(:,7); % 11th column: Foil angle
    % 12th column: Accuracy
    % 13th column: Reaction Time

    % Extract relevant columns for the exp. conditions column 
    repetition     = conditionMatrix(:,2);
    contextChange  = conditionMatrix(:,3);

    % Assign values based on specified conditions
    experimentalConditions(repetition == 1 & contextChange == 0) = 1;
    experimentalConditions(repetition == 1 & contextChange == 1) = 2;
    experimentalConditions(repetition == 5 & contextChange == 0) = 3;
    experimentalConditions(repetition == 5 & contextChange == 1) = 4;

    outputMatrix(:,14) = experimentalConditions; % 14th: Experimental Conditions 
    % (1= Rep 1, No Change; 2= Rep 1, Change; 3= Rep 5, No Change; 4= Rep 5, Change) 

    % 15th column: Break time

%% TRAINING BEGINS

greetings =['Welcome to the experiment!\n\n' ...
    'You will now see an object tilted at a random angle\n' ...
    'Please keep the object and its orientation in mind\n\n' ...
    'You will then see two versions of the same image\n' ...
    'Please indicate which image is the studied one\n' ...
    'You will have a few seconds to make your selection']; 

enterContextChange =['Sometimes the background color may change\n' ...
    'Your task is still to indicate the correct image'];

enterCalibration = ['At the beginning of each block, you will be asked to do an eye calibration\n' ...
    'Simply follow the circles on the screen with your eyes\n' ...
    'You may be required to repeat the calibration if needed'];

enterFixationGate = ['To start each trial, you will need to perform a central fixation\n\n' ...
    'Please keep your gaze on the cross at the center of the screen\n' ...
    'Keep in mind that the trials will not begin until you do so\n\n' ...
    'However, you can move your eyes freely once the trial starts'];

terminateTraining = ['Excellent! The training is over\n\n' ...
    'You may begin the actual experiment now\n' ...
    'Good luck!\n\n' ...
    'Press SPACE to start'];

% Training length
instructionsDuration = 18;

% Check 'false' if you want to skip to the main phase
doTraining = false;

if doTraining
    for trainingTrial = 1:instructionsDuration
        
        % Display instructions at given trials
        if trainingTrial == 1
    
            % The trials don't include a fixation gate yet 
            enforceFixation = false;
    
            % Greet the participant & describe the task
            Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
            DrawFormattedText(window, greetings, 'center', 'center', instructionsTextColor);
            Screen('Flip', window);
            waitForSpace();
          
        elseif trainingTrial == 5
            
            % Introduce context change
            Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
            DrawFormattedText(window, enterContextChange, 'center', 'center', instructionsTextColor);
            Screen('Flip', window);
            waitForSpace();
    
        elseif trainingTrial == 7
    
            % Introduce eye-calibration
            Screen('FillRect', window, [128 128 128], [0 0 screenWidth screenHeight]);
            DrawFormattedText(window, enterCalibration, 'center', 'center', instructionsTextColor);
            Screen('Flip', window);  
            waitForSpace();
        
            if eyeTrack
    
                % Do eye calibration, repeat if error is too high
                calibrationOK = false;
    
                while ~calibrationOK
    
                    EyelinkDoTrackerSetup(el);
    
                    Screen('FillRect', window, [128 128 128]);
                    DrawFormattedText(window, ...
                        'Accept calibration?\n\nSPACE = accept\nR = recalibrate', ...
                        'center','center', instructionsTextColor);
                    Screen('Flip', window);
    
                    while true
                        [~,~,kc] = KbCheck;
                        if kc(KbName('SPACE'))
                            
                            % Proceed to the trial
                            calibrationOK = true;
                            
                            % Start recording AFTER calibration 
                            Eyelink('StartRecording');
                            WaitSecs(0.01);
                            break;
                        elseif kc(KbName('R'))
                            % Rerun eye-calibration
                            break;  
                        end
                    end
                end            
            end
    
        elseif trainingTrial == 13
            
            % No fixation gate if eye-tracker is not running
            if eyeTrack
                % Fixation gate open from now on
                enforceFixation = true;
            end
    
            % Introduce fixation gate
            Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
            DrawFormattedText(window, enterFixationGate, 'center', 'center', instructionsTextColor);
            Screen('Flip', window);
            waitForSpace();
            
        end
    
        %%% TRIAL FLOW:
    
        % Recording is on after trial 7:
    
        if trainingTrial >= 7
            if eyeTrack
                Eyelink('StartRecording');
                WaitSecs(0.01);
            end
        end
    
        % ITI:
    
        % Create and show the ITI screen. 
        Screen('FillRect', window, [128 128 128], [0 0 screenWidth screenHeight]);
        [~, itiOnset] = Screen('Flip', window);
        WaitSecs(itiDuration);
    
        % Fixation Gate:
        % Triggered to ask for central fixation after trial 7.

        % If this is a context change trial, present fixation with the new
        % context

        if trainingMatrix(trainingTrial, 3) == 1
            contextIndex = 3 - contextIndex;
            currentContext = contextColors(contextIndex,:);
        end
    
        if enforceFixation
            
            % Draw a fixation cross
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawLines', window, allCoords, fixationWidth, fixationColor, [centerX centerY], 2);
            [~, fixOnsetTime] = Screen('Flip', window);
    
            tFix = NaN;          % fixation made
    
            % Mark when the gate is entered
            gateStart = GetSecs;
    
            while true
    
                % Locate current gaze
                currentGaze = Eyelink('NewestFloatSample');
    
                % If fixation fails, re-calibrate
                if GetSecs - gateStart > maxWait
                    EyelinkDoTrackerSetup(el);
                    break;
                end
    
                if isempty(currentGaze) || currentGaze.time == 0
                    WaitSecs(0.001);
                    continue;
                end
    
                if currentGaze.gx(1) ~= el.MISSING_DATA && currentGaze.gy(1) ~= el.MISSING_DATA
                    currentDistance = hypot(currentGaze.gx(1) - centerX, ...
                        currentGaze.gy(1) - centerY);
                    if currentDistance < fixRadius
                        if isnan(tFix)
                            tFix = GetSecs;
                        elseif GetSecs - tFix >= holdTime
                            break;
                        end
                    else
                        tFix = NaN;
                    end
                end
                WaitSecs(0.001);
            end
        end
    
        % Context Habituation
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
    
        % Mark when the habituation display is shown
        [~, habituationOnset] = Screen('Flip', window);
    
        % Schedule a flip into the encoding display
        habituationOffset = habituationOnset + habituationDuration - ifi / 2; 
    
        % Encoding Screen
        if trainingMatrix(trainingTrial, 4) == 0
            currentEncodingSite = encodingSites(1,:);
            counterEncodingSite = encodingSites(2,:);
        elseif trainingMatrix(trainingTrial, 4) == 1
            currentEncodingSite = encodingSites(2,:);
            counterEncodingSite = encodingSites(1,:);
        end
        
        % Current rotation angle
        rotationAngle = trainingMatrix(trainingTrial, 6);
    
        [img, ~, alpha] = imread(trainingStimuli{trainingTrial});
    
        % Fix alpha range
        if ~isempty(alpha)
            alpha = uint8(alpha * 255);
        else
            alpha = 255 * ones(size(img,1), size(img,2), 'uint8');
        end
        
        gray = uint8(mean(img, 3));
        imgRGBA = cat(3, gray, gray, gray, alpha);
        
        memoryImageTexture = Screen('MakeTexture', window, imgRGBA);
    
        % Draw the texture at the destination rect (currentEncodingSite) with the rotation
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle, 0);
        
        % Flip the screen to present the image
        [~, encodingOnset] = Screen('Flip', window, habituationOffset);
    
        encodingOffset = encodingOnset + encodingDuration - ifi / 2;
    
        % DELAY PERIOD
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
    
        delayOnset = Screen('Flip', window, encodingOffset);
        delayOffset = delayOnset + delayDuration - ifi / 2;
    
        % PROBE SCREEN
    
        % That's rotation angle for the foil image 
        foilRotationAngle = trainingMatrix(trainingTrial, 7);
    
        if trainingMatrix(trainingTrial, 5) == 0
    
            currentTestingSite = testingSites(1,:);
            counterTestingSite = testingSites(2,:);
    
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, memoryImageTexture, [], currentTestingSite, rotationAngle);
            Screen('DrawTexture', window, memoryImageTexture, [], counterTestingSite, foilRotationAngle);
    
       elseif trainingMatrix(trainingTrial, 5) == 1
    
            currentTestingSite = testingSites(2,:);
            counterTestingSite = testingSites(1,:);
        
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, memoryImageTexture, [], currentTestingSite, rotationAngle);
            Screen('DrawTexture', window, memoryImageTexture, [], counterTestingSite, foilRotationAngle);
        end
        
        % Show the testing screen
        [~, probeOnset] = Screen('Flip', window, delayOffset);
    
        testingLimit = probeOnset + testingDuration;
    
        keyPressed = false;
        selectedSide = NaN;
            
        % 2AFC response loop
        while GetSecs < testingLimit && ~keyPressed
            [keyIsDown, ~, keyCode] = KbCheck;
        
            if keyIsDown
                if keyCode(KbName('UpArrow'))
                    % If "a" is keyed in, left half is chosen
                    selectedSide = 0;
                    % Break out of the response loop (when the response key
                    % is released).
                    keyPressed = true;
                    KbReleaseWait;
                elseif keyCode(KbName('DownArrow'))
                    % If "d" is keyed in, right half is chosen
                    selectedSide = 1;
                    keyPressed = true;
                    KbReleaseWait;
                elseif keyCode(KbName('Escape'))
                    Screen('CloseAll');
                end
            end
            WaitSecs(0.01);
        end
            
        % FEEDBACK
            
        % Put up the background
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        testingSite = trainingMatrix(trainingTrial, 5);
            
        % If testing was timed-out
        if ~keyPressed
    
            % Show the time-out warning
            DrawFormattedText(window, timeOutFeedback, 'center', 'center', instructionsTextColor);
           
        % If the response was correct
        elseif keyPressed && ...
          ((testingSite == 0 && selectedSide == 0) || ...
           (testingSite == 1 && selectedSide == 1))
    
            % Show positive feedback
            DrawFormattedText(window, correctAnswerFeedback, 'center', 'center', instructionsTextColor);
        
        % If the response was incorrect
        elseif keyPressed && ...
          ((testingSite == 0 && selectedSide == 1) || ...
           (testingSite == 1 && selectedSide == 0))
    
            % Show negative feedback
            DrawFormattedText(window, wrongAnswerFeedback, 'center', 'center', instructionsTextColor);          
        end
        
        % Show the feedback screen
        [~, feedbackOnset] = Screen('Flip', window);
        WaitSecs(feedbackDuration);
    
        % Close the study image texture at the end of the trial to save memory.
        Screen('Close', memoryImageTexture);
    
        % Stop recording at the end of the trial
        if trainingTrial >= 7
            if eyeTrack
                Eyelink('StopRecording');
            end
        end
    end
end

% END OF TRAINING

% Transition to main phase
Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
DrawFormattedText(window, terminateTraining, 'center', 'center', instructionsTextColor);
Screen('Flip', window);
waitForSpace();

% Instructions specific to the main phase
breakTime1 = 'End of block';
breakTime2 = 'You may now take a break.';
breakTime3 = 'Press SPACE for the next block';

terminateExperiment = ['You have completed the experiment.\n' ...
    'Thank you for your participation.\n\n' ...
    'Please notify the experimenter that you have finished.' ...
    ];

if eyeTrack
    % Note which context is the first in the main phase
    Eyelink('Message', 'MAIN_PHASE_START_CONTEXT %d', contextIndex);
end

%% THE MAIN PHASE BEGINS

% That's the trial counter. Gets updated dynamically inside the loop.  
liveTrial = 0;

for block = 1:totalBlock

    % End of the block screen, where people can take a break.

    % Save the behavioral data
    currentLabel = sprintf('imperil5dataID%d.mat', participantNumber);
    fullPath = fullfile(outputDest, currentLabel);
    save(fullPath, 'outputMatrix');

    % Save the MATLAB workspace
    currentLabel = sprintf('imperil5workspaceID%d.mat', participantNumber);
    fullPath = fullfile(workspaceDest, currentLabel);
    save(fullPath);

    % Some block info 
    curBlock = block;

    % Reset this variable once at each block for trial-by-trial
    % drift correction
    maxDrift = 100; 
    driftOffset = max(min(driftOffset, maxDrift), -maxDrift);

    if curBlock > 1

        remainingBlocks = totalBlock - curBlock;
    
        % Get the accuracy values this block
        blockResponses = outputMatrix(outputMatrix(:,3) == curBlock-1, 12);
    
        % Calculate performance percentage
        proportionCorrect = mean(blockResponses == 1, 'omitnan') * 100;

        % That's the break limit in seconds
        countdownLimit = 120; 
        startTimeBreak = GetSecs();
    
        % The break screen is up till time-out or self-initiation. 
        while GetSecs - startTimeBreak < countdownLimit
    
            % Check for key press
            [~, ~, keyCode] = KbCheck;
    
            % Calculate remaining break time
            timeRemaining = countdownLimit - (GetSecs - startTimeBreak);
    
            % If space key is pressed, terminate break. 
            if keyCode(KbName('space'))
                
                % Store how much break time was taken
                outputMatrix(liveTrial, 15) = (countdownLimit - timeRemaining);
    
                % Small pause before continuing
                WaitSecs(1);
    
                % Break out of the loop / move to next block
                break;
            end
    
            % Convert time remaining to minutes and seconds
            minutesRemaining = floor(timeRemaining / 60);
            secondsRemaining = mod(floor(timeRemaining), 60);
    
            % Pull up a gray background
            Screen('FillRect', window, [128 128 128], [0 0 screenWidth screenHeight]);
    
            % Draw info on the break display
            DrawFormattedText(window, breakTime1, 'center', (centerY - 3 * lineSpacing), instructionsTextColor);
            DrawFormattedText(window, breakTime2, 'center', (centerY - 2 * lineSpacing), instructionsTextColor);
            DrawFormattedText(window, ...
                ['Average Accuracy in This Block: ' num2str(proportionCorrect, '%.0f') ' %'], ...
                'center', 'center', instructionsTextColor);
    
            DrawFormattedText(window, ['Remaining Blocks: ' num2str(remainingBlocks)], 'center', (centerY + lineSpacing), instructionsTextColor);
            DrawFormattedText(window, sprintf('Remaining Break Time: %02d:%02d', minutesRemaining, secondsRemaining), 'center', (centerY + 2 * lineSpacing), instructionsTextColor);
            DrawFormattedText(window, breakTime3, 'center', (centerY + 4 * lineSpacing), instructionsTextColor);
    
            % Show the break screen
            Screen('Flip', window);
        end
    end

    % An eye calibration is needed before every block
    if eyeTrack

        % Do eye calibration, repeat if error is too high
        calibrationOK = false;
        
        while ~calibrationOK

            % Mark when calibration starts
            if eyeTrack
                Eyelink('Message', 'EYE_CALIBRATION_START');
            end

            EyelinkDoTrackerSetup(el);

            Screen('FillRect', window, [128 128 128]);
            DrawFormattedText(window, ...
                'Accept calibration?\n\nSPACE = accept\nR = recalibrate', ...
                'center','center', instructionsTextColor);
            Screen('Flip', window);

            while true
                [~,~,kc] = KbCheck;
                if kc(KbName('SPACE'))

                    % Proceed with the trial
                    calibrationOK = true;

                    if eyeTrack
                        Eyelink('Message', 'EYE_CALIBRATION_ACCEPTED');
                    end
                    
                    % Enter the trial loop below
                    break;
    
                elseif kc(KbName('R'))
                    % Rerun eye-calibration
                    if eyeTrack
                        Eyelink('Message', 'EYE_CALIBRATION_REDO');
                    end

                    break;  
                end
            end
        end            
    end
   

    % Trial loop begins
    for trial = 1:trialPerBlock

       %% At the beginning of each trial, start recording

       % Start recording at the beginning of each block
       if eyeTrack
           % Put tracker in idle mode before recording
           Eyelink('Command', 'set_idle_mode');

           % Operator display info
           Eyelink('command', ...
               'record_status_message ''BLOCK %d TRIAL %d''', block, trial);

           % Start recording
           Eyelink('StartRecording');

           % Give EyeLink a moment to start streaming
           WaitSecs(0.01);

           % Log trial identity
           Eyelink('Message', 'BLOCK %d', block);
           Eyelink('Message', 'TRIAL %d', trial);
       end


        %% Phase 0: Inter-Trial Interval (ITI)
        % Paint the background gray for a short time and start the trial

        % Create and show the ITI screen. 
        Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
        [~, itiOnset] = Screen('Flip', window);

        if eyeTrack
            Eyelink('Message', 'ITI_ON');
        end

        WaitSecs(itiDuration);

        % If it's a context-change trial, switch the background
        if conditionMatrix(liveTrial, 3) == 1
            contextIndex = 3 - contextIndex;
            currentContext = contextColors(contextIndex,:);
            outputMatrix(liveTrial, 7) = contextIndex;
        elseif conditionMatrix(liveTrial, 3) == 0
            currentContext = contextColors(contextIndex,:);
            outputMatrix(liveTrial, 7) = contextIndex;
        end

        % No fixation gate if the eye-tracker is offline
        if eyeTrack
            %% Phase 1: Fixation Gate
            % Ensure central fixation before the trial
    
                % Draw a fixation cross
                Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
                Screen('DrawLines', window, allCoords, fixationWidth, fixationColor, [centerX centerY], 2);
                [~, fixOnsetTime] = Screen('Flip', window);
        
                tFix = NaN;          % fixation made
        
                if eyeTrack
                    Eyelink('Message', 'FIX_ON');
                end
        
                fixEnterTime = NaN;
                gateStart = GetSecs;

                % For drift correction
                fixGazeX = [];
                fixGazeY = [];
        
                while true
        
                    % If fixation fails, re-calibrate
                    if GetSecs - gateStart > maxWait
                        EyelinkDoTrackerSetup(el);
                        break;
                    end
        
                    % Get the most recent eye sample from EyeLink
                    currentGaze = Eyelink('NewestFloatSample');
        
                    % Check that gaze data exist (not missing)
                    if currentGaze.gx(1) ~= el.MISSING_DATA && currentGaze.gy(1) ~= el.MISSING_DATA
        
                        % Compute distance between gaze and screen center
                        rawX = currentGaze.gx(1);
                        rawY = currentGaze.gy(1);
                        
                        corrX = rawX - driftOffset(1);
                        corrY = rawY - driftOffset(2);
                        
                        % The fixation is now corrected for drift
                        currentDistance = hypot(corrX - centerX, corrY - centerY);

                        % Check whether gaze is within fixation radius
                        if currentDistance < fixRadius
                        
                            if isnan(tFix)
                                % Fixation just started
                                tFix = GetSecs;
                        
                                % Initialize fixation sample buffers
                                fixGazeX = rawX;
                                fixGazeY = rawY;
                        
                                if isnan(fixEnterTime)
                                    fixEnterTime = tFix;
                        
                                    if eyeTrack
                                        Eyelink('Message', 'FIX_ENTERED');
                                        Eyelink('Message', sprintf('FIX_ORIENTATION_LATENCY %.3f', ...
                                            fixEnterTime - fixOnsetTime));
                                    end
                                end
                        
                            else
                                % Fixation is ongoing → keep collecting samples
                                fixGazeX(end+1) = rawX;
                                fixGazeY(end+1) = rawY;
                        
                                % If fixation has been held long enough, accept it
                                if GetSecs - tFix >= holdTime
                        
                                    % === ONLINE DRIFT CORRECTION ===
                                    meanFixX = mean(fixGazeX);
                                    meanFixY = mean(fixGazeY);
                        
                                    driftOffset = [meanFixX - centerX, ...
                                                   meanFixY - centerY];
                        
                                    if eyeTrack
                                        Eyelink('Message', 'FIX_ACCEPTED');
                                        Eyelink('Message', sprintf('DRIFT_OFFSET_UPDATED %.2f %.2f', ...
                                            driftOffset(1), driftOffset(2)));
                                    end
                        
                                    fixAcceptedTime = GetSecs;
                        
                                    if eyeTrack
                                        Eyelink('Message', sprintf('FIX_GATE_LATENCY %.3f', ...
                                            fixAcceptedTime - fixOnsetTime));
                                    end
                        
                                    break;  % Central fixation. Execute the trial
                                end
                            end
                        
                        else
                            % Gaze left fixation area → reset fixation timer and buffers
                            tFix = NaN;
                            fixGazeX = [];
                            fixGazeY = [];
                        end
                    end
        
                    % To help reduce CPU overload
                    WaitSecs(0.001);
                   
                end
        
                if eyeTrack
                    Eyelink('Message', 'FIX_OFF');
                end
        end

        % If the fixation gate has been passed, the trial is a go
        liveTrial = liveTrial + 1;

        if eyeTrack
            Eyelink('Message', 'TRIAL_START');
        end

        %% Phase 2: Context Habituation
        
        % Show the background without the stimulus
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);

        % Mark when the habituation display is shown
        [~, habituationOnset] = Screen('Flip', window);

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'HABITUATION_ON'); 
        end
        
        % Schedule a flip into the encoding display
        habituationOffset = habituationOnset + habituationDuration - ifi / 2; 

        %% Phase 3: Encoding Screen
        % Show a singular memory item rotated at a random orientation on one half of the screen
    
        % If value is 0, memory item is lateral to the left visual half.  
        % If value is 1, memory item is lateral to the right visual half. 
        % Counter-sites are for the upcoming probe screen. 

        if conditionMatrix(liveTrial, 4) == 0
            currentEncodingSite = encodingSites(1,:);
            counterEncodingSite = encodingSites(2,:);
        elseif conditionMatrix(liveTrial, 4) == 1
            currentEncodingSite = encodingSites(2,:);
            counterEncodingSite = encodingSites(1,:);
        end
    
        % Get the pre-determined rotation angle. 
        rotationAngle = conditionMatrix(liveTrial, 6);

        [img, ~, alpha] = imread(experimentalStimuli{liveTrial});

        % Fix alpha range
        if ~isempty(alpha)
            alpha = uint8(alpha * 255);
        else
            alpha = 255 * ones(size(img,1), size(img,2), 'uint8');
        end

        gray = uint8(mean(img, 3));
        imgRGBA = cat(3, gray, gray, gray, alpha);

        memoryImageTexture = Screen('MakeTexture', window, imgRGBA);

        % Draw the texture at the destination rect (currentEncodingSite) with the rotation
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle, 0);
        [~, encodingOnset] = Screen('Flip', window, habituationOffset);

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'ENCODING_ON'); 
        end

        encodingOffset = encodingOnset + encodingDuration - ifi / 2;

        %% Phase 4: Delay Period
        % Show the background without the stimulus
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        
        delayOnset = Screen('Flip', window, encodingOffset);
      
        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'DELAY_ON'); 
        end

        delayOffset = delayOnset + delayDuration - ifi / 2;

        %% Phase 5: Probe Screen
        % Show two copies of the study item on each half of the screen. 
        % One tilted at the original orientation, and the other at a slightly different one.
        % Ask a key press for the original orientation.

        % That's rotation angle for the foil image 
        foilRotationAngle = conditionMatrix(liveTrial, 7);

        % Draw probe screen
        % 0 = encoding site is consistent with its testing site
        % 1 = inconsistent

        if conditionMatrix(liveTrial, 5) == 0
            
            currentTestingSite = testingSites(1,:);
            counterTestingSite = testingSites(2,:);
    
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, memoryImageTexture, [], currentTestingSite, rotationAngle);
            Screen('DrawTexture', window, memoryImageTexture, [], counterTestingSite, foilRotationAngle);
        
        elseif conditionMatrix(liveTrial, 5) == 1

            currentTestingSite = testingSites(2,:);
            counterTestingSite = testingSites(1,:);
        
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, memoryImageTexture, [], currentTestingSite, rotationAngle);
            Screen('DrawTexture', window, memoryImageTexture, [], counterTestingSite, foilRotationAngle);
        end
        
        % Show the testing screen
        [~, probeOnset] = Screen('Flip', window, delayOffset);

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'TESTING_ON'); 
        end

        testingLimit = probeOnset + testingDuration;

        keyPressed = false;
        selectedSide = NaN;
        
        % 2AFC response loop
        while GetSecs < testingLimit && ~keyPressed
            [keyIsDown, ~, keyCode] = KbCheck;
            
            if keyIsDown
                
                % When an answer is given, first get the RT and save it
                responseTimePoint = GetSecs();
                reactionTime = responseTimePoint - probeOnset;
                outputMatrix(liveTrial, 13) = reactionTime;

                if keyCode(KbName('UpArrow'))
                    % If "a" is keyed in, left half is chosen
                    selectedSide = 0;
                    % Break out of the response loop (when the response key
                    % is released).
                    keyPressed = true;
                    KbReleaseWait;
                elseif keyCode(KbName('DownArrow'))
                    % If "d" is keyed in, right half is chosen
                    selectedSide = 1;
                    keyPressed = true;
                    KbReleaseWait;
                end
            end
            WaitSecs(0.01);
        end
        
        %% Phase 6: Feedback
        % Show appropriate feedback against the ongoing context
        
        % Put up the background
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);

        testingSite = conditionMatrix(liveTrial, 5);
        
        % If testing was timed-out
        if ~keyPressed
            % No need to save anything to the output matrix. 

            % Tell them to hurry up
            DrawFormattedText(window, timeOutFeedback, 'center', 'center', instructionsTextColor);
           
        % If the response was correct
        elseif keyPressed && ...
          ((testingSite == 0 && selectedSide == 0) || ...
           (testingSite == 1 && selectedSide == 1))
                
            % Save accuracy to the output matrix.
            outputMatrix(liveTrial, 12) = 1;

            % Tell them good job
            DrawFormattedText(window, correctAnswerFeedback, 'center', 'center', instructionsTextColor);
        
        % If the response was incorrect
        elseif  keyPressed && ...
          ((testingSite == 0 && selectedSide == 1) || ...
           (testingSite == 1 && selectedSide == 0))

            % Save accuracy to the output matrix.
            outputMatrix(liveTrial, 12) = 0;

            % Tell them to do better
            DrawFormattedText(window, wrongAnswerFeedback, 'center', 'center', instructionsTextColor);          
        end
        
        % Show the feedback screen
        [~, feedbackOnset] = Screen('Flip', window);
        WaitSecs(feedbackDuration);

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'FEEDBACK_ON'); 
        end

        % Close the study image texture at the end of the trial to save memory.
        Screen('Close', memoryImageTexture);

        if eyeTrack
            % Stop recording at the end of the block
            Eyelink('StopRecording');
        end
    end
end

% Save the eye data to the local computer
if eyeTrack
    Eyelink('StopRecording');        % (safeguard)
    Eyelink('Command', 'clear_screen 0');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    WaitSecs(0.5);
    Eyelink('ReceiveFile', edfFile, eyeOutputDest, 1);
    WaitSecs(0.5);
end

% Save the last block of behavioral data:
% Save the behavioral data
currentLabel = sprintf('imperil5dataID%d.mat', participantNumber);
fullPath = fullfile(outputDest, currentLabel);
save(fullPath, 'outputMatrix');

% Save the MATLAB workspace
currentLabel = sprintf('imperil5workspaceID%d.mat', participantNumber);
fullPath = fullfile(workspaceDest, currentLabel);
save(fullPath);

% The end of experiment screen
Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
DrawFormattedText(window, terminateExperiment, 'center', 'center', instructionsTextColor);
Screen('Flip', window);
waitForSpace();
sca;