%% Protect or Imperil - Experiment 6 Code 
% Coded by A.Y.
% Conception - 21.04.2026 - v1.0
% V2 - 25.04.2026 
% Ready for data collection: 4.05.2026 
% V3 - design beta 20/05/2026 (ready for data)
% V4 - design gamma 22/05/2026 (ready for data)

%% Runing on what? Mark true:
aliscomputer = false;
experimentcomputer = true;
newexpcomputer = false;
gammacomputer = false;

% % Relevant directories given the computer handle
% if aliscomputer && ~(experimentcomputer) && ~(newexpcomputer)
%     condFiles = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/imperil6ConditionFilesV2';
%     condFilesTraining = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/imperil6conditionFilesTrainingV2';
%     stimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/TestObjectsTransparent'; 
%     trainingStimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/trainingStimuliExp6';
%     outputDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/outputFiles';
%     mouseDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/trackingFiles';
%     workspaceDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/experimentWorkspace';
%     subjectCountDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis';
% end
if ~aliscomputer && experimentcomputer && ~(newexpcomputer)
    condFiles = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\imperil6GammaConditionFiles';
    condFilesTraining = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\imperil6GammaConditionFilesTraining';
    stimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\testObjectsTransparentExtended';
    trainingStimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\trainingStimuliExp6';
    outputDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\outputFiles';
    mouseDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\trackingFiles';
    workspaceDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\experimentWorkspace';
    subjectCountDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma';
% elseif newexpcomputer && ~(experimentcomputer) && ~(aliscomputer)
%     condFiles = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil4\imperil4conditionFiles';
%     stimuliDIR = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil4\testObjectsTransparent';
%     trainingStimuliDIR = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil4\trainingStimuli';
%     outputDest = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil4\outputFiles';
%     workspaceDest = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil4\experimentWorkspace';
%     subjectCountDest = 'C:\Users\eeglab\Documents\MACC_lab\Ali Yilmaztekin\imperil4';
end
% 
% if gammacomputer
%     condFiles = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\imperil4conditionFiles';
%     condFilesTraining = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\imperil4conditionFilesTraining';
%     stimuliDIR = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\testObjectsTransparent';
%     trainingStimuliDIR = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\trainingStimuli';
%     outputDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\outputFiles';
%     workspaceDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\experimentWorkspace';
%     subjectCountDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\';
% end

% Ask for a participant number

% Load the last participant number (if the file exists)
if exist('imperil6Gammasubjectcount.mat', 'file')
    load('imperil6Gammasubjectcount.mat', 'lastParticipantNumber');
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
    save('imperil6Gammasubjectcount.mat', 'lastParticipantNumber');
    error('Participant counter reset to 0. Please restart the script and enter a new number.');
end

% Check that new number is not smaller than last
if participantNumber <= lastParticipantNumber
    error('Participant number must be greater than the last used (%d).', lastParticipantNumber);
end

% Save the new participant number for next time
lastParticipantNumber = participantNumber;
save(fullfile(subjectCountDest, 'imperil6Gammasubjectcount.mat'), 'lastParticipantNumber');


% Engage a condition file based on participant ID
currentConditionNumber = mod(lastParticipantNumber - 1, 15) + 1;

% Build the filename dynamically
currentCond = sprintf('imperil6Gammacond%d.mat', currentConditionNumber);
currentTrainingCond = sprintf('imperil6GammaTrainCond%d.mat', currentConditionNumber);

% Build the full path
fileToLoad = fullfile(condFiles, currentCond);
fileToLoadTraining = fullfile(condFilesTraining, currentTrainingCond);

% Load it
load(fileToLoad);  % The condition matrix
load(fileToLoadTraining); % The training matrix

% For good measure
rng('shuffle');

%% SCREEN PARAMETERS

