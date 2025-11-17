%% Imperil or Protect - Experiment 5 - Eye Tracking
% First began: 15.11.2025 
% Coded by A.Y.

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

% Some screen property related to image transparency 
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

nExperimentalStimuli = totalTrial/6; 
nTrainingStimuli = 10; 

% Randomly select experimental stimuli
experimentalStimulusIndices = randperm(nAvailableStimuli, nExperimentalStimuli);
experimentalStimulusPaths = stimuliPaths(experimentalStimulusIndices);
experimentalStimuli = repelem(experimentalStimuliPaths, 6);

% Randomly select training stimuli from the remaining pool
remainingIndices = setdiff(1:nAvailableStimuli, experimentalStimulusIndices);

trainingStimulusIndices = randsample(remainingIndices, nTrainingStimuli);
trainingStimulusPaths = stimuliPaths(trainingStimulusIndices);
trainingStimuli = repelem(trainingStimulusPaths, 6);


% Make each image this big
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
    EyeLinkDefaults=EyelinkInitDefaults(window); 

    % Second, if you want to change those default settings, enter them
    EyeLinkDefaults.backgroundcolour = gray;    % The color of the calibration screen background
    EyeLinkDefaults.calibrationtargetcolour = black;  % The color of the calibration test targets
    EyeLinkDefaults.msgfontcolour = black;        % The color of the texts
    EyeLinkDefaults.imgtitlecolour = black;       % The color of the image title

    % Lastly, update the settings to the new ones
    EyelinkUpdateDefaults(EyeLinkDefaults);             

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


%% OUTPUT MATRIX LAYOUT

