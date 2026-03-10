%% Imperil or Protect - Experiment 5 - Eye Tracking Experiment Script
% First began: 15.11.2025 
% Coded by A.Y.

% Stage: Alpha - 17.12.2025 

% Ask for participant number
participantNumber = input('Enter participant number: ');

% Engage a condition matrix. Loop around at every 15th participant. 
currentConditionNumber = mod(participantNumber - 1, 15) + 1;

% Build the filename dynamically
currentCond = sprintf('imperil5cond%d.mat', currentConditionNumber);

% Build the full path
fileToLoad = fullfile(condFiles, currentCond);

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

% To get the coordinates for the encoding sites
topXleftHalf = round(windowRect(3)*(3/4));
topYleftHalf = round(windowRect(4)/2);

topXrightHalf = round(windowRect(3)*(9/4));
topYrightHalf = round(windowRect(4)/2);

% Stimulus dimensions
stim.size = 256;
stimRect = CenterRect([0 0 stim.size stim.size], windowRect);

% Define the offset distance from the center (e.g., half of the screen width divided by 2)
xOffset = round(windowRect(3) / 4); % Quarter of the screen width

% Left and right rectangles for the stimuli
stimRectLeft = CenterRectOnPointd([0 0 stim.size stim.size], centerX - xOffset, centerY);
stimRectRight = CenterRectOnPointd([0 0 stim.size stim.size], centerX + xOffset, centerY);
encodingSites = [stimRectLeft; stimRectRight];

% The coordinate space
screenHeight=windowRect(4);
screenWidth=windowRect(3);

outputDest = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil5\outputFiles';
workspaceDest = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil5\experimentWorkspace';

%% STIMILUS SELECTION

% Randomly select training and experimental stimuli from the image pool
stimuliDIR = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil5\testObjectsTransparent';
stimuliFiles = dir(fullfile(stimuliDIR, '*.png'));
stimuliPaths = fullfile({stimuliFiles.folder}, {stimuliFiles.name});

nAvailableStimuli = numel(stimuliPaths);

% First, cut the training phase trials out of the condition matrix.

trainingMatrix = zeros(18,8);
trainingMatrix = conditionMatrix(end-17:end, :);

conditionMatrix(end-17:end, :) = [];

totalTrial = length(conditionMatrix);

if totalTrial == 384
    trialPerBlock = 48;
end

totalBlock = totalTrial/trialPerBlock; 

nExperimentalStimuli = ((totalTrial/6)/2) + (totalTrial/2); 
nTrainingStimuli = 8; 

% Randomly select experimental stimuli
experimentalStimulusIndices = randperm(nAvailableStimuli, nExperimentalStimuli);
experimentalStimulusPaths = stimuliPaths(experimentalStimulusIndices);

% Randomly select training stimuli from the remaining pool
remainingIndices = setdiff(1:nAvailableStimuli, experimentalStimulusIndices);

trainingStimulusIndices = randsample(remainingIndices, nTrainingStimuli);
trainingStimulusPaths = stimuliPaths(trainingStimulusIndices);

% Extend the training and experimental image lists depending on their block
% type commands (whether a given image should be repeated or not).


trainingStimuli = strings(length(trainingMatrix),1);
outIdx = 1;

for i = 1:length(trainingStimulusPaths)
    if trainingMatrix(i,3) == 0
        % repeat this image 6 times
        trainingStimuli(outIdx:outIdx+5) = trainingStimulusPaths(i);
        outIdx = outIdx + 6;
    elseif trainingMatrix(i,3) == 1
        % repeat this image once
        trainingStimuli(outIdx) = trainingStimulusPaths(i);
        outIdx = outIdx + 1;
    end
end


experimentalStimuli = strings(totalTrial,1);
outIdx = 1;

for i = 1:length(experimentalStimulusPaths)
    if conditionMatrix(i,3) == 0
        experimentalStimuli(outIdx:outIdx+5) = experimentalStimulusPaths(i);
        outIdx = outIdx + 6;
    elseif conditionMatrix(i,3) == 1
        experimentalStimuli(outIdx) = experimentalStimulusPaths(i);
        outIdx = outIdx + 1;
    end