% Skip invalid preference 'WindowedMode'
% Set whether to skip sync tests (0 means don't skip, run the tests)
Screen('Preference', 'SkipSyncTests', 1);

% Get the highest screen number (usually the external monitor or main display)
monitor = max(Screen('Screens'));

% Open a fullscreen window on the selected monitor with grey background
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
colorWheel.radius = 169; % 75% of the original 225
colorWheel.rect = CenterRect([0 0 colorWheel.radius*2 colorWheel.radius*2], windowRect);
stim.size = 192; % 75% of the original 256
stimRect = CenterRect([0 0 stim.size stim.size], windowRect);

% Set up the coordinate space
screenHeight=windowRect(4);
screenWidth=windowRect(3);
yAxis = 1:screenHeight - stim.size;
xAxis = 1:screenWidth - stim.size;

% Make each image this big
imageSize = [192 192]; % %60 of the usual 256x256 size  

% Memory array 1 presentation circle settings
% The memoranda will be drawn along this shape
memArray1.radius = 225; %60% of the original 300
memArray1.rect = CenterRect([0 0 memArray1.radius*2 memArray1.radius*2], windowRect);

baseRads = repelem(([0 90 180 270] * pi/180), size(conditionMatrix, 1), 1);
baseRadsTrain = repelem([0 90 180 270] * pi/180, size(trainingMatrix, 1), 1);

thetaRad = conditionMatrix(:,7)' * pi/180;
thetaRadTrain = trainingMatrix(:,7)' * pi/180;

rotatedRads = baseRads + thetaRad';
rotatedRadsTrain = baseRadsTrain + thetaRadTrain';

cx = (memArray1.rect(1) + memArray1.rect(3)) / 2;
cy = (memArray1.rect(2) + memArray1.rect(4)) / 2;

xCo = cx + memArray1.radius * cos(rotatedRads);
yCo = cy - memArray1.radius * sin(rotatedRads);

xCoTrain = cx + memArray1.radius * cos(rotatedRadsTrain);
yCoTrain = cy - memArray1.radius * sin(rotatedRadsTrain);

nTrials = size(conditionMatrix, 1);
nTrainTrials = size(trainingMatrix, 1);

mainRects = zeros(4, 4, nTrials);
trainRects = zeros(4, 4, nTrainTrials);

for trial = 1:nTrials
    for slot = 1:4
        mainRects(:,slot,trial) = CenterRectOnPoint([0 0 imageSize(2) imageSize(1)], ...
            xCo(trial,slot), yCo(trial,slot));
    end
end

for trial = 1:nTrainTrials
    for slot = 1:4
        trainRects(:,slot,trial) = CenterRectOnPoint([0 0 imageSize(2) imageSize(1)], ...
            xCoTrain(trial,slot), yCoTrain(trial,slot));
    end
end

%% Randomization of locations discontinued with design gamma
% % Randomize locations so that the repeated items don't appear adjacent
% % otherwise, they could be encoded as a chunk
% 
% % Randomize locations so that the repeated items don't appear adjacent
% 
% randSeqsMain = NaN(nTrials,4);
% 
% for trial = 1:nTrials
%     randSeqsMain(trial,:) = randperm(4);
% end
% 
% for trial = 1:nTrials
%     mainRects(:,:,trial) = mainRects(:, randSeqsMain(trial,:), trial);
% end
% 
% 
% randSeqsTrain = NaN(nTrainTrials,4);
% 
% for trial = 1:nTrainTrials
%     randSeqsTrain(trial,:) = randperm(4);
% end
% 
% for trial = 1:nTrainTrials
%     trainRects(:,:,trial) = trainRects(:, randSeqsTrain(trial,:), trial);
% end


% Parameters for drawing text on the feedback display & break screen
textSize = 30;
Screen('TextSize', window, textSize);
textColorPostResponse = [0 0 0];
instructionsTextColor = [255 255 255];
lineSpacing = 40;

% Define keys to allow key presses
% Hold ESC down for at least 2 seconds during testing to quit PTB
KbName('UnifyKeyNames');
escStartTime = NaN;

%% Now, all is set up and we can kick it off with training:
% EXPERIMENT PARAMETERS

% Background colors:
greenBackground = [135 174 116];
redBackground = [165 127 151];
backgroundColors = [greenBackground; redBackground];

trainingBackgroundIndex = randi([1,2]);

interTrialIntervalDuration = 0.300;

% Event durations (training):
habituationDurationTraining = 0.800;
encodingDurationTraining = 1.200;
retentionDurationTraining = 1.000;
testingDurationTraining = 4.000;
warningDurationTraining = 0.600;

% Event durations (practice):
habituationDurationPractice = 0.800;
encodingDurationPractice = 0.750;
retentionDurationPractice = 0.800;
testingDurationPractice = 4.000;
warningDurationPractice = 0.300;

% Practice Task Parameters
trainingAverageError = [];
errorPerSeries = NaN(size(trainingMatrix,1),1);
passOnToExperiment = false;

instructionsMainTask = ['Welcome to the experiment!\n\n' ...
                'You will now see four objects in random colors\n' ...
                'Please keep these objects and their colors in your mind\n\n' ...
                'Shortly after, one of these objects will be shown on the screen in black and white\n' ...
                'At that moment, your task is to recreate the color of the object\n' ...
                'To do so, rotate the mouse around the image as if making a circle\n' ...
                'Adjust the color wheel to the color in your mind and click to indicate your answer\n' ...
                'You will have a few seconds to make your selection\n\n'];

instructionsContextChange = ['Sometimes, the background color may also change\n\n' ...
                'Your task is still to report the color of the images\n\n'];

instructionsPractice = ['Well done!\n\n' ...
                'Lastly, you will go through another series at the speed of the actual experiment\n\n' ...
                'If your average angular error is too high, you may need to repeat this part\n\n'];

instructionsRepeatPractice = 'Practice failed. Please try again';

instructionsMainPhaseStarts = ['Excellent!\n\n' ...
                'Training is over. You may begin with the actual experiment now.\n\n' ...
                'Good luck!\n\n' ...
                'Press SPACE to start the experiment.'];

probeTimeOut = 'Please respond quicker!';

breakTime1 = 'You have completed this block!';

breakTime2 = 'You can now take a break.';

breakTime3 = 'Press SPACE to move on to the next block';

terminateExperiment = ['You have reached the end of the experiment.\n\n' ... 
                        'Thank you for your participation.\n\n' ...
                        'Please notify the experimenter.\n\n'];

% Check true if you want to skip training
skipTraining = false;

if ~(skipTraining)    
    %% THE TRAINING 
    % Initialize the trial counters
    practice = 1;
    trainingTrial = 1;

    % Allow average error in practice up to:
    errorThreshold = 60;

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
            
            if trainingMatrix(trainingTrial, 2) == 1
                % If on a 5th repetition, shift the context index to change the
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
        
                habituationDurationTraining = habituationDurationPractice;
                encodingDurationTraining = encodingDurationPractice;
                retentionDurationTraining = retentionDurationPractice;
                testingDurationTraining = testingDurationPractice;
                warningDurationTraining = warningDurationPractice;
                
                % Wait for space key
                waitForSpace();
            end
        end

        %% FRAME 1: CONTEXT HABITUATION

        % First, lay down a background     
        trainingBackground = backgroundColors(trainingBackgroundIndex, 1:3);
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);

        % Simply display it for the habituation duration 

        % The moment the context screen is shown
        habituationOnsetTraining = Screen('Flip', window);
    
        % Calculate when the memory display should appear
        habituationOffsetTraining = habituationOnsetTraining + habituationDurationTraining - ifi / 2; 
    
        %% FRAME 2: MEMORY DISPLAY 
        % Put on a background again    
        trainingBackground = backgroundColors(trainingBackgroundIndex, 1:3);
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
       
        % First, load the three repeated items
        [load1, ~ , load1alpha] = imread(trainingImageMatrix{trainingTrial,1});
        [load2, ~ , load2alpha] = imread(trainingImageMatrix{trainingTrial,2});
        [load3, ~ , load3alpha] = imread(trainingImageMatrix{trainingTrial,3});
    
        load1 = imresize(load1, imageSize);
        load2 = imresize(load2, imageSize);
        load3 = imresize(load3, imageSize);
    
        load1color = trainingMatrix(trainingTrial, 3);
        load2color = trainingMatrix(trainingTrial, 4);
        load3color = trainingMatrix(trainingTrial, 5);

        % Convert the image to LAB only once to speed up color rotations:
        savedLab1 = colorspace('rgb->lab', load1);
        % Convert the image to LAB only once to speed up color rotations:
        savedLab2 = colorspace('rgb->lab', load2);
        % Convert the image to LAB only once to speed up color rotations:
        savedLab3 = colorspace('rgb->lab', load3);
    
        % Fetch the color 
        load1colorRGB = RotateImage(savedLab1, load1color);
        load2colorRGB = RotateImage(savedLab2, load2color);
        load3colorRGB = RotateImage(savedLab3, load3color);
    
        load1alpha = imresize(load1alpha, [size(load1colorRGB,1), size(load1colorRGB,2)]);
        load1colorRGB(:,:,4)= load1alpha;
        load1alpha = imresize(load1alpha, imageSize);

        load2alpha = imresize(load2alpha, [size(load2colorRGB,1), size(load2colorRGB,2)]);
        load2colorRGB(:,:,4)= load2alpha;
        load2alpha = imresize(load2alpha, imageSize);

        load3alpha = imresize(load3alpha, [size(load3colorRGB,1), size(load3colorRGB,2)]);
        load3colorRGB(:,:,4)= load3alpha;
        load3alpha = imresize(load3alpha, imageSize);

        % Paint the objects     
        im1colored = Screen('MakeTexture', window, load1colorRGB);
        im2colored = Screen('MakeTexture', window, load2colorRGB);
        im3colored = Screen('MakeTexture', window, load3colorRGB);
    
        % Draw the memory objects on the screen
        Screen('DrawTexture', window, im1colored, [], trainRects(:,1, trainingTrial));
        Screen('DrawTexture', window, im2colored, [], trainRects(:,2, trainingTrial));
        Screen('DrawTexture', window, im3colored, [], trainRects(:,3, trainingTrial));

        % Next, load the singular novel memory item
        [load4, ~ , load4alpha] = imread(trainingImageMatrix{trainingTrial, 4});
        load4 = imresize(load4, imageSize);
        load4color = trainingMatrix(trainingTrial, 6);
        
        % Convert the image to LAB only once to speed up color rotations:
        savedLab4 = colorspace('rgb->lab', load4);
    
        % Fetch the color 
        load4colorRGB = RotateImage(savedLab4, load4color);
    
        load4alpha = imresize(load4alpha, [size(load4colorRGB,1), size(load4colorRGB,2)]);
    
        % Combine the color and the alpha channel
        load4colorRGB(:,:,4)= load4alpha;
        load4alpha = imresize(load4alpha, imageSize);
    
        % Paint the image     
        im4colored = Screen('MakeTexture', window, load4colorRGB);
    
        % Draw the selected texture onto the screen
        Screen('DrawTexture', window, im4colored, [], trainRects(:,4, trainingTrial));

        % Mark when the encoding screen comes on
        [~, memoryDisplayOnsetTraining] = Screen('Flip', window, habituationOffsetTraining);
    
        % Calculate when retention should start
        memoryDisplayOffsetTraining = memoryDisplayOnsetTraining + encodingDurationTraining - ifi / 2; 
    
        %% FRAME 3: RETENTION DISPLAY
        % Background
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
    
        % Begin the delay period and prepare for the probe display onset
        [~, retentionDisplayOnsetTraining] = Screen('Flip', window, memoryDisplayOffsetTraining);
        retentionDisplayOffsetTraining = retentionDisplayOnsetTraining + retentionDurationTraining - ifi / 2; 
    
        %% FRAME 4: PROBE DISPLAY
         
        % Increment the color wheel position by a random degree each time
        temp = Shuffle(0:45:315);
        randomAddition = temp(1);

        % Index of the item to be tested
        testItem = trainingMatrix(trainingTrial,8);

        % If idx is 4, test the novel item
        if testItem == 4
            % Borrow image assets created at encoding and reuse here
              
            probeLoad = load4;
            probeAlpha = load4alpha;
            probeColor = load4color;
        
        % If test item idx is 1, 2 or 3, probe the corresponding repeated item
        elseif testItem == 1
                probeLoad = load1;
                probeAlpha = load1alpha;
                probeColor = load1color;
        elseif testItem == 2
                probeLoad = load2;
                probeAlpha = load2alpha;
                probeColor = load2color;
        elseif testItem == 3
                probeLoad = load3;
                probeAlpha = load3alpha;
                probeColor = load3color;
        end
        
        % Show the tested item in greyscale 
        probeLab = colorspace('rgb->lab', probeLoad);

        probeGray = repmat(mean(probeLoad,3), [1 1 3]);
        probeGray(:,:,4)=probeAlpha;

        probeTexture = Screen('MakeTexture', window, probeGray);
            
        % Draw initial screen
        Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', window, probeTexture, [], stimRect);
        Screen('FrameOval', window, [0 0 0], colorWheel.rect);
            
        % Probe onset ties in from the offset of retention
        [~, greyscaleOnset] = Screen('Flip', window, retentionDisplayOffsetTraining);
        
        %% Testing begins
        % Start the test timer 
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
    
            if (curAngle ~= probeColor) && round(curAngle) ~= 0
                newRgb = RotateImage(probeLab, round(curAngle) + randomAddition);
                newRgb(:, :, 4) = probeAlpha;
                Screen('Close', probeTexture);
                probeTexture = Screen('MakeTexture', window, newRgb);
            end
        
            Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
            Screen('FrameOval', window, [0, 0, 0], colorWheel.rect);
            Screen('DrawLine', window, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
            Screen('DrawTexture', window, probeTexture, [], stimRect);
            Screen('Flip', window);
            
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
        Screen('Close', probeTexture);

        if any(buttons) && GetSecs < testingLimit

            % Flip immediately to blank background (ensures sync)
            Screen('FillRect', window, trainingBackground, [0 0 screenWidth screenHeight]);
            [~, postResponseOnsetTraining] = Screen('Flip', window);
            postResponseOffsetTraining = postResponseOnsetTraining;  % next phase can start right away

            % Wait for button release
            while any(buttons), [~, ~, buttons] = GetMouse(window); end

            % Wrap angles to [0,360)
            probeColor = mod(probeColor, 360);
            curAngle_adjusted = mod(curAngle + randomAddition, 360);
    
            % Compute angular disparity ([-180,180) range)
            angularDisparity = mod((probeColor - curAngle_adjusted) + 180, 360) - 180;

            % Save errors if it's practice
            if trainingTrial >= 13
                errorPerSeries(practice) = abs(angularDisparity);
            end
        
        else
            % If testing times out, the post response screen will show a 
            % time-out warning. 

            % This branch will be entered regardless of where the time
            % was up. A participant could fail either during response
            % selection, or even before the first mouse movement.

            % No angular disp value could have been assigned. 
            angularDisparity = NaN;
            
            % Save errors if it's the practice part
            if trainingTrial >= 13
                errorPerSeries(practice) = angularDisparity;
            end

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

            % Show the time-out warning at time testing limit.  
            [~, postResponseOnsetTraining] = Screen('Flip', window, testingLimit);
            postResponseOffsetTraining = postResponseOnsetTraining + warningDurationTraining - ifi / 2;
        end
    
        % If at the end of practice, evaluate performance
        if practice == 18
            
            % How many probe screens was failed in practice? 
            numNaNs = sum(isnan(errorPerSeries(practice-5:practice)), 'all');

            % At the end of practice, take the mean of errors (ignore the
            % NaNs). 
            practiceAverageError = mean(errorPerSeries, 'omitnan');

            % Repeat practice if any test was timed-out, and/or error is
            % above the threshold
            if numNaNs >= 1 || practiceAverageError >= errorThreshold

                Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);

                DrawFormattedText(window, instructionsRepeatPractice, 'center', (centerY - 2*lineSpacing), instructionsTextColor);

                DrawFormattedText(window, ...
                ['Missed Tests: ' num2str(numNaNs)], ...
                'center',  (centerY - lineSpacing/2), instructionsTextColor);

                DrawFormattedText(window, ...
                ['Average error: ' num2str(practiceAverageError, '%.0f') ' degrees'], ...
                'center',  (centerY + lineSpacing), instructionsTextColor);          

                % Flip to show it
                Screen('Flip', window);
            
                % Wait for space key
                waitForSpace();

                % Rewind the trial flow back to the start of practice
                practice = 13;
                trainingTrial = trainingTrial + 1;      
               
                % Restart accumulators
                errorPerSeries = NaN(size(trainingMatrix,1),1);
                numNaNs = 0;
                practiceAverageError = 0;

                % Restart practice with an ITI
                Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
                Screen('Flip', window);
                WaitSecs(interTrialIntervalDuration);
         
                continue;

            elseif numNaNs == 0 && practiceAverageError <= errorThreshold
                % If the performance is sufficient, allow transition into
                % the actual experiment.
                passOnToExperiment = true;
            end
        end
    
        % If given the nod, break out of training. 
        if passOnToExperiment
            
           Screen('Close', im1colored);
           Screen('Close', im2colored);
           Screen('Close', im3colored);
           Screen('Close', im4colored);

           break;
        end
    
        % Increment the trial counter
        practice = practice + 1;

        % This counter is not reeled back to the beginning of the practice
        % unlike the other two, as this is a counter for the training cond.
        % matrix. 
        trainingTrial = trainingTrial + 1;
    
        %% FRAME 5: INTER-TRIAL INTERVAL
    
        % Move on to the next trial through ITI after test.  
        Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
        Screen('Flip', window, postResponseOffsetTraining);
        WaitSecs(interTrialIntervalDuration);
        
    end