% Define the data matrix and preallocate some of the columns
outputMatrix = NaN(totalTrial,15);
experimentalConditions = NaN(totalTrial,1);

    outputMatrix(:,1) = repmat(participantNumber,totalTrial,1); % 1st column: ID
    outputMatrix(:,2) = repmat(conditionFile,totalTrial,1); % 2nd column: Condition File ID
    outputMatrix(:,3) = repelem((1:totalBlock)', trialPerBlock); % 3rd column: Block Number
    outputMatrix(:,4) = (1:totalTrial)'; % 4th column: trial counter
    outputMatrix(:,5) = executiveMatrix.finalMatrix.Repetition(:);  % 5th column: repetition counter
    outputMatrix(:,6) = executiveMatrix.finalMatrix.ContextChange(:);  % 6th column: context change 
        outputMatrix(:,7) = "Context ID";  % 7th column: Current Context RGB (only the first number) 

        outputMatrix(:,8) = "Encoding Site"; 
        outputMatrix(:,9) = "Original Angle";
        outputMatrix(:,10) = "Testing Site";
        outputMatrix(:,11) = "Foil Angle";
    outputMatrix(:,12) = "Accuracy"; % 11th column: Accuracy
    outputMatrix(:,13) = "Reaction Time"; % 12th column: Reaction Time
    
    % Extract relevant columns for the exp. conditions column 
    repetition     = outputMatrix(:,5);
    contextChange  = outputMatrix(:,6);

    % Assign values based on specified conditions
    experimentalConditions(repetition == 1 & contextChange == 0) = 1;
    experimentalConditions(repetition == 1 & contextChange == 1) = 2;
    experimentalConditions(repetition == 5 & contextChange == 0) = 3;
    experimentalConditions(repetition == 5 & contextChange == 1) = 4;

    outputMatrix(:,14) = experimentalConditions; % 14th: Experimental Conditions 
    % (1= Rep 1, No Change; 2= Rep 1, Change; 3= Rep 5, No Change; 4= Rep 5, Change)

    outputMatrix(:,15) = "breakTaken"; % 15th column: Break time % (updated inside the loop)

% That's the trial counter. Gets updated dynamically inside the loop.  
liveTrial = 0;

%% THE TRIAL FLOW BEGINS

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
    curBlock = outputMatrix(liveTrial,3);
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

        % If space key is pressed, terminate intermission. 
        if keyCode(KbName('space'))

            % Store how much break time was taken
            outputMatrix(liveTrial, 15) = (countdownLimit - timeRemaining);

            % Small pause before continuing
            WaitSecs(1);

            % Break out of the loop / move to next block
            break;
        end

        % Calculate remaining break time
        timeRemaining = countdownLimit - (GetSecs - startTimeBreak);

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


    % The eye tracker needs to do calibration at the start of each block.
    % Start it with the termination of the break
    if eyeTrack
        EyelinkDoTrackerSetup(EyeLinkDefaults);
    end

    for trial = 1:trialPerBlock
        % The actual trial counter
        liveTrial = liveTrial + 1;

        %% Phase 1: Inter-Trial Interval (ITI)
        % Paint the background gray for a short time and start the trial

        % Create and show the ITI screen. 
        Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
        [~, itiOnset] = Screen('Flip', window);
        itiOffset = itiOnset + itiDuration - ifi / 2;

        % With the beginning of the ITI, tell the eye-tracker to start rolling the camera. 
        if eyeTrack
            % Put it to idle/offline mode before starting to record.
            Eyelink('Command', 'set_idle_mode');

            % Put block and trial number at the bottom of the operator display
            Eyelink('command', 'record_status_message ''BLOCK %d TRIAL %d''', block, trial)
            
            % Press record
            Eyelink('StartRecording')
            Eyelink('message', 'BLOCK %d ', block);
            Eyelink('message', 'TRIAL %d ', trial);
            
            % Mark zero-plot time in EDF file
            Eyelink('Message', 'ITI'); 
        end

        %% Phase 2: Context Habituation
        % Show the background without the stimulus
    
        % If it's a context-change trial, switch the background
        if outputMatrix(liveTrial, 6) == 1
            contextIndex = 3 - contextIndex;
            currentContext = contextColors(contextIndex);
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        else
            Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        end
    
        % Mark when the habituation display is shown
        [~, habituationOnset] = Screen('Flip', window, itiOffset);
        
        % Schedule a flip into the encoding display
        habituationOffset = habituationOnset + habituationDuration - ifi / 2; 
    
        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'Habituation Onset'); 
        end

        %% Phase 3: Encoding Screen
        % Show a singular memory item rotated at a random orientation on one half of the screen
    
        % If value is 0, memory item is lateral to the left visual half.  
        % If value is 1, memory item is lateral to the right visual half. 
        % Counter-sites are for the upcoming probe screen. 

        if outputMatrix(liveTrial, 8) == 0
            currentEncodingSite = encodingSites(1);
            counterEncodingSite = encodingSites(2);
        elseif outputMatrix(liveTrial, 8) == 1
            currentEncodingSite = encodingSites(2);
            counterEncodingSite = encodingSites(1);
        end
    
        % Get the pre-determined rotation angle. 
        rotationAngle = outputMatrix(liveTrial, 9);
    
        % Get an image from the experimental stimuli pool
        memoryImage = imread(experimentalStimuli(liveTrial));
    
        % Convert to gray scale, make into texture, draw on the given half at
        % the given rotation tilt against the ongoing context. 
        memoryImageGray = rgb2gray(memoryImage);
        memoryImageTexture = Screen('MakeTexture', window, memoryImageGray);
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, memoryImageTexture, [], currentEncodingSite, rotationAngle);
    
        [~, encodingOnset] = Screen('Flip', window, habituationOffset);
        encodingOffset = encodingOnset + encodingDuration - ifi / 2;

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'Encoding Onset'); 
        end

        %% Phase 4: Delay Period
        % Show the background without the stimulus
        Screen('FillRect', window, currentContext, [0 0 screenWidth screenHeight]);
        
        delayOnset = Screen('Flip', window, encodingOffset);
        delayOffset = delayOnset + delayDuration - ifi / 2;

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'Delay Onset'); 
        end

        %% Phase 5: Probe Screen
        % Show two copies of the study item on each half of the screen. 
        % One tilted at the original orientation, and the other at a slightly different one.
        % Ask a key press for the original orientation.

        % That's rotation angle for the foil image 
        foilRotationAngle = outputMatrix(liveTrial, 11);

        % Draw probe screen
        % 0 = encoding site is consistent with its testing site
        % 1 = inconsistent

        if outputMatrix(liveTrial, 12) == 0
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
        testingLimit = probeOnset + probeDuration;

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'Probe Onset'); 
        end

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

        testingSite = outputMatrix(liveTrial, 10);
        
        % If testing was timed-out
        if ~keyPressed
            % No need to save anything to the output matrix. 

            % Tell them to hurry up
            DrawFormattedText(window, timeOutFeedback, 'center', 'center', instructionsTextColor);
           
        % If the response was correct
        elseif (testingSite == 0 && selectedSide == 0) || ...
               (testingSite == 1 && selectedSide == 1)
            
            % Save accuracy to the output matrix.
            outputMatrix(liveTrial, 12) = 1;

            % Tell them good job
            DrawFormattedText(window, correctAnswerFeedback, 'center', 'center', instructionsTextColor);
        
        % If the response was incorrect
        else
            % Save accuracy to the output matrix.
            outputMatrix(liveTrial, 12) = 0;

            % Tell them to do better
            DrawFormattedText(window, wrongAnswerFeedback, 'center', 'center', instructionsTextColor);          
        end
        
        % Show the feedback screen
        [~, feedbackOnset] = Screen('Flip', window);
        feedbackOffset = feedbackOnset + feedbackDuration - ifi / 2;

        if eyeTrack
            % Send event trigger.
            Eyelink('Message', 'Feedback Onset'); 
            % End the eye recording at the end of every trial.
            Eyelink('StopRecording');
        end

        % Close the study image texture at the end of the trial to save memory.
        Screen('Close', memoryImageTexture);
    end
end