end


% Make each image this big (ADJUST AS NEEDED)
imageSize = [256 256];

% Parameters for drawing text on the feedback display & break screen
textSize = 30;
Screen('TextSize', window, textSize);
feedbackTextColor = [0 0 0]; % Black
instructionsTextColor = [255 255 255]; % White
lineSpacing = 40;

% Define keys to allow key presses
% Hold ESC down for at least 2 seconds during testing to quit PTB
KbName('UnifyKeyNames');
leftHalfKey = KbName('a');
rightHalfKey = KbName('d');

% Background colors:
greenContext = [135 174 116];
redContext = [165 127 151];
contextColors = [greenContext; redContext];
contextIndex = randi([1,2]);
currentContext = contextColors(contextIndex);

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
    el.backgroundcolour = gray;    % The color of the calibration screen background
    el.calibrationtargetcolour = black;  % The color of the calibration test targets
    el.msgfontcolour = black;        % The color of the texts
    el.imgtitlecolour = black;       % The color of the image title

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
    Eyelink('command', 'add_file_preamble_text','imperil5eyeData');

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
    edfFile = ['imp5eye.edf' num2str(participantNumber)];
    Eyelink('Openfile', edfFile);    

end

%% EVENT DURATIONS
itiDuration = 0.300;
habituationDuration = 1.000;
encodingDuration = 0.600;
delayDuration = 0.900;
testingDuration = 4.000;
feedbackDuration = 0.300;

%% OUTPUT MATRIX LAYOUT