end

%% Set up main phase parameters

% Experiment Trial Count
numTrials = size(conditionMatrix, 1);
totalBlock = 15;
trialPerBlock = numTrials/totalBlock;

% Event durations:
habituationDuration = 0.800;
encodingDuration = 0.750;
retentionDuration = 0.800;
testingDuration = 4.000;
warningDuration = 0.300;

% Pick an initial background
currentBackgroundIndex = randi([1,2]);

% Data to save:
participantNumber = zeros(numTrials,1);
conditionUsed = zeros(numTrials,1);

blockNumber = zeros(numTrials,1);
trialCount = zeros(numTrials,1);

contextChangeValue = zeros(numTrials,1);
currentContext = zeros(numTrials,1);
primaryImageColor = zeros(numTrials,1);
secondaryImageColor = zeros(numTrials,1);

errorPerBlock = NaN(numTrials);

errorSigned = zeros(numTrials,1);
errorAbs = zeros(numTrials,1);
mouseOnset = zeros(numTrials,1);
decisionRT = zeros(numTrials,1);
totalRT = zeros(numTrials,1);

clickAngle = zeros(numTrials,1); % Where on the color wheel is clicked? (ignoring random rotation)
adjustedAngle = zeros(numTrials,1); % Where on the color wheel is clicked?
wheelRotation = zeros(numTrials,1); % By how much was the color wheel rotated?

breakTaken = NaN(numTrials,1);
experimentalConditions = NaN(numTrials, 1);

% Define the data matrix and preallocate some of the columns
outputMatrix = NaN(numTrials,23);

        outputMatrix(:,1) = repmat(lastParticipantNumber,numTrials,1); % ID
        outputMatrix(:,2) = repmat(currentConditionNumber, numTrials,1); % Cond File
        outputMatrix(:,3) = repelem((1:totalBlock)', trialPerBlock); % Block Number
        outputMatrix(:,4) = (1:numTrials)'; % Trial counter
        outputMatrix(:,5) = conditionMatrix(:,1);  % Repetition counter
        outputMatrix(:,6) = conditionMatrix(:,2);  % Context change 
        % 7th column: Current Context RGB (only the first number) 
        outputMatrix(:,8) = conditionMatrix(:, 7); % Mem array rotation angle
        outputMatrix(:,9) = conditionMatrix(:, 3); % Repeated item 1 color deg
        outputMatrix(:,10) = conditionMatrix(:, 4); % Repeated item 2 color deg
        outputMatrix(:,11) = conditionMatrix(:, 5); % Repeated item 3 color deg
        outputMatrix(:,12) = conditionMatrix(:, 6); % Novel item color deg
        outputMatrix(:,13) = conditionMatrix(:, 8); % Probe item index
       
        % 14th column: angular error (signed)
        % 15th column: angular error (absolute)
        % 16th column: Mouse Onset time
        % 17th column: Decision Time (time elapsed scrolling the wheel)
        % 18th column: Total RT (combined) 
        % 19th column: Clicked angle 
        % 20th column: Adjusted angle
        % 21st column: Color wheel rotation increment
        outputMatrix(:,22) = breakTaken; % Break time

        % Extract relevant columns for the exp. conditions column 
        repetition     = outputMatrix(:,5);
        contextChange  = outputMatrix(:,6);
        
        % Assign values based on specified conditions
        experimentalConditions(repetition == 1 & contextChange == 0) = 1;
        experimentalConditions(repetition == 1 & contextChange == 1) = 2;
        experimentalConditions(repetition == 5 & contextChange == 0) = 3;
        experimentalConditions(repetition == 5 & contextChange == 1) = 4;
        
        outputMatrix(:,23) = experimentalConditions; % 23rd: Experimental Conditions 
        % (1: Rep 1, No Change; 2: Rep 1, Change; 3: Rep 5, No Change; 4: Rep 5, Change; NaN)

% Matrix to save mouse trajectory data
trackingData = cell(numTrials);
    % Mouse Time: Time of mouse movement relative to probe time
    % Mouse X: the x coordinate of the cursor
    % Mouse Y: the y coordinate

escStartTime = NaN;

% Lead the participant into the actual experiment
Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
DrawFormattedText(window, instructionsMainPhaseStarts, 'center', 'center', instructionsTextColor);

% Flip to show it
Screen('Flip', window);

% Wait for space key
waitForSpace();

% Start the trial flow
for trial = 1:numTrials
    
    %% FRAME 0: BREAK TIME / END OF BLOCK
     
    % If this is a block end
    if trial >= 2 && (outputMatrix(trial,3) ~= outputMatrix((trial-1),3))

        % Save the data in each block intermission. 

        % Save the data
        currentLabel = sprintf('imperil6GammaDataID%d.mat', lastParticipantNumber);
        fullPath = fullfile(outputDest, currentLabel);
        save(fullPath, 'outputMatrix');

        % Save the mouse data
        currentLabel2 = sprintf('imperil6GammaDataMouseID%d.mat', lastParticipantNumber);
        fullPath = fullfile(mouseDest, currentLabel2);
        save(fullPath, 'trackingData');

        save(fullPath, 'trackingData', '-v7.3');

        % Save the workspace
        currentLabel3 = sprintf('imperil6GammaWorkspaceID%d.mat', lastParticipantNumber);
        fullPath = fullfile(workspaceDest, currentLabel3);
        save(fullPath);
        
        remainingBlocks = totalBlock - (outputMatrix((trial-1),3));
        averageBlockError = mean(errorPerBlock(:), 'omitnan'); 

        % Set the duration of the countdown in seconds
        countdownDuration = 120; 
        
        % Get the starting time
        startTimeBreak = GetSecs;
        
        % Main loop
        while GetSecs - startTimeBreak < countdownDuration
            
            % Check for key press
            [~, ~, keyCode] = KbCheck;
            
            % Only accept SPACE key to break
            if keyCode(KbName('space'))
            
                % Store how much break was taken
                outputMatrix(trial, 22) = (countdownDuration - timeRemaining);
            
                % Reset these parameters
                errorPerBlock = NaN(numTrials);
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
            DrawFormattedText(window, breakTime1, 'center', (centerY - 4 * lineSpacing), instructionsTextColor);
            
            DrawFormattedText(window, breakTime2, 'center', (centerY - 3 * lineSpacing), instructionsTextColor);

            DrawFormattedText(window, ...
                ['Average error: ' num2str(averageBlockError, '%.0f') ' degrees'], ...
                'center',  (centerY - lineSpacing/2), instructionsTextColor);
            
            DrawFormattedText(window, ['Remaining blocks: ' num2str(remainingBlocks)], 'center', (centerY + 2*lineSpacing), instructionsTextColor);

            DrawFormattedText(window, sprintf('Remaining break time: %02d:%02d', minutesRemaining, secondsRemaining), 'center', (centerY + 3 * lineSpacing), instructionsTextColor);
            
            DrawFormattedText(window, breakTime3, 'center', (centerY + 4 * lineSpacing + lineSpacing/2), instructionsTextColor);
                
            % Flip screen
            Screen('Flip', window);
        end
    end
    
    %% FRAME 1: CONTEXT HABITUATION

    % First, lay down a background of the chosen color
    % If this is not a context change trial, go on with the current context

    if conditionMatrix(trial,2) ~= 1
        
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

    % The moment the context screen is shown
    habituationOnset = Screen('Flip', window);

    % Calculate when the first memory display should appear
    habituationOffset = habituationOnset + habituationDuration - ifi / 2; 

    %% FRAME 2: MEMORY DISPLAY
    % Load the repeated memory items

    [load1M, ~ , load1alphaM] = imread(imageMatrix{trial,1});
    [load2M, ~ , load2alphaM] = imread(imageMatrix{trial,2});
    [load3M, ~ , load3alphaM] = imread(imageMatrix{trial,3});

    % Resize images
    load1M = imresize(load1M, imageSize);
    load2M = imresize(load2M, imageSize);
    load3M = imresize(load3M, imageSize);

    % Fetch color degrees
    load1colorM = conditionMatrix(trial, 3);
    load2colorM = conditionMatrix(trial, 4);
    load3colorM = conditionMatrix(trial, 5);

    % Convert the image to LAB only once to speed up color rotations:
    savedLab1M = colorspace('rgb->lab', load1M);
    % Convert the image to LAB only once to speed up color rotations:
    savedLab2M = colorspace('rgb->lab', load2M);
    % Convert the image to LAB only once to speed up color rotations:
    savedLab3M = colorspace('rgb->lab', load3M);

    % Image colors in RGB values
    load1colorRGBM = RotateImage(savedLab1M, load1colorM);
    load2colorRGBM = RotateImage(savedLab2M, load2colorM);
    load3colorRGBM = RotateImage(savedLab3M, load3colorM);

    % Create alpha channels
    load1alphaM = imresize(load1alphaM, [size(load1colorRGBM,1), size(load1colorRGBM,2)]);
    load1colorRGBM(:,:,4)= load1alphaM;
    load1alphaM = imresize(load1alphaM, imageSize);

    load2alphaM = imresize(load2alphaM, [size(load2colorRGBM,1), size(load2colorRGBM,2)]);
    load2colorRGBM(:,:,4)= load2alphaM;
    load2alphaM = imresize(load2alphaM, imageSize);

    load3alphaM = imresize(load3alphaM, [size(load3colorRGBM,1), size(load3colorRGBM,2)]);
    load3colorRGBM(:,:,4)= load3alphaM;
    load3alphaM = imresize(load3alphaM, imageSize);

    % Paint the images
    im1coloredM = Screen('MakeTexture', window, load1colorRGBM);
    im2coloredM = Screen('MakeTexture', window, load2colorRGBM);
    im3coloredM = Screen('MakeTexture', window, load3colorRGBM);

    % Draw on the memory display at the rotated locations
    Screen('DrawTexture', window, im1coloredM, [], mainRects(:,1, trial));
    Screen('DrawTexture', window, im2coloredM, [], mainRects(:,2, trial));
    Screen('DrawTexture', window, im3coloredM, [], mainRects(:,3, trial));

    % Load the non-repeated item
    [load4M, ~ , load4alphaM] = imread(imageMatrix{trial, 4});
    load4M = imresize(load4M, imageSize);
    load4colorM = conditionMatrix(trial, 6);

    % Convert the image to LAB only once to speed up color rotations:
    savedLab4M = colorspace('rgb->lab', load4M);

    % Fetch the colour 
    load4colorRGBM = RotateImage(savedLab4M, load4colorM);
    load4alphaM = imresize(load4alphaM, [size(load4colorRGBM,1), size(load4colorRGBM,2)]);

    % Combine the color and the alpha channel
    load4colorRGBM(:,:,4)= load4alphaM;
    load4alphaM = imresize(load4alphaM, imageSize);

    % Project the colour onto the target     
    im4coloredM = Screen('MakeTexture', window, load4colorRGBM);

    % Draw the selected texture to the screen
    Screen('DrawTexture', window, im4coloredM, [], mainRects(:,4,trial));

    % Show the display + schedule the flip into retention 1
    [~, memoryDisplayOnset] = Screen('Flip', window, habituationOffset);
    memoryDisplayOffset = memoryDisplayOnset + encodingDuration - ifi / 2; 

    %% FRAME 3: RETENTION DISPLAY

    Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
    [~, retentionDisplayOnset] = Screen('Flip', window, memoryDisplayOffset);
    retentionDisplayOffset = retentionDisplayOnset + retentionDuration - ifi / 2; 

    %% FRAME 4: PROBE DISPLAY

    % Increment the color wheel position by a random degree
    temp=Shuffle(0:45:315);
    randomAddition=temp(1);
    
    % Make sure the random addition differs from test to test
    if trial >= 2
        while wheelRotation(trial-1) == randomAddition
            temp=Shuffle(0:45:315);
            randomAddition=temp(1);
        end
    end
    
    % Add the increment after making sure it's different than the last
    wheelRotation(trial) = randomAddition;

    % Which memory item is to be tested? 
    probeIndex = conditionMatrix(trial,8);

    % If index is 4, test the non-repeated item
    if probeIndex == 4
        probeLoadM = load4M;
        probeAlphaM = load4alphaM;
        probeColorM = load4colorM;

    % If 1,2 or 3, test the corresponding repeated item
    elseif probeIndex == 1
        probeLoadM = load1M;
        probeAlphaM = load1alphaM;
        probeColorM = load1colorM;
    elseif probeIndex == 2
        probeLoadM = load2M;
        probeAlphaM = load2alphaM;
        probeColorM = load2colorM;
    elseif probeIndex == 3
        probeLoadM = load3M;
        probeAlphaM = load3alphaM;
        probeColorM = load3colorM;
    end

    % Create the grayscale test image
    probeLabM = colorspace('rgb->lab', probeLoadM);

    probeGrayM = repmat(mean(probeLoadM,3), [1 1 3]);
    probeGrayM(:,:,4)=probeAlphaM;

    probeTextureM = Screen('MakeTexture', window, probeGrayM);

    % Draw initial screen
    Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
    Screen('DrawTexture', window, probeTextureM, [], stimRect);
    Screen('FrameOval', window, [0 0 0], colorWheel.rect);
    
    %% Testing has begun
    % Show the probe in greyscale, mark the time
    [~, greyscaleOnset] = Screen('Flip', window, retentionDisplayOffset);

    % Testing limit spans four seconds from probe onset  
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
        %% TIMESTAMP: The participant has made the first mouse movement
        firstMouseMovement = GetSecs();
        mouseOnset(trial) = (firstMouseMovement - greyscaleOnset);
    else
        % If timed out before the first mouse movement, the entire test was missed
        clickAngle(trial) = NaN;
        adjustedAngle(trial) = NaN;
        errorSigned(trial) = NaN;
        errorAbs(trial) = NaN;
        errorPerBlock(trial) = NaN;
        mouseOnset(trial) = NaN;
        decisionRT(trial) = NaN;
        totalRT(trial) = NaN;
    end

    % Show object in correct color for current angle and wait for click:
    buttons = [];

    sampleInterval = 0.005;
    maxSamples = ceil(testingDuration / sampleInterval) + 20;
    
    mouseX = NaN(maxSamples);
    mouseY = NaN(maxSamples);
    mouseTime = NaN(maxSamples);

    frame = 1;
    probeStart = greyscaleOnset;

    % Enter color-selection phase if still within time window
    while GetSecs < testingLimit && ~any(buttons)
        
        relativeTime = GetSecs - probeStart;
        [curX, curY, buttons] = GetMouse(window);

        % Save mouse information and increment frames until time-out
        if frame <= maxSamples
            mouseX(frame) = curX;
            mouseY(frame) = curY;
            mouseTime(frame) = relativeTime;
            frame = frame + 1;
        end  

        curAngle = GetPolarCoordinates(curX, curY, centerX, centerY);
        [dotX1, dotY1] = polar2xy(curAngle, colorWheel.radius-5, centerX, centerY);
        [dotX2, dotY2] = polar2xy(curAngle, colorWheel.radius+20, centerX, centerY);

        if (curAngle ~= probeColorM) && round(curAngle) ~= 0
            newRgb = RotateImage(probeLabM, round(curAngle) + randomAddition);
            newRgb(:, :, 4) = probeAlphaM;
            Screen('Close', probeTextureM);
            probeTextureM = Screen('MakeTexture', window, newRgb);
        end
    
        Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
        Screen('FrameOval', window, [0, 0, 0], colorWheel.rect);
        Screen('DrawLine', window, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
        Screen('DrawTexture', window, probeTextureM, [], stimRect);
        Screen('Flip', window);

        % Quit the experiment by holding the button down 
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

    % Save mouse trajectory 
    mouseX = mouseX(1:frame-1);
    mouseY = mouseY(1:frame-1);
    mouseTime = mouseTime(1:frame-1);
        
    trackingData{trial} = [mouseTime, mouseX, mouseY];
        
    % Close the probe texture
    Screen('Close', probeTextureM);

    % If response is made before time-out, 
    % the post response screen will show feedback at time testing limit. 
    if any(buttons) && GetSecs < testingLimit

        %% TIMESTAMP: MOUSE CLICK - RESPONSE MADE
        % Marks the exact moment a mouse click is made
        decisionMade = GetSecs;
        
        % Wait for button release
        while any(buttons), [~, ~, buttons] = GetMouse(window); end

            Screen('FillRect', window, currentBackground, [0 0 screenWidth screenHeight]);
            [~, postResponseOnset] = Screen('Flip', window);
            postResponseOffset = postResponseOnset; 
        
            % Compute angular disparity ([-180,180) range)
            adjusted_angle = mod(curAngle + randomAddition, 360); 
            angularDisparityM = mod((probeColorM - adjusted_angle) + 180, 360) - 180;
        
            clickAngle(trial) = curAngle; % Where on the screen was clicked?
            adjustedAngle(trial) = adjusted_angle; % Where on the color space was clicked?
            errorSigned(trial) = angularDisparityM; 
            errorAbs(trial) = abs(angularDisparityM);
            errorPerBlock(trial) = abs(angularDisparityM);
            decisionRT(trial) = (decisionMade - firstMouseMovement);
            totalRT(trial) = (decisionMade - greyscaleOnset);
         
    else
        % If testing times out, the post response screen will show a 
        % time-out warning at time testing limit. 

        clickAngle(trial) = NaN;
        adjustedAngle(trial) = NaN;
        errorSigned(trial) = NaN;
        errorAbs(trial) = NaN;
        errorPerBlock(trial) = NaN;
        decisionRT(trial) = NaN;
        totalRT(trial) = NaN;

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
        [~, postResponseOnset] = Screen('Flip', window, testingLimit);

        postResponseOffset = postResponseOnset + warningDuration - ifi / 2;
    end
        
    % Save the trial-by-trial data before ITI
    outputMatrix(trial, 7) = currentContext(trial);
    outputMatrix(trial, 14:21) = [errorSigned(trial) errorAbs(trial) mouseOnset(trial) decisionRT(trial) totalRT(trial) ...
        clickAngle(trial) adjustedAngle(trial) wheelRotation(trial)]; 
    
    %% FRAME 6: INTER-TRIAL INTERVAL
    % At the very end of the trial, close the generated textures for
    % smoother script execution.

    Screen('Close', im1coloredM);
    Screen('Close', im2coloredM);
    Screen('Close', im3coloredM);
    Screen('Close', im4coloredM);

    % At post response offset, move on to the next trial through ITI.  
    Screen('FillRect' , window, [128 128 128], [0 0 screenWidth screenHeight]);
    Screen('Flip', window, postResponseOffset);
    WaitSecs(interTrialIntervalDuration);
   
    % Save the last block data before ending the experiment
    if trial == numTrials    
        % Save the data
        currentLabel = sprintf('imperil6GammaDataID%d.mat', lastParticipantNumber);
        fullPath = fullfile(outputDest, currentLabel);
        save(fullPath, 'outputMatrix');

         % Save the mouse data
        currentLabel2 = sprintf('imperil6GammaDataMouseID%d.mat', lastParticipantNumber);
        fullPath = fullfile(mouseDest, currentLabel2);
        save(fullPath, 'trackingData');
        
        save(fullPath, 'trackingData', '-v7.3');

        % Save the workspace
        currentLabel3 = sprintf('imperil6GammaWorkspaceID%d.mat', lastParticipantNumber);
        fullPath = fullfile(workspaceDest, currentLabel3);
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





% for it = 1:900
% 
%     curQuad = conditionMatrix(it,3:6);
% 
%     differ = curQuad(:)-curQuad(:).';
% 
%     if any(abs(differ(:)) < 40 & differ(:) ~= 0)
%         fprintf("vio found at %d\n", it);
%     end
% 
% 
% end
% 















function newRgb = RotateImage(lab, r)
    x = lab(:,:,2);
    y = lab(:,:,3);
    v = [x(:)'; y(:)'];
    vo = [cosd(r) -sind(r); sind(r) cosd(r)] * v;
    lab(:,:,2) = reshape(vo(1,:), size(lab,1), size(lab,2));
    lab(:,:,3) = reshape(vo(2,:), size(lab,1), size(lab,2));
    newRgb = (colorspace('lab->rgb', lab) .* 255);
end

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


function [x, y] = polar2xy(angle,radius,centerH,centerV)  
  x = round(centerH + radius.*cosd(angle));
  y = round(centerV + radius.*sind(angle));
end