% Define the data matrix and preallocate some of the columns
outputMatrix = NaN(totalTrial,16);
experimentalConditions = NaN(totalTrial,1);

    outputMatrix(:,1) = repmat(participantNumber,totalTrial,1); % 1st column: ID
    outputMatrix(:,2) = repmat(currentConditionNumber,totalTrial,1); % 2nd column: Condition File ID
    outputMatrix(:,3) = repelem((1:totalBlock)', trialPerBlock); % 3rd column: Block Number
    outputMatrix(:,4) = conditionMatrix(:,1); % 4th column: trial counter
    outputMatrix(:,5) = conditionMatrix(:,2);  % 5th column: repetition counter
    outputMatrix(:,6) = conditionMatrix(:,3);  % 6th column: block type
    outputMatrix(:,7) = conditionMatrix(:,4);  % 7th column: context change 
    % 8th column: Current Context RGB (only the first number) 
    outputMatrix(:,9) = conditionMatrix(:,5); % 9th column: Encoding site 
    outputMatrix(:,10) = conditionMatrix(:,6); % 10th column: Testing site
    outputMatrix(:,11) = conditionMatrix(:,7); % 11th column: Target angle
    outputMatrix(:,12) = conditionMatrix(:,8); % 12th column: Foil angle
    % 13th column: Accuracy
    % 14th column: Reaction Time

    % Extract relevant columns for the exp. conditions column 
    repetition     = conditionMatrix(:,2);
    blockType      = conditionMatrix(:,3);
    contextChange  = conditionMatrix(:,4);

    % Assign values based on specified conditions
    experimentalConditions(repetition == 1 & contextChange == 0 & blockType == 0) = 1;
    experimentalConditions(repetition == 1 & contextChange == 1 & blockType == 0) = 2;
    experimentalConditions(repetition == 5 & contextChange == 0 & blockType == 0) = 3;
    experimentalConditions(repetition == 5 & contextChange == 1 & blockType == 0) = 4;
    experimentalConditions(repetition == 1 & contextChange == 0 & blockType == 1) = 5;
    experimentalConditions(repetition == 1 & contextChange == 1 & blockType == 1) = 6;
    experimentalConditions(repetition == 5 & contextChange == 0 & blockType == 1) = 7;
    experimentalConditions(repetition == 5 & contextChange == 1 & blockType == 1) = 8;

    outputMatrix(:,15) = experimentalConditions; % 15th: Experimental Conditions 
    % (1= Rep 1, No Change; 2= Rep 1, Change; 3= Rep 5, No Change; 4= Rep 5, Change) 

    % 16th column: Break time


%% TRAINING BEGINS
greetings =['Welcome to the experiment!\n\n' ...
    'You will now see an object tilted at a random angle\n' ...
    'Please keep the object and its orientation in mind.\n\n' ...
    'You will then see two versions of the same image\n' ...
    'Please indicate which image is the studied one\n' ...
    'You will have a few seconds to make your selection\n\n' ...
    'Press SPACE to start.'];

enterContextChange =['Sometimes the background color may change\n' ...
    'Your task is still to indicate the correct image\n\n' ...
    'Press SPACE to continue'];

enterEyeTracking = ['Eye-tracking will now begin!\n\n' ...
    'Please keep your gaze on the cross at the center of the screen.\n' ...
    'Keep in mind that the trials will not begin until you do so.\n' ...
    'However, you can move your eyes freely once the trial starts\n\n' ...
    'Press SPACE to continue.'];

enterCalibration = ['At the beginning of each block, you will be asked to fixate on a circle for a few seconds.\n' ...
    'If this eye-check fails, you will have to do an eye-calibration\n' ...
    'In which case, simply follow the circles on the screen with your eyes\n'...
    'You may be required to repeat the calibration if needed\n\n'...
    'Press SPACE to continue.'];

terminateTraining = ['Excellent! The training is over.\n\n' ...
    'You may start the actual experiment now.\n' ...
    'Good luck!\n\n' ...
    'Press SPACE to start.'];

instructionsDuration = 18;

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

        enforceFixation = true;
    
        Screen('FillRect', window, [128 128 128], [0 0 screenWidth screenHeight]);
        DrawFormattedText(window, enterEyeTracking, 'center', 'center', instructionsTextColor);
        Screen('Flip', window);
        waitForSpace();
    
        if eyeTrack
            % First real calibration
            EyelinkDoTrackerSetup(el);
    
            % Start recording AFTER calibration
            Eyelink('StartRecording');
            WaitSecs(0.01);
        end

    elseif trainingTrial == 13
        
        % Teach eye calibration
        Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
        DrawFormattedText(window, enterCalibration, 'center', 'center', instructionsTextColor);
        Screen('Flip', window);
        waitForSpace();

        % Do a drift correction, and then a manual correction
        if eyeTrack
            % Demonstrate drift-correction
            EyelinkDoDriftCorrection(el, centerX, centerY, 1, 1);

            % Demonstrate manual calibration
            EyelinkDoTrackerSetup(el);
        end
        
        % Start recording again after calibration
        if eyeTrack
            Eyelink('StartRecording');
            WaitSecs(0.01);
        end
    end

    %%% TRIAL FLOW:

    % ITI:

    % Create and show the ITI screen. 
    Screen('FillRect', window, [128 128 128], [0 0 screenWidth screenHeight]);
    [~, itiOnset] = Screen('Flip', window);
    itiOffset = itiOnset + itiDuration - ifi / 2;

    % Fixation Gate:
    % Triggered to ask for central fixation after trial 7.

    if enforceFixation
        DrawFixation(window, centerX, centerY);
        [~, fixOnsetTime] = Screen('Flip', window, itiOffset);
        tFix = NaN;
        while true
            currentGaze = Eyelink('NewestFloatSample');
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
    if trainingMatrix(trainingTrial, 4) == 1
        contextIndex = 3 - contextIndex;
        currentContext = contextColors(contextIndex);
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
    else
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
    end

    % Mark when the habituation display is shown
    [~, habituationOnset] = Screen('Flip', window);

    % Schedule a flip into the encoding display
    habituationOffset = habituationOnset + habituationDuration - ifi / 2; 

    % Encoding Screen
    if trainingMatrix(trainingTrial, 5) == 0
        currentEncodingSite = encodingSites(1);
        counterEncodingSite = encodingSites(2);
    elseif trainingMatrix(trainingTrial, 5) == 1
        currentEncodingSite = encodingSites(2);
        counterEncodingSite = encodingSites(1);
    end

    % Current rotation angle
    rotationAngle = trainingMatrix(trainingTrial, 7);

    % Current memory image
    memoryImage = imread(trainingStimuli(trainingTrial));

    memoryImageGray = rgb2gray(memoryImage);
    memoryImageTexture = Screen('MakeTexture', window, memoryImageGray);
    Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
    Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle);

    [~, encodingOnset] = Screen('Flip', window, habituationOffset);
    encodingOffset = encodingOnset + encodingDuration - ifi / 2;

    % DELAY PERIOD
    Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);

    delayOnset = Screen('Flip', window, encodingOffset);
    delayOffset = delayOnset + delayDuration - ifi / 2;

    % PROBE SCREEN

    % That's rotation angle for the foil image 
    foilRotationAngle = trainingMatrix(trainingTrial, 8);

    if trainingMatrix(trainingTrial, 6) == 0
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle);
        Screen('DrawTexture', window, memoryImageTexture, [], counterEncodingSite, foilRotationAngle);
    elseif trainingMatrix(trainingTrial, 6) == 1
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, memoryImageTexture, [], counterEncodingSite, rotationAngle);
        Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, foilRotationAngle);
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
            if keyCode(KbName('a'))
                % If "a" is keyed in, left half is chosen
                selectedSide = 0;
                % Break out of the response loop (when the response key
                % is released).
                keyPressed = true;
                KbReleaseWait;
            elseif keyCode(KbName('d'))
                % If "d" is keyed in, right half is chosen
                selectedSide = 1;
                keyPressed = true;
                KbReleaseWait;
            end
        end
        WaitSecs(0.01);
    end
        
    % FEEDBACK
        
    % Put up the background
    Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
    testingSite = trainingMatrix(trainingTrial, 6);
        
    % If testing was timed-out
    if ~keyPressed

        % Show the time-out warning
        DrawFormattedText(window, timeOutFeedback, 'center', 'center', instructionsTextColor);
       
    % If the response was correct
    elseif (testingSite == 0 && selectedSide == 0) || ...
           (testingSite == 1 && selectedSide == 1)

        % Show positive feedback
        DrawFormattedText(window, correctAnswerFeedback, 'center', 'center', instructionsTextColor);
    
    % If the response was incorrect
    else
        % Show negative feedback
        DrawFormattedText(window, wrongAnswerFeedback, 'center', 'center', instructionsTextColor);          
    end
    
    % Show the feedback screen
    [~, feedbackOnset] = Screen('Flip', window);
    WaitSecs(feedbackDuration);

    % Close the study image texture at the end of the trial to save memory.
    Screen('Close', memoryImageTexture);

end

% END OF TRAINING

if eyeTrack
    Eyelink('StopRecording');
end

% Transition to main phase
Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
DrawFormattedText(window, terminateTraining, 'center', 'center', instructionsTextColor);
Screen('Flip', window);
waitForSpace();

% Instructions specific to the main phase
breakTime1 = 'End of block';
breakTime2 = 'You may now take a break.';
breakTime3 = 'Press SPACE to move on to the next block';

terminateExperiment = ['You have completed the experiment.\n' ...
    'Thank you for your participation.\n\n' ...
    'Please notify the experimenter that you have finished.' ...
    ];

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
    remainingBlocks = totalBlock - curBlock;

    % Get the accuracy values this block
    blockResponses = outputMatrix(outputMatrix(:,3) == curBlock, 12);

    % Calculate performance percentage
    proportionCorrect = (sum(blockResponses == 1, 'omitnan')/trialPerBlock)*100;

    % That's the break limit in seconds
    countdownLimit = 120; 
    startTimeBreak = GetSecs();

    % The break screen is up till time-out or self-initiation. 
    while GetSecs - startTimeBreak < countdownLimit

        % Check for key press
        [~, ~, keyCode] = KbCheck;

        % Calculate remaining break time
        timeRemaining = countdownLimit - (GetSecs - startTimeBreak);

        % If space key is pressed, terminate intermission. 
        if keyCode(KbName('space'))

            % Store how much break time was taken
            outputMatrix(liveTrial, 16) = (countdownLimit - timeRemaining);

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
            ['Average Error in This Block: ' num2str(proportionCorrect, '%.0f') ' %'], ...
            'center', 'center', instructionsTextColor);

        DrawFormattedText(window, ['Remaining Blocks: ' num2str(remainingBlocks)], 'center', (centerY + lineSpacing), instructionsTextColor);

        DrawFormattedText(window, sprintf('Remaining Break Time: %02d:%02d', minutesRemaining, secondsRemaining), 'center', (centerY + 2 * lineSpacing), instructionsTextColor);

        DrawFormattedText(window, breakTime3, 'center', (centerY + 4 * lineSpacing), instructionsTextColor);

        % Show the break screen
        Screen('Flip', window);
    end

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

    % A drift-correction is needed before every block
    % If the drift-correction error is too large, a full eye calibration is engaged.  

    if eyeTrack
        Eyelink('Message', 'DRIFT_CORRECTION_START');
    end
   
    if eyeTrack
        driftStatus = EyelinkDoDriftCorrection(el, centerX, centerY, 1, 1);
        if driftStatus ~= 0
            Eyelink('Message', 'DRIFT_CORRECTION_ABORTED');
            error('EyeLink drift correction aborted');
        end
    end

    if eyeTrack
        Eyelink('Message', 'DRIFT_CORRECTION_OK');
    end

    % Trial loop begins
    for trial = 1:trialPerBlock

        %% Phase 0: Inter-Trial Interval (ITI)
        % Paint the background gray for a short time and start the trial

        % Create and show the ITI screen. 
        Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
        [~, itiOnset] = Screen('Flip', window);
        itiOffset = itiOnset + itiDuration - ifi / 2;

        %% Phase 1: Fixation Reset
        % Ensure gaze is at the center to execute the trial

        fixRadius = 50;      % fixation radius in pixels
        holdTime  = 0.3;     % required fixation duration in seconds

        tFix = NaN;          % time when fixation started (unknown at first)

        DrawFixation(window, centerX, centerY);
        [~, fixOnsetTime] = Screen('Flip', window, itiOffset);

        if eyeTrack
            Eyelink('Message', 'FIX_ON');
        end

        fixEnterTime = NaN;

        while true
            % Get the most recent eye sample from EyeLink
            currentGaze = Eyelink('NewestFloatSample');

            % Check that gaze data exist (not missing)
            if currentGaze.gx(1) ~= el.MISSING_DATA && currentGaze.gy(1) ~= el.MISSING_DATA

                % Compute distance between gaze and screen center
                currentDistance = hypot(currentGaze.gx(1) - centerX, ...
                    currentGaze.gy(1) - centerY);

                % Check whether gaze is within fixation radius
                if currentDistance < fixRadius

                    if isnan(tFix)
                        tFix = GetSecs;
                    
                        if isnan(fixEnterTime)
                            fixEnterTime = tFix;
                    
                            if eyeTrack
                                Eyelink('Message', 'FIX_ENTERED');
                                Eyelink('Message', ...
                                    'FIX_ORIENTATION_LATENCY %.3f', fixEnterTime - fixOnsetTime);
                            end
                        end

                    % If fixation has been held long enough, accept it
                    elseif GetSecs - tFix >= holdTime
                        
                        if eyeTrack
                            Eyelink('Message', 'FIX_ACCEPTED');
                        end

                        fixAcceptedTime = GetSecs;
                        
                        if eyeTrack
                            Eyelink('Message', 'FIX_GATE_LATENCY %.3f', fixAcceptedTime - fixOnsetTime);
                        end

                        break;  % Central fixation. Execute the trial
                    end

                else
                    % Gaze left fixation area → reset fixation timer
                    tFix = NaN;
                end
            end

            % To help reduce CPU overload
            WaitSecs(0.001);
            
            % This is a fail-safe: If the drift-correction gets stuck,
            % engages calibration.
            if GetSecs - fixOnsetTime > 60
                EyelinkDoTrackerSetup(el);
            end
        end

        if eyeTrack
            Eyelink('Message', 'FIX_END');
        end
           
        % The actual trial counter
        liveTrial = liveTrial + 1;

        if eyeTrack
            Eyelink('Message', 'TRIAL_START_FIX_ACCEPTED');
        end

        %% Phase 2: Context Habituation
        % Show the background without the stimulus
    
        % If it's a context-change trial, switch the background
        if conditionMatrix(liveTrial, 3) == 1
            contextIndex = 3 - contextIndex;
            currentContext = contextColors(contextIndex);
            outputMatrix(liveTrial, 8) = contextIndex;
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        else
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        end
    
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
            currentEncodingSite = encodingSites(1);
            counterEncodingSite = encodingSites(2);
        elseif conditionMatrix(liveTrial, 4) == 1
            currentEncodingSite = encodingSites(2);
            counterEncodingSite = encodingSites(1);
        end
    
        % Get the pre-determined rotation angle. 
        rotationAngle = conditionMatrix(liveTrial, 6);
    
        % Get an image from the experimental stimuli pool
        memoryImage = imread(experimentalStimuli(liveTrial));
    
        % Convert to gray scale, make into texture, draw on the given half at
        % the given rotation tilt against the ongoing context. 
        memoryImageGray = rgb2gray(memoryImage);
        memoryImageTexture = Screen('MakeTexture', window, memoryImageGray);
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle);
    
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

        if conditionMatrix(liveTrial, 5)
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle);
            Screen('DrawTexture', window, memoryImageTexture, [], counterEncodingSite, foilRotationAngle);
        else
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
            Screen('DrawTexture', window, memoryImageTexture, [], counterEncodingSite, rotationAngle);
            Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, foilRotationAngle);
        end
        
        % Show the testing screen
        [~, probeOnset] = Screen('Flip', window);

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
                outputMatrix(liveTrial, 14) = reactionTime;

                if keyCode(KbName('a'))
                    % If "a" is keyed in, left half is chosen
                    selectedSide = 0;
                    % Break out of the response loop (when the response key
                    % is released).
                    keyPressed = true;
                    KbReleaseWait;
                elseif keyCode(KbName('d'))
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
        elseif (testingSite == 0 && selectedSide == 0) || ...
               (testingSite == 1 && selectedSide == 1)
            
            % Save accuracy to the output matrix.
            outputMatrix(liveTrial, 13) = 1;

            % Tell them good job
            DrawFormattedText(window, correctAnswerFeedback, 'center', 'center', instructionsTextColor);
        
        % If the response was incorrect
        else
            % Save accuracy to the output matrix.
            outputMatrix(liveTrial, 13) = 0;

            % Tell them to do better
            DrawFormattedText(window, wrongAnswerFeedback, 'center', 'center', instructionsTextColor);          
        end
        
        % Show the feedback screen
        [~, feedbackOnset] = Screen('Flip', window);

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'FEEDBACK_ON'); 
        end

        % Close the study image texture at the end of the trial to save memory.
        Screen('Close', memoryImageTexture);

        if eyeTrack && trial == trialPerBlock
            % Stop recording at the end of the block
            Eyelink('StopRecording');
        end
    end
end

%% Save the data in the last block: 
% Save the behavioral data
currentLabel = sprintf('imperil5dataID%d.mat', participantNumber);
fullPath = fullfile(outputDest, currentLabel);
save(fullPath, 'outputMatrix');

% Save the MATLAB workspace
currentLabel = sprintf('imperil5workspaceID%d.mat', participantNumber);
fullPath = fullfile(workspaceDest, currentLabel);
save(fullPath);