

%%%%%%%%Participant Number Input%%%%%%%%

% % Load the last participant number (if the file exists)
if exist('lastParticipantNumber.mat', 'file')
    load('lastParticipantNumber.mat');
else
    lastParticipantNumber = 1;  % Set a default starting number if the file doesn't exist
end

% Get or use the participant number
participantNumber = input(['Enter participant number (last used: ' num2str(lastParticipantNumber) '): ']);

% Save the current participant number for the next session
lastParticipantNumber = participantNumber;
save('lastParticipantNumber.mat', 'lastParticipantNumber');

%%%%%%%%Participant Number Input%%%%%%%%




%%%%%%%%Engage Next Condition File%%%%%%%%

% Load the last processed condition file
try
    load('lastProcessedCondition.mat');
catch
    % If the file doesn't exist, initialize the structure
    currentCondition = struct('currentConditionNumber', 1);
end

% Extract the numeric value
currentConditionNumber = currentCondition.currentConditionNumber;

% Increment the condition number and reset to 1 if it exceeds the total number of conditions
currentConditionNumber = mod(currentConditionNumber, 15) + 1;

% Update the structure with the new condition number
currentCondition.currentConditionNumber = currentConditionNumber;

% Save the updated structure
save('lastProcessedCondition.mat', 'currentCondition');

% Generate the filename for the current condition
useCondition = ['conditionMatrix' num2str(currentConditionNumber) '.mat'];

% Display the filename
disp(useCondition);

% Load the file and display the field names
commandValues = load(useCondition);

% Access the conditionMatrix from the structure
conditionMatrix = commandValues.matrix;

% Extract the second and third columns for context and interference
contextCommands = conditionMatrix(:, 2);  % Second column
interferenceCommands = conditionMatrix(:, 3);  % Third column







%%%%%%%%Engage Next Condition File%%%%%%%%





%%%%%%%%Initiliaze Screen and Relevant Vriables%%%%%%%%%

Screen('Preference', 'SkipSyncTests', 1)
% Options:
monitor = max(Screen('Screens'));

% Define the size and position of the window (e.g., a 600x400 window at position (100, 100))


% Which images to use (randomly ordered):
listOfTargets = Shuffle(dir('TestObjectsTransparent/*.png'));


% Open the small window
[win, winRect] = Screen('OpenWindow', monitor);
Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
ifi = Screen('GetFlipInterval', win); %measure refresh rate

HideCursor(win);

centerX = round(winRect(3)/2);
centerY = round(winRect(4)/2);
colorWheel.radius = 225;
colorWheel.rect = CenterRect([0 0 colorWheel.radius*2 colorWheel.radius*2], winRect);
stim.size = 256;
intStimSize = 150;
stimRect = CenterRect([0 0 stim.size stim.size], winRect);

% Show a loading images status:
DrawFormattedText(win, 'Loading images...', 'center', 'center');
Screen('Flip', win);

%Parameters
screenHeight=winRect(4);
screenWidth=winRect(3);
yAxis = 1:screenHeight - stim.size;
xAxis = 1:screenWidth - stim.size;

%%%%%%%%Initiliaze Screen and Relevant Vriables%%%%%%%%%



%%%%%%%%%Practice Begins%%%%%%%%%%%




%%%%%%%%Initiliaze Practice Variables%%%%%%%%%

previousColourDegree = 0;
miniBlockEnd = 0;   
usedTargets = {};
randomBackgroundIndexAcross = {};
randomBackgroundAcross = {};
otherBackgroundIndex = {};
usedSurpriseDistractors = {};
usedAngels = cell(2,0);
usedSurpriseTargets = {};
errorRateList = [];
errorRate=0;
breakout=false;

participantNumber1 = zeros(1440, 1);
trialNumber = zeros(1440, 1);
contextChange = zeros(1440, 1);
interferencePresence = zeros(1440, 1);
angularDisparity = zeros(1440, 1);
targetPresented = strings(1440, 1);
conditionUsed = strings(1440, 1); 

textSize = 30;
Screen('TextSize', win, textSize);

blockCountdown = 120;
% Get the screen resolution
[screenXpixels, screenYpixels] = Screen('WindowSize', win);

%%%%%%%%Initiliaze Practice Variables%%%%%%%%%






%%%%%%%%Pre-Test Practice Begins%%%%%%%%%%%%

practice = 1;

currentIteration = 1;
while currentIteration <= 18
        if practice == 1
                informedConsent= imread('informedconsent.png');
                informedConsentTexture = Screen('MakeTexture', win, informedConsent);
                Screen('DrawTexture', win, informedConsentTexture);
    
    
                % Flip the screen to show the text
                Screen('Flip', win);
    
                % Wait for a key press to continue
                KbWait;

                WaitSecs(3);
            
            
                practiceInstructions= imread('experimentinstricutionsENG.png');
                practiceInstructionsTexture = Screen('MakeTexture', win, practiceInstructions);
                Screen('DrawTexture', win, practiceInstructionsTexture);
    
    
                % Flip the screen to show the text
                Screen('Flip', win);
    
                % Wait for a key press to continue
                KbWait;
        end
    
        if practice == 8
                backgroundInstructions= imread('backgroundinstructionsENG.png');
                backgroundInstructionsTexture = Screen('MakeTexture', win, backgroundInstructions);
                Screen('DrawTexture', win, backgroundInstructionsTexture);
    
                % Flip the screen to show the text
                Screen('Flip', win);
    
                % Wait for a key press to continue
                KbWait;
        end
    
        if practice == 8
            for sampleBackground = 1:4
                    sampleBackgroundImage = imread(backgroundPoolPractice{sampleBackground});
                    sampleBackgroundImageTexture = Screen('MakeTexture', win, sampleBackgroundImage);
    
                    % Show the target with the background
                    Screen('DrawTexture', win, sampleBackgroundImageTexture);
    
                    % Flip the screen to show the text
                    Screen('Flip', win);
    
                    % Wait for a key press to continue
                    KbWait;
    
                    WaitSecs(2);
            end
        end
    
        if practice == 8
            practiceBackgroundImage = imread(backgroundPoolPractice{4});
            practiceBackgroundImageTexture = Screen('MakeTexture', win, practiceBackgroundImage);
        end
    
    
        if practice == 1 || practice == 7 || practice == 13
            % Choose a target among the targets
            practiceTargetIndex = randi(length(listOfTargets));
            practiceTargetFilename = listOfTargets(practiceTargetIndex).name;
    
            % Load the random target
            [practiceTargetLoad, map, alpha] = imread((fullfile('TestObjectsTransparent', practiceTargetFilename)));
    
    
            % Choose the degree of colour to be assigned to the target
            minColourDegreePractice = 1;
            maxColourDegreePractice = 360;
            practiceColourDegree = randi([minColourDegreePractice, maxColourDegreePractice]);
    
    
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', practiceTargetLoad);
    
            % Fetch the colour 
            newRgb = RotateImage(savedLab, practiceColourDegree);
    
            newRgb(:,:,4)=alpha;
    
            % Project the colour onto the target     
            practiceTargetTexture = Screen('MakeTexture', win, newRgb);
    
            % Generate the first background
            backgroundPoolPractice = {'bg1.png', 'bg4.png', 'final3.png', 'final4.png'}; 
    
    
            practiceBackgroundImage = imread(backgroundPoolPractice{1});
            practiceBackgroundImageTexture = Screen('MakeTexture', win, practiceBackgroundImage);
    
            if any(practice == 13:18)
                Screen('FillRect' , win, [255 255 255], [0 0 screenWidth screenHeight])
                Screen('Flip', win);
                WaitSecs(0.4);
            end
            
            
            % Show the target with the background
            Screen('DrawTexture', win, practiceBackgroundImageTexture);
            Screen('DrawTexture', win, practiceTargetTexture, [], stimRect);
    
    
            Screen('Flip', win);

            if practice == 1
                WaitSecs(7);
                Screen('DrawTexture', win, practiceBackgroundImageTexture);
                Screen('Flip', win);
                WaitSecs(1);
            elseif practice == 7
                WaitSecs(3);
                Screen('DrawTexture', win, practiceBackgroundImageTexture);
                Screen('Flip', win);
                WaitSecs(1);
            elseif practice == 13
                WaitSecs(0.5);
                Screen('DrawTexture', win, practiceBackgroundImageTexture);
                Screen('Flip', win);
                WaitSecs(0.6);
            end
        else
            if practice == 5
                interferenceWarning= imread('interferencewarningENG.png');
                interferenceWarningTexture = Screen('MakeTexture', win, interferenceWarning);
                Screen('DrawTexture', win, interferenceWarningTexture);
    
    
                % Flip the screen to show the text
                Screen('Flip', win);
    
                % Wait for a key press to continue
                KbWait;
            end
            if any(practice == 13:18)
                Screen('FillRect' , win, [255 255 255], [0 0 screenWidth screenHeight])
                Screen('Flip', win);
                WaitSecs(0.4);
            end
            
            
            % Show the target with the background
            Screen('DrawTexture', win, practiceBackgroundImageTexture);
            Screen('DrawTexture', win, practiceTargetTexture, [], stimRect);
    
            if practice <=12
                Screen('Flip', win);
                WaitSecs(3);
                Screen('DrawTexture', win, practiceBackgroundImageTexture);
                Screen('Flip', win);
                WaitSecs(1);
            elseif practice >=13
                Screen('Flip', win);
                WaitSecs(0.5);
                Screen('DrawTexture', win, practiceBackgroundImageTexture);
                Screen('Flip', win);
                WaitSecs(0.6);
            end
        end
    
    
        if practice == 5 || practice == 11 || practice == 17
    
                    Screen('DrawTexture', win, practiceBackgroundImageTexture);
                    
                    % Initialize the list to store the selected interference images
                    listOfInterferenceTextures = {};
                    
                    luckyNumber = randi([1, 6]); % Randomly choose lucky number (1 for left, 2 for right)
                    
                    % Choose the degree of colour to be assigned to the target
                    minColourDegreePractice = 1;
                    maxColourDegreePractice = 360;
                    interferenceColourDegree = randi([minColourDegreePractice, maxColourDegreePractice]);
                    newinterferenceColourDegree = 0;
                    
                    for interferenceImageSelection = 1:6
                        % Randomly select an index from listOfTargets
                        InterferenceImageIndex = randi(length(listOfTargets));
                        
                        % Get the corresponding image filename
                        InterferenceImageFilename = listOfTargets(InterferenceImageIndex).name;
                    
                        % Load the random interference image
                        [InterferenceImageLoad, map, alpha] = imread(fullfile('TestObjectsTransparent', InterferenceImageFilename));
                    
                        if interferenceImageSelection == luckyNumber
                            newinterferenceColourDegree = interferenceColourDegree + 90;
                            
                            % Convert the image to LAB only once to speed up color rotations:
                            savedLab = colorspace('rgb->lab', InterferenceImageLoad);
                            % Fetch the colour
                            interferenceRgb = RotateImage(savedLab, newinterferenceColourDegree);
                    
                        else
                            % Convert the image to LAB only once to speed up color rotations:
                            savedLab = colorspace('rgb->lab', InterferenceImageLoad);
                            % Fetch the colour
                            interferenceRgb = RotateImage(savedLab, interferenceColourDegree);
                        end
                    
                        % Preserve the alpha channel
                        interferenceRgb(:,:,4) = alpha;
                    
                        % Create texture and store it in the list
                        interferenceTargetTexture = Screen('MakeTexture', win, interferenceRgb);
                        listOfInterferenceTextures{interferenceImageSelection} = interferenceTargetTexture;
                    end
                    
                    % Define circle properties
                    numImages = 6;  % Number of images
                    radius = 400;   % Adjust the radius as needed
                    
                    % Angle between each image (in radians)
                    theta = linspace(0, 2*pi, numImages + 1);
                    theta = theta(1:end-1);  % Remove the last angle to avoid overlap
                    
                    % Loop through the textures and draw them in a circle
                    for i = 1:numImages
                        % Calculate position for each image in the circle
                        xPos = centerX + radius * cos(theta(i));
                        yPos = centerY + radius * sin(theta(i));
                        
                        % Center the 'stimRect' around the calculated (xPos, yPos)
                        destRect = CenterRectOnPoint(stimRect, xPos, yPos);
                        
                        % Draw the texture at the calculated position
                        Screen('DrawTexture', win, listOfInterferenceTextures{i}, [], destRect);
                    end
                    
                    % Flip the screen to display the images
                    Screen('Flip', win);
                    
                    % Wait for user input
                    keyPressed = '';
                    while ~ismember(keyPressed, {'a', 'd'})
                        [keyIsDown, ~, keyCode] = KbCheck; % Check for key presses
                        if keyIsDown
                            if keyCode(KbName('A')) % If 'A' is pressed
                                keyPressed = 'a';
                                selectedSide = 1; % Left
                            elseif keyCode(KbName('D')) % If 'D' is pressed
                                keyPressed = 'd';
                                selectedSide = 2; % Right
                            end
                        end
                    end
                    
                    if selectedSide == 1 && (luckyNumber == 5 || luckyNumber == 4 || luckyNumber == 3 )
                        Screen('DrawTexture', win, practiceBackgroundImageTexture);
                        DrawFormattedText(win, 'Correct Side!', 'center', 'center', [0, 200, 0]);
                    elseif selectedSide == 2 && (luckyNumber == 2 || luckyNumber == 1 || luckyNumber == 6 )
                        Screen('DrawTexture', win, practiceBackgroundImageTexture);
                        DrawFormattedText(win, 'Correct Side!', 'center', 'center', [0, 200, 0]);
                    else
                        Screen('DrawTexture', win, practiceBackgroundImageTexture);
                        DrawFormattedText(win, 'Incorrect Side!', 'center', 'center', [255, 0, 0]);
                    
                    end
                                        
                    
                    Screen('Flip', win);
                    WaitSecs(0.4);    
       end
    
    
            Screen('DrawTexture', win, practiceBackgroundImageTexture);
    
    
    
      if practice ==1
                colouReportInstructions= imread('colourreportinstructionsENG.png');
                colouReportInstructionsTexture = Screen('MakeTexture', win, colouReportInstructions);
                Screen('DrawTexture', win, colouReportInstructionsTexture);
    
    
                % Flip the screen to show the text
                Screen('Flip', win);
    
                % Wait for a key press to continue
                KbWait;
    
                Screen('DrawTexture', win, practiceBackgroundImageTexture);
    
      end
    
    
            tempPractice=Shuffle(0:45:315);
            randomAdditionPractice=tempPractice(1);
    
            startTime = GetSecs;
            % Show in grayscale:
            [originalImgPractice, map, alpha] = imread(fullfile('TestObjectsTransparent',practiceTargetFilename)); 
            % originalImg = imresize(originalImg, [stim.size stim.size]); 
            imgGrayPractice = repmat(mean(originalImgPractice,3), [1 1 3]);
            imgGrayPractice(:,:,4)=alpha;
    
            curTexturePractice = Screen('MakeTexture', win, imgGrayPractice);
            Screen('DrawTexture', win, curTexturePractice, [], stimRect);
    
            % Show color report circle:
            
            Screen('FrameOval', win, [128,128,128], colorWheel.rect);
            Screen('Flip', win);
    
            % Center mouse
            SetMouse(centerX,centerY,win);
    
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', originalImgPractice);
    
            % Wait until the mouse moves:
            [curX,curY] = GetMouse(win);
            while (curX == centerX && curY == centerY)
              [curX,curY] = GetMouse(win);
            end
    
            % Show object in correct color for current angle and wait for click:
            buttons = [];
            while ~any(buttons)  
    
              [curX,curY, buttons] = GetMouse(win);
              curAnglePractice = GetPolarCoordinates(curX,curY,centerX,centerY);
              [dotX1, dotY1] = polar2xy(curAnglePractice,colorWheel.radius-5,centerX,centerY);
              [dotX2, dotY2] = polar2xy(curAnglePractice,colorWheel.radius+20,centerX,centerY);
    
    
    
              if (curAnglePractice ~= practiceColourDegree) && round(curAnglePractice) ~= 0 
                
                newRgb = RotateImage(savedLab, round(curAnglePractice)+randomAdditionPractice);
                newRgb(:,:,4)=alpha;
                Screen('Close', curTexturePractice);
                curTexturePractice = Screen('MakeTexture', win, newRgb);
              end
    
              % Show stimulus:
    
              Screen('DrawTexture', win, practiceBackgroundImageTexture);
    
              % Draw frame and dot
              Screen('FrameOval', win, [128,128,128], colorWheel.rect);
              Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
    
              Screen('DrawTexture', win, curTexturePractice, [], stimRect);
    
    
              Screen('Flip', win);
    
              % Allow user to quit on each frame:
              [~,~,keys]=KbCheck;
              if keys(KbName('q')) && keys(KbName('7'))
                sca; error('User quit');
              end
            end
            Screen('Close', curTexturePractice);
    
            % Wait for release of mouse button
            while any(buttons), [~,~,buttons] = GetMouse(win); end
            responseTime = GetSecs;
    
    
            %Correct for circular space degrees
            angular_disparityPractice=(practiceColourDegree-(curAnglePractice+randomAdditionPractice));
            if angular_disparityPractice>180
                angular_disparityPractice=angular_disparityPractice-360;
            elseif angular_disparityPractice<-180
                angular_disparityPractice=angular_disparityPractice+360;
            end
    
            angularDisparity(practice)=angular_disparityPractice;
            if any(practice == 13:18)
                errorRateList(end+1) = abs(angular_disparityPractice);
            end
            
            errorRate=mean(errorRateList);
    
    
            
            % Format the reaction time for display
            formattedReactionTime = sprintf('%.3f seconds', responseTime);
            
            % Display the formatted reaction time
            
    
            Screen('DrawTexture', win, practiceBackgroundImageTexture);
            Screen('DrawText', win, ['Angular Disparity Rate: ' num2str(round(abs(angular_disparityPractice)))], centerX-125, centerY-525, [250 0 0]); 
            if abs(angular_disparityPractice) <= 5
                Screen('DrawText', win, 'Excellent!', centerX-30, centerY-475, [250 0 0]); 
            elseif abs(angular_disparityPractice) > 5 && abs(angular_disparityPractice) <= 15
                Screen('DrawText', win, 'Great!', centerX-45, centerY-475, [250 0 0]); 
            elseif abs(angular_disparityPractice) > 15 && abs(angular_disparityPractice) <= 25
                Screen('DrawText', win, 'Nice!', centerX-30, centerY-475, [250 0 0]);
            elseif abs(angular_disparityPractice) > 25 && abs(angular_disparityPractice) <= 35
                Screen('DrawText', win, 'Not Bad', centerX-45, centerY-475, [250 0 0]);
            elseif abs(angular_disparityPractice) > 35
                Screen('DrawText', win, 'Could be better', centerX-80, centerY-475, [250 0 0]);
            end
            
            Screen('Flip', win);
            WaitSecs(0.75); 
    
         if practice == 12
            %%%%the end of instructions -- proceed to practice%%%%
            transitionToPractice= imread('transitiontopracticeENG.png');
            transitionToPracticeTexture = Screen('MakeTexture', win, transitionToPractice);
            Screen('DrawTexture', win, transitionToPracticeTexture);
        
        
            % Flip the screen to show the text
            Screen('Flip', win);
        
            % Wait for a key press to continue
            KbWait;
        
            Screen('DrawTexture', win, practiceBackgroundImageTexture);
          end
    
    
        if currentIteration == 18
        % Check the value and reset the loop index if needed
            if errorRate > 30
                errorRateAlarm= imread('errorratealarmENG.png');
                errorRateAlarmTexture = Screen('MakeTexture', win, errorRateAlarm);
                Screen('DrawTexture', win, errorRateAlarmTexture);
            
            
                % Flip the screen to show the text
                Screen('Flip', win);
            
                % Wait for a key press to continue
                KbWait;
                
                practice = 13;
                currentIteration = 13;
                errorRateList = [];
                errorRate=0;
                continue;  % Continue to the next iteration
            else
                breakout=true;
            end
        end
    
    if breakout
        break;
    end
    practice = practice + 1;
    currentIteration = currentIteration + 1;
    % 
    % if practice == 14
    %     break
    % end

end


%%%%%%%%Pre-Test Practice Ends%%%%%%%%%%%%


endOfPractice= imread('endofpracticeinstructionsENG.png');
endOfPracticeTexture = Screen('MakeTexture', win, endOfPractice);
Screen('DrawTexture', win, endOfPracticeTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;


%%%%Resetting variables after practice%%%%%

previousColourDegree = 0;
miniBlockEnd = 0;   
usedTargets = strings(720, 1);
randomBackgroundIndexAcross = strings(720, 1); 
randomBackgroundAcross = strings(720, 1); 
otherBackgroundIndex = strings(720, 1); 
usedSurpriseDistractors = strings(720, 1); 
usedAngels = cell(2,0);
usedSurpriseTargets = strings(720, 1); 

participantNumber1 = zeros(720, 1);
trialNumber = zeros(720, 1);
contextChange = zeros(720, 1);
interferencePresence = zeros(720, 1);
angularDisparity = zeros(720, 1);
targetPresented = strings(720, 1);
conditionUsed = strings(720, 1); 

participantNumber2 = zeros(240, 1);
trialNumber2 = zeros(240, 1);
trueOrFalse = zeros(240, 1);  %1==true, 2==false
angularDisparity2 = zeros(240, 1);
targetPresented2 = strings(240, 1);
distractorPresented = strings(240, 1);
repRange = 1:6;
repeatedArray = repmat(repRange, 1, ceil(720 / length(repRange)));
resultArray = repeatedArray(1:720);
resultColumnVector = resultArray(:);
onsetTime= zeros(720, 1);
moveTime = zeros(720, 1);
onsetTimeSurprise = zeros(240, 1);
moveTimeSurprise = zeros(240, 1);
disparityRates = [];
blockEndTrials = [];
breakTime = zeros(720, 1);
% remainingBlocks = max(blocks);

firstContext=strings(720, 1);
firstInterference=strings(720, 1);
fifthContext=strings(720, 1);
fifthInterference=strings(720, 1);
blocks = zeros(720,1);
interferenceSelection = strings (720,1);


background_pool = {'bg1.png', 'bg4.png', 'final3.png', 'final4.png'}; 
backgroundPoolet1 = {'bg1.png', 'bg4.png'};
backgroundPoolet2 = {'final3.png', 'final4.png'};


%%%%Resetting variables after practice%%%%%








%%%%%%%%%Actual Experiment Begins%%%%%%%%%%%








%%%%%%%%%%%%%%%%%Target Phase%%%%%%%%%%%%%%%%%%%%%

for trial = 1:720 
    rounderS=GetSecs;
    participantNumber1(trial) = participantNumber;
    trialNumber(trial) = trial;
    conditionUsed(trial) = useCondition;

    if trial <=120
        currentBlock = 0;
    elseif trial >=121 && trial <=240
        currentBlock = 1;
    elseif trial >=241 && trial <=360
        currentBlock = 2;
    elseif trial >=361 && trial <=480
        currentBlock = 3;
    elseif trial >=481 && trial <=600
        currentBlock = 4;
    elseif trial >=601 && trial <=720
        currentBlock = 5;
    end

    blocks(trial)=(currentBlock)+1;



    if trial>=2
        if trial == 121 || trial == 241 || trial == 361 || trial == 481 || trial == 601
            remainingBlocks = 6 - currentBlock;
            blockEndTrials(end+1)=(trial-1);
            blockendImage= imread('blockendENG.png');
            blockendImageTexture = Screen('MakeTexture', win, blockendImage);
            averageBlockError1= num2str(round(abs(sum(disparityRates)/(blockEndTrials(end)))));
            averageBlockError= num2str(round(abs(sum(disparityRates)/((trial-(blockEndTrials(end))+1)))));
            
            % Set the duration of the countdown in seconds
            countdownDuration = 300; % 2 minutes
            
            KbName('UnifyKeyNames');
            
            % Get the starting time
            startTime = GetSecs;
            
            % Main loop
            while GetSecs - startTime < countdownDuration
                % Check for any key press
                [~, ~, keyCode] = KbCheck;
                if any(keyCode)
                    % Exit the loop if any key is pressed
                    break;
                end
               
                
                % Calculate time remaining
                timeRemaining = countdownDuration - (GetSecs - startTime);
                
                % Convert time remaining to minutes and seconds
                minutesRemaining = floor(timeRemaining / 60);
                secondsRemaining = mod(floor(timeRemaining), 60);

                 % Draw the image
                Screen('DrawTexture', win, blockendImageTexture);
             
                
                % Display the time remaining on the screen
                DrawFormattedText(win, sprintf('%02d:%02d', minutesRemaining, secondsRemaining), centerX, centerY-375, [255 0 0]);
                Screen('DrawText', win, ['Remaining blocks: ' num2str(remainingBlocks)], centerX-125, centerY-525, [250 0 0])
                Screen('Flip', win);
         
            
            
            end
           
            

            

            
            
            % Flip the screen to show the text
            % 
            breakTime(trial)=120-timeRemaining;
            disparityRates = [];
            averageBlockError1= 0;
            averageBlockError= 0;

            % Wait for a key press to continue
            KbWait;
            
            WaitSecs(2)
        end
    end
    

    %%%ITI display%%%
    Screen('FillRect' , win, [255 255 255], [0 0 screenWidth screenHeight])
    [~, iti_onset] = Screen('Flip', win);

    
    
    if miniBlockEnd == 0
        
        % Choose a target among the targets
        currentTargetIndex = randi(length(listOfTargets));
        currentTargetFilename = listOfTargets(currentTargetIndex).name;

        % Load the random target
        [currentTargetLoad, map, alpha] = imread((fullfile('TestObjectsTransparent', currentTargetFilename)));
        
       
        % Choose the degree of colour to be assigned to the target
        minColourDegree = 1;
        maxColourDegree = 360;
        currentColourDegree = randi([minColourDegree, maxColourDegree]);

        % Assign a new degree if not 30 degrees different than previous

        while abs(currentColourDegree - previousColourDegree) < 30
            currentColourDegree = randi([minColourDegree, maxColourDegree]);
        end

        % Convert the image to LAB only once to speed up color rotations:
        savedLab = colorspace('rgb->lab', currentTargetLoad);

        % Fetch the colour 
        newRgb = RotateImage(savedLab, currentColourDegree);

        newRgb(:,:,4)=alpha;

        % Project the colour onto the target     
        currentTargetTexture = Screen('MakeTexture', win, newRgb);
        

        % Store the first used image
        usedTargets(trial) = currentTargetFilename;


        % Generate the first background
        

        randomBackgroundIndex = randi(numel(background_pool));
        randomBackground = background_pool{randomBackgroundIndex};
        randomBackgroundImage = imread(randomBackground);
        randomBackgroundImageTexture = Screen('MakeTexture', win, randomBackgroundImage);

        targetPresented(trial) = currentTargetFilename;

        % if final_condition(1, trial) == 1
        %     contextChange(trial)=1;
        %     if randomBackground(1) == "b"
        %         otherBackgroundIndex = find(~strcmp(backgroundPoolet1, randomBackground)); 
        %         randomBackground = backgroundPoolet1{otherBackgroundIndex};
        %         if mod(trial,6)==1
        %             firstContext(trial)='Within';
        %         elseif mod(trial,6)==5
        %             fifthContext(trial)='Within';
        %         end
        %     elseif randomBackground(1) == "f"
        %         otherBackgroundIndex = find(~strcmp(backgroundPoolet2, randomBackground));
        %         randomBackground = backgroundPoolet2{otherBackgroundIndex};
        %         if mod(trial,6)==1
        %             firstContext(trial)='Within';
        %         elseif mod(trial,6)==5
        %             fifthContext(trial)='Within';
        %         end
        %     end
        % end

        if strcmp(contextCommands{trial}, 'Yes Change')
            contextChange(trial)=2;
            if randomBackground(1) == "b"
                randomBackgroundIndexAcross = randi(numel(backgroundPoolet2));
                randomBackgroundAcross = backgroundPoolet2{randomBackgroundIndexAcross};
                randomBackground = randomBackgroundAcross;
                if mod(trial,6)==1
                    firstContext(trial)='Yes Change';
                elseif mod(trial,6)==5
                    fifthContext(trial)='Yes Change';
                end
            else
                randomBackgroundIndexAcross = randi(numel(backgroundPoolet1));
                randomBackgroundAcross = backgroundPoolet1{randomBackgroundIndexAcross};
                randomBackground = randomBackgroundAcross;
                if mod(trial,6)==1
                    firstContext(trial)='Yes Change';
                elseif mod(trial,6)==5
                    fifthContext(trial)='Yes Change';
                end
            end
        end


        % Draw the target with change or unchanged background
        randomBackgroundImage = imread(randomBackground);
        randomBackgroundImageTexture = Screen('MakeTexture', win, randomBackgroundImage);


        % Show the target with the background
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        Screen('DrawTexture', win, currentTargetTexture, [], stimRect);
        
        
        % WaitSecs('UntilTime',iti_onset + 0.4 - 0.5*ifi); 
        
        % [~, mem_onset] = Screen('Flip', win);
        
         
        Screen('Flip', win);
        WaitSecs(0.4);
        
       
        
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        % WaitSecs('UntilTime',mem_onset + 0.5 - 0.5*ifi); 
        % [~, retention_onset] = Screen('Flip', win);
         

    elseif miniBlockEnd == 6
        miniBlockEnd = 0;

        % Choose a target among the targets
        currentTargetIndex = randi(length(listOfTargets));
        currentTargetFilename = listOfTargets(currentTargetIndex).name;

        % Make sure the choice is not among the used targets
        while ismember(currentTargetFilename, usedTargets)
            currentTargetIndex = randi(length(listOfTargets));
            currentTargetFilename = listOfTargets(currentTargetIndex).name;
        end

        % Load the random target
        [currentTargetLoad, map, alpha] = imread(fullfile('TestObjectsTransparent', currentTargetFilename));
        

        % Choose the degree of colour to be assigned to the target
        minColourDegree = 1;
        maxColourDegree = 360;
        currentColourDegree = randi([minColourDegree, maxColourDegree]);

        % Assign a new degree if not 30 degrees different than previous

        while abs(currentColourDegree - previousColourDegree) < 30
            currentColourDegree = randi([minColourDegree, maxColourDegree]);
        end

        % Convert the image to LAB only once to speed up color rotations:
        savedLab = colorspace('rgb->lab', currentTargetLoad);
        
        % Fetch the colour 
        newRgb = RotateImage(savedLab, currentColourDegree);

        newRgb(:,:,4)=alpha;

        % Project the colour onto the target     
        currentTargetTexture = Screen('MakeTexture', win, newRgb);

        usedTargets(trial) = currentTargetFilename;

        % if final_condition(1, trial) == 1
        %     contextChange(trial)=1;
        %     if randomBackground(1) == "b"
        %         otherBackgroundIndex = find(~strcmp(backgroundPoolet1, randomBackground)); 
        %         randomBackground = backgroundPoolet1{otherBackgroundIndex};
        %         if mod(trial,6)==1
        %             firstContext(trial)='Within';
        %         elseif mod(trial,6)==5
        %             fifthContext(trial)='Within';
        %         end
        %     elseif randomBackground(1) == "f"
        %         otherBackgroundIndex = find(~strcmp(backgroundPoolet2, randomBackground));
        %         randomBackground = backgroundPoolet2{otherBackgroundIndex};
        %         if mod(trial,6)==1
        %             firstContext(trial)='Within';
        %         elseif mod(trial,6)==5
        %             fifthContext(trial)='Within';
        %         end
        %     end
        % end

        if strcmp(contextCommands{trial}, 'Yes Change')
            contextChange(trial)=2;
            if randomBackground(1) == "b"
                randomBackgroundIndexAcross = randi(numel(backgroundPoolet2));
                randomBackgroundAcross = backgroundPoolet2{randomBackgroundIndexAcross};
                randomBackground = randomBackgroundAcross;
                if mod(trial,6)==1
                    firstContext(trial)='Yes Change';
                elseif mod(trial,6)==5
                    fifthContext(trial)='Yes Change';
                end
            else
                randomBackgroundIndexAcross = randi(numel(backgroundPoolet1));
                randomBackgroundAcross = backgroundPoolet1{randomBackgroundIndexAcross};
                randomBackground = randomBackgroundAcross;
                if mod(trial,6)==1
                    firstContext(trial)='Yes Change';
                elseif mod(trial,6)==5
                    fifthContext(trial)='Yes Change';
                end
            end
        end

 

        % Draw the target with change or unchanged background
        randomBackgroundImage = imread(randomBackground);
        randomBackgroundImageTexture = Screen('MakeTexture', win, randomBackgroundImage);




        Screen('DrawTexture', win, randomBackgroundImageTexture);
        Screen('DrawTexture', win, currentTargetTexture, [], stimRect);
        

        WaitSecs('UntilTime',iti_onset + 0.4 - 0.5*ifi); 
        [~, mem_onset] = Screen('Flip', win);
        
       
        
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        WaitSecs('UntilTime',mem_onset + 0.5 - 0.5*ifi); 
        
        

        targetPresented(trial) = currentTargetFilename;

        

        

    else
        % Depending on the command value, make a within or across change


        % if final_condition(1, trial) == 1
        %     contextChange(trial)=1;
        %     if randomBackground(1) == "b"
        %         otherBackgroundIndex = find(~strcmp(backgroundPoolet1, randomBackground)); 
        %         randomBackground = backgroundPoolet1{otherBackgroundIndex};
        %         if mod(trial,6)==1
        %             firstContext(trial)='Within';
        %         elseif mod(trial,6)==5
        %             fifthContext(trial)='Within';
        %         end
        %     elseif randomBackground(1) == "f"
        %         otherBackgroundIndex = find(~strcmp(backgroundPoolet2, randomBackground));
        %         randomBackground = backgroundPoolet2{otherBackgroundIndex};
        %         if mod(trial,6)==1
        %             firstContext(trial)='Within';
        %         elseif mod(trial,6)==5
        %             fifthContext(trial)='Within';
        %         end
        %     end
        % end

        if strcmp(contextCommands{trial}, 'Yes Change')
            contextChange(trial)=2;
            if randomBackground(1) == "b"
                randomBackgroundIndexAcross = randi(numel(backgroundPoolet2));
                randomBackgroundAcross = backgroundPoolet2{randomBackgroundIndexAcross};
                randomBackground = randomBackgroundAcross;
                if mod(trial,6)==1
                    firstContext(trial)='Yes Change';
                elseif mod(trial,6)==5
                    fifthContext(trial)='Yes Change';
                end
            else
                randomBackgroundIndexAcross = randi(numel(backgroundPoolet1));
                randomBackgroundAcross = backgroundPoolet1{randomBackgroundIndexAcross};
                randomBackground = randomBackgroundAcross;
                if mod(trial,6)==1
                    firstContext(trial)='Yes Change';
                elseif mod(trial,6)==5
                    fifthContext(trial)='Yes Change';
                end
            end
        end

        % Draw the target with change or unchanged background
        randomBackgroundImage = imread(randomBackground);
        randomBackgroundImageTexture = Screen('MakeTexture', win, randomBackgroundImage);

        Screen('DrawTexture', win, randomBackgroundImageTexture);
        Screen('DrawTexture', win, currentTargetTexture, [], stimRect);


        WaitSecs('UntilTime',iti_onset + 0.4 - 0.5*ifi); 

        %%%target display%%%
        [~, mem_onset] = Screen('Flip', win);



        %%%retention%%%%
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        WaitSecs('UntilTime',mem_onset + 0.5 - 0.5*ifi); 




        targetPresented(trial) = currentTargetFilename;

        
        
    end
    
    
    
  %%%%%%%%%%%%%%%%%Target Phase%%%%%%%%%%%%%%%%%%%%%
          
  
          
  %%%%%%%%%%%%%Interference Phase%%%%%%%%%%%%%%%%%%
  
  [~, retention_onset] = Screen('Flip', win);

  


  if strcmp(interferenceCommands{trial}, 'Left Interference')

      numberSet = [3, 4, 5];  % Define the set of numbers
      luckyNumberLeft = randsample(numberSet, 1);

      % Randomly choose lucky number

      engageInterference=true;

      %Engage Interference Display if Command Value is 1
    
        if mod(trial,6)==1
            firstInterference(trial)='Left Interference';
        elseif mod(trial,6)==5
            fifthInterference(trial)='Left Interference';
        end


      interferencePresence(trial)=1;
      interferenceTextures = cell(1, 7);


    previousInterferenceColourDegree = 0; 

    
                    
    % Initialize the list to store the selected interference images
    listOfInterferenceTextures = {};
    
     
    
    % Choose the degree of colour to be assigned to the target
    minColourDegreePractice = 1;
    maxColourDegreePractice = 360;
    interferenceColourDegree = randi([minColourDegreePractice, maxColourDegreePractice]);
    newinterferenceColourDegree = 0;
    
    for interferenceImageSelection = 1:6
        % Randomly select an index from listOfTargets
        InterferenceImageIndex = randi(length(listOfTargets));
        
        % Get the corresponding image filename
        InterferenceImageFilename = listOfTargets(InterferenceImageIndex).name;
    
        % Load the random interference image
        [InterferenceImageLoad, map, alpha] = imread(fullfile('TestObjectsTransparent', InterferenceImageFilename));
    
        if interferenceImageSelection == luckyNumberLeft
            newinterferenceColourDegree = interferenceColourDegree + 90;
            
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', InterferenceImageLoad);
            % Fetch the colour
            interferenceRgb = RotateImage(savedLab, newinterferenceColourDegree);
    
        else
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', InterferenceImageLoad);
            % Fetch the colour
            interferenceRgb = RotateImage(savedLab, interferenceColourDegree);
        end
    
        % Preserve the alpha channel
        interferenceRgb(:,:,4) = alpha;
    
        % Create texture and store it in the list
        interferenceTargetTexture = Screen('MakeTexture', win, interferenceRgb);
        listOfInterferenceTextures{interferenceImageSelection} = interferenceTargetTexture;
    end
    
    % Define circle properties
    numImages = 6;  % Number of images
    radius = 400;   % Adjust the radius as needed
    
    % Angle between each image (in radians)
    theta = linspace(0, 2*pi, numImages + 1);
    theta = theta(1:end-1);  % Remove the last angle to avoid overlap

    Screen('DrawTexture', win, randomBackgroundImageTexture)
    
    % Loop through the textures and draw them in a circle
    for i = 1:numImages
        % Calculate position for each image in the circle
        xPos = centerX + radius * cos(theta(i));
        yPos = centerY + radius * sin(theta(i));
        
        % Center the 'stimRect' around the calculated (xPos, yPos)
        destRect = CenterRectOnPoint(stimRect, xPos, yPos);
        

        
        % Draw the texture at the calculated position
        Screen('DrawTexture', win, listOfInterferenceTextures{i}, [], destRect);
    end
    
    % Flip the screen to display the images
    Screen('Flip', win);
    
    % Wait for user input
    keyPressed = '';
    while ~ismember(keyPressed, {'a', 'd'})
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key presses
        if keyIsDown
            if keyCode(KbName('A')) % If 'A' is pressed
                keyPressed = 'a';
                selectedSide = 1; % Left
            elseif keyCode(KbName('D')) % If 'D' is pressed
                keyPressed = 'd';
                selectedSide = 2; % Right
            end
        end
    end

    if selectedSide == 1
        interferenceSelection(trial) = "Left Selection";
    elseif selectedSide == 2
        interferenceSelection(trial) = "Right Selection";
    end


    if selectedSide == 1 && (luckyNumberLeft == 5 || luckyNumberLeft == 4 || luckyNumberLeft == 3 )
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        DrawFormattedText(win, 'Correct Side!', 'center', 'center', [0, 200, 0]);
    elseif selectedSide == 2 && (luckyNumberLeft == 2 || luckyNumberLeft == 1 || luckyNumberLeft == 6 )
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        DrawFormattedText(win, 'Correct Side!', 'center', 'center', [0, 200, 0]);
    else
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        DrawFormattedText(win, 'Incorrect Side!', 'center', 'center', [255, 0, 0]);
    
    end
                        
    
    Screen('Flip', win);
    WaitSecs(0.1);    

  elseif strcmp(interferenceCommands{trial}, 'Right Interference')
      engageInterference=true;

      numberSet2 = [1, 2, 6];  % Define the set of numbers
      luckyNumberRight = randsample(numberSet2, 1);

      %Engage Interference Display if Command Value is 1
    
        if mod(trial,6)==1
            firstInterference(trial)='Right Interference';
        elseif mod(trial,6)==5
            fifthInterference(trial)='Right Interference';
        end


      interferencePresence(trial)=1;
      interferenceTextures = cell(1, 7);


    previousInterferenceColourDegree = 0; 

    Screen('DrawTexture', win, randomBackgroundImageTexture);
                    
    % Initialize the list to store the selected interference images
    listOfInterferenceTextures = {};
    
     
    
    % Choose the degree of colour to be assigned to the target
    minColourDegreePractice = 1;
    maxColourDegreePractice = 360;
    interferenceColourDegree = randi([minColourDegreePractice, maxColourDegreePractice]);
    newinterferenceColourDegree = 0;
    
    for interferenceImageSelection = 1:6
        % Randomly select an index from listOfTargets
        InterferenceImageIndex = randi(length(listOfTargets));
        
        % Get the corresponding image filename
        InterferenceImageFilename = listOfTargets(InterferenceImageIndex).name;
    
        % Load the random interference image
        [InterferenceImageLoad, map, alpha] = imread(fullfile('TestObjectsTransparent', InterferenceImageFilename));
    
        if interferenceImageSelection == luckyNumberRight
            newinterferenceColourDegree = interferenceColourDegree + 90;
            
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', InterferenceImageLoad);
            % Fetch the colour
            interferenceRgb = RotateImage(savedLab, newinterferenceColourDegree);
    
        else
            % Convert the image to LAB only once to speed up color rotations:
            savedLab = colorspace('rgb->lab', InterferenceImageLoad);
            % Fetch the colour
            interferenceRgb = RotateImage(savedLab, interferenceColourDegree);
        end
    
        % Preserve the alpha channel
        interferenceRgb(:,:,4) = alpha;
    
        % Create texture and store it in the list
        interferenceTargetTexture = Screen('MakeTexture', win, interferenceRgb);
        listOfInterferenceTextures{interferenceImageSelection} = interferenceTargetTexture;
    end
    
    % Define circle properties
    numImages = 6;  % Number of images
    radius = 400;   % Adjust the radius as needed
    
    % Angle between each image (in radians)
    theta = linspace(0, 2*pi, numImages + 1);
    theta = theta(1:end-1);  % Remove the last angle to avoid overlap

    Screen('DrawTexture', win, randomBackgroundImageTexture)
    
    % Loop through the textures and draw them in a circle
    for i = 1:numImages
        % Calculate position for each image in the circle
        xPos = centerX + radius * cos(theta(i));
        yPos = centerY + radius * sin(theta(i));
        
        % Center the 'stimRect' around the calculated (xPos, yPos)
        destRect = CenterRectOnPoint(stimRect, xPos, yPos);


        
        % Draw the texture at the calculated position
        Screen('DrawTexture', win, listOfInterferenceTextures{i}, [], destRect);
    end
    
    % Flip the screen to display the images
    Screen('Flip', win);
    
    % Wait for user input
    keyPressed = '';
    while ~ismember(keyPressed, {'a', 'd'})
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key presses
        if keyIsDown
            if keyCode(KbName('A')) % If 'A' is pressed
                keyPressed = 'a';
                selectedSide = 1; % Left
            elseif keyCode(KbName('D')) % If 'D' is pressed
                keyPressed = 'd';
                selectedSide = 2; % Right
            end
        end
    end


    if selectedSide == 1
        interferenceSelection(trial) = "Left Selection";
    elseif selectedSide == 2
        interferenceSelection(trial) = "Right Selection";
    end
    
    if selectedSide == 1 && (luckyNumberRight == 5 || luckyNumberRight == 4 || luckyNumberRight == 3 )
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        DrawFormattedText(win, 'Correct Side!', 'center', 'center', [0, 200, 0]);
    elseif selectedSide == 2 && (luckyNumberRight == 2 || luckyNumberRight == 1 || luckyNumberRight == 6 )
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        DrawFormattedText(win, 'Correct Side!', 'center', 'center', [0, 200, 0]);
    else
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        DrawFormattedText(win, 'Incorrect Side!', 'center', 'center', [255, 0, 0]);
    
    end
                        
    
    Screen('Flip', win);
    WaitSecs(0.1);    
        
        
  
  elseif strcmp(interferenceCommands{trial}, 'No Interference')

        engageInterference=false;
        
        interferencePresence(trial)=2;
        
        if mod(trial,6)==1
            firstInterference(trial)='No Interference';
        elseif mod(trial,6)==5
            fifthInterference(trial)='No Interference';
        end
      

        
        Screen('DrawTexture', win, randomBackgroundImageTexture);
        % WaitSecs('UntilTime',retention_onset + 0.6 - 0.5*ifi); 
        [~, retention_onset2] = Screen('Flip', win);

        Screen('DrawTexture', win, randomBackgroundImageTexture);
        % WaitSecs('UntilTime',retention_onset2 + 0.8 - 0.5*ifi); 
        [~, retention_onset2] = Screen('Flip', win);
       

  end


%%%%%%%%%%%%%Interference Phase%%%%%%%%%%%%%
    
rounderE=GetSecs;
    
    
%%%%%%%%%%%%%Test Phase%%%%%%%%%%%%%%%%%%%%

   
    WaitSecs(0.4);
    Screen('DrawTexture', win, randomBackgroundImageTexture);
    % if engageInterference
    %     WaitSecs('UntilTime',interferenceOff + 0.4 - 0.5*ifi); 
    % end
    
    
    timee=rounderE-rounderS;
    disp(timee);
    disp(miniBlockEnd);
    

    temp=Shuffle(0:45:315);
    randomAddition=temp(1);
    
    startTimeOnset = GetSecs;
    startTimeMove = GetSecs;
    % Show in grayscale:
    [originalImg, map, alpha] = imread(fullfile('TestObjectsTransparent',currentTargetFilename)); 
    % originalImg = imresize(originalImg, [stim.size stim.size]); 
    imgGray = repmat(mean(originalImg,3), [1 1 3]);
    imgGray(:,:,4)=alpha;

    curTexture = Screen('MakeTexture', win, imgGray);
    Screen('DrawTexture', win, curTexture, [], stimRect);
    
    % Show color report circle:
    
    Screen('FrameOval', win, [128,128,128], colorWheel.rect);
    Screen('Flip', win);

    % Center mouse
    SetMouse(centerX,centerY,win);
      
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', originalImg);
    
    % Wait until the mouse moves:
    [curX,curY] = GetMouse(win);
    while (curX == centerX && curY == centerY)
      [curX,curY] = GetMouse(win);
    end

    
    endTimeMove = GetSecs;
      
    % Show object in correct color for current angle and wait for click:
    buttons = [];

   
    

    while ~any(buttons)  
      
      
      [curX,curY, buttons] = GetMouse(win);
      curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
      [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
      [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
      
   
               
      if (curAngle ~= currentColourDegree) && round(curAngle) ~= 0 
        newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
        newRgb(:,:,4)=alpha;
        Screen('Close', curTexture);
        curTexture = Screen('MakeTexture', win, newRgb);
      end
      
      % Show stimulus:
      
      Screen('DrawTexture', win, randomBackgroundImageTexture);
      
      % Draw frame and dot
      Screen('FrameOval', win, [128,128,128], colorWheel.rect);
      Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);

      Screen('DrawTexture', win, curTexture, [], stimRect);
      
      
      Screen('Flip', win);

      
      
      % Allow user to quit on each frame:
      [~,~,keys]=KbCheck;
      if keys(KbName('q')) && keys(KbName('7'))
        sca; error('User quit');
      end
    
    
    end
    
    
    Screen('Close', curTexture);
    
    
    % Wait for release of mouse button
    while any(buttons), [~,~,buttons] = GetMouse(win); end

    
    endTimeOnset = GetSecs;
    
    timeElapsedOnset = abs(endTimeOnset - startTimeOnset);
    timeElapsedMove = abs(endTimeMove - startTimeMove);

    onsetTime(trial) = timeElapsedOnset;
    moveTime(trial) = timeElapsedMove;
    
    
    %Correct for circular space degrees
    angular_disparity=(currentColourDegree-(curAngle+randomAddition));
    if angular_disparity>180
        angular_disparity=angular_disparity-360;
    elseif angular_disparity<-180
        angular_disparity=angular_disparity+360;
    end
    
    angularDisparity(trial)=angular_disparity;
    disparityRates = [disparityRates, abs(angular_disparity)];

    Screen('DrawTexture', win, randomBackgroundImageTexture);
    Screen('DrawText', win, ['Angular Disparity Rate: ' num2str(round(abs(angular_disparity)))], centerX-125, centerY-525, [250 0 0]); 
    if abs(angular_disparity) <= 5
        Screen('DrawText', win, 'Excellent!', centerX-30, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 5 && abs(angular_disparity) <= 15
        Screen('DrawText', win, 'Great!', centerX-45, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 15 && abs(angular_disparity) <= 25
        Screen('DrawText', win, 'Nice!', centerX-30, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 25 && abs(angular_disparity) <= 35
        Screen('DrawText', win, 'Not Bad', centerX-45, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 35
        Screen('DrawText', win, 'Could be better', centerX-80, centerY-475, [250 0 0]);
    end
    
    
    Screen('Flip', win);
    WaitSecs(0.75);


    usedAngels(:, end + 1) = {currentTargetFilename; currentColourDegree};
    previousColourDegree=currentColourDegree;

    
    
    if trial>=1
        miniBlockEnd=miniBlockEnd+1;
    end
    
    
   
    
    disp(trial);

    dataMatrix = [participantNumber1, trialNumber, resultColumnVector, contextChange, interferencePresence, angularDisparity, conditionUsed, targetPresented, onsetTime, moveTime, interferenceSelection, firstContext, firstInterference, fifthContext, fifthInterference, blocks, breakTime];
    % Specify the file name
    fileName = ['output_data', num2str(participantNumber), '.csv'];
    
    % Write the matrix to a CSV file
    writematrix(dataMatrix, fileName);

   
    
end  


%%%%%%%%%%%%%Test Phase%%%%%%%%%%%%%%%%


%%%%%%%%%%Actual Experiment Ends%%%%%%%%%




disp('Data saved successfully.');






%%%%%%%%SURPRISE MEMORY TASK BEGINS%%%%%%%%%%

leadInImage= imread('leadintosurpriseENG.png');
leadInImageTexture = Screen('MakeTexture', win, leadInImage);
Screen('DrawTexture', win, leadInImageTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;

WaitSecs(2)


% Flip the screen to show the text
Screen('Flip', win);



instructionsImage= imread('instructionsSurpriseENG.png');
instructionsImageTexture = Screen('MakeTexture', win, instructionsImage);
Screen('DrawTexture', win, instructionsImageTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;

WaitSecs(2)

Screen('Flip', win);


uniqueTargets = unique(usedTargets);
non_empty_idx = ~strcmp(uniqueTargets, "");
filteredUniqueTargets = uniqueTargets(non_empty_idx);

allTargetsCell = {listOfTargets.name};
allTargetsString = string(allTargetsCell');
availableTargets = setdiff(allTargetsString, filteredUniqueTargets);


for surpriseTrial = 1:(numel(filteredUniqueTargets))
    
    participantNumber2(surpriseTrial) = participantNumber;
    trialNumber2(surpriseTrial) = surpriseTrial;
    

    randomSurpiseIndex = randi(numel(filteredUniqueTargets));
    randomSurpriseTargetFilename = filteredUniqueTargets{randomSurpiseIndex};
    remove_UsedTarget = string(randomSurpriseTargetFilename);
    targetPresented2(surpriseTrial) = randomSurpriseTargetFilename;
    
    filteredUniqueTargets = setdiff(filteredUniqueTargets,remove_UsedTarget);
    
    
    randomSurpriseDistractorIndex = randi(length(availableTargets));
    randomSurpriseDistractorFilename = availableTargets(randomSurpriseDistractorIndex); 
    distractorPresented(surpriseTrial) = randomSurpriseDistractorFilename;
    
    
    
    [image1, map, alpha] = imread(randomSurpriseTargetFilename);
    image1Gray = repmat(mean(image1,3), [1 1 3]);
    image1Gray(:,:,4)=alpha;
    
    [image2, map, alpha] = imread(randomSurpriseDistractorFilename);
    image2Gray = repmat(mean(image2,3), [1 1 3]);
    image2Gray(:,:,4)=alpha;
  

    
    texture1 = Screen('MakeTexture', win, image1Gray);
    texture2 = Screen('MakeTexture', win, image2Gray);
    
    
    imageSize = size(image1);
    stimRect1 = [0, 0, imageSize(2), imageSize(1)];
    
    imagePosition1=[centerX-640, centerY]; 
    imagePosition2=[centerX+640, centerY];
    
    textureList={texture1,texture2};
    shuffledIndices = randperm(2);
    shuffledTextureList = textureList(shuffledIndices);
    
    
    Screen('DrawTexture', win, shuffledTextureList{1}, [], CenterRectOnPoint(stimRect1, imagePosition1(1), imagePosition1(2))); %%left image
    Screen('DrawTexture', win, shuffledTextureList{2}, [], CenterRectOnPoint(stimRect1, imagePosition2(1), imagePosition2(2))); %%right image

    
    textureList={};

    if surpriseTrial ~= 1
        Screen('Flip', win);
    end
    
    
    
    KbName('UnifyKeyNames');
    leftArrowKey = KbName('a');
    rightArrowKey = KbName('d');
    
    

    if surpriseTrial == 1
        
        if texture1 == shuffledTextureList{1} 
            Screen('DrawText', win, ['Since the image you have seen before is on the left, you need to press the left arrow key.'], centerX-650, centerY-400, [250 0 0]);
            Screen('DrawText', win, ['Please indicate the image colour after keypress.'], centerX-300, centerY-300, [250 0 0]);
            Screen('Flip', win);
        end
        
        if texture1 == shuffledTextureList{2}
            Screen('DrawText', win, ['Since the image you have seen before is on the right, you need to press the right arrow key.'] , centerX-650, centerY-400, [250 0 0]); 
            Screen('DrawText', win, ['Please indicate the image colour after keypress.'], centerX-300, centerY-300, [250 0 0]);
            Screen('Flip', win);
        end
    end

    

    true;
    
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
            
       if keyIsDown
        if ~keyCode(leftArrowKey) && ~keyCode(rightArrowKey)
            % If neither right nor left is keyed in, do nothing
        elseif keyCode(leftArrowKey) && texture1 == shuffledTextureList{1}
            % If left is keyed and target is on the left, correct choice
            trueOrFalse(surpriseTrial) = 1;
            break;
        elseif keyCode(rightArrowKey) && texture1 == shuffledTextureList{2}
            % If right is keyed and target is on the right, correct choice
            trueOrFalse(surpriseTrial) = 1;
            break;
        else
            % Incorrect choice
            trueOrFalse(surpriseTrial) = 2;
            warningImage = imread('yanlisgorselENG.png');
            warningImageTexture = Screen('MakeTexture', win, warningImage);
            Screen('DrawTexture', win, warningImageTexture);
            Screen('Flip', win);
            WaitSecs(2);
            break;
        end
       end
    end
        
    
    
    temp=Shuffle(0:45:315);
    randomAddition=temp(1);

    startTimeOnsetSurprise = GetSecs;
    startTimeMoveSurprise = GetSecs;
    
    indexDF = find(ismember(usedAngels(1, :), randomSurpriseTargetFilename));
    if ~isempty(indexDF)
        currentColourDegree = usedAngels{2, indexDF};
    end

    
    % Show in grayscale:
    [image1, map, alpha] = imread(randomSurpriseTargetFilename); 
    % image1 = imresize(image1, [stim.size stim.size]); 
    image1Gray = repmat(mean(image1,3), [1 1 3]);
    image1Gray(:,:,4)=alpha;

    image1GrayTexture = Screen('MakeTexture', win, image1Gray);
    Screen('DrawTexture', win, image1GrayTexture, [], stimRect);
    
    % Show color report circle:
    
    Screen('FrameOval', win, [128,128,128], colorWheel.rect);
    Screen('Flip', win);
      
    % Center mouse
    SetMouse(centerX,centerY,win);
      
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', image1);
    
    % Wait until the mouse moves:
    [curX,curY] = GetMouse(win);
    while (curX == centerX && curY == centerY)
      [curX,curY] = GetMouse(win);
    end


    endTimeMoveSurprise = GetSecs;
      
    % Show object in correct color for current angle and wait for click:
    buttons = [];
    while ~any(buttons)  
        
      [curX,curY, buttons] = GetMouse(win);
      curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
      [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
      [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
      
      % Draw frame and dot
      Screen('FrameOval', win, [128,128,128], colorWheel.rect);
      Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
      

                   
      if (curAngle ~= currentColourDegree) && round(curAngle) ~= 0 
        newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
        newRgb(:,:,4)=alpha;
        Screen('Close', image1GrayTexture);
        image1GrayTexture = Screen('MakeTexture', win, newRgb);
      end
      
      % Show stimulus:
      Screen('DrawTexture', win, image1GrayTexture, [], stimRect);
      Screen('Flip', win);
      
      % Allow user to quit on each frame:
      [~,~,keys]=KbCheck;
      if keys(KbName('q')) && keys(KbName('7'))
        sca; error('User quit');
      end
    end
    Screen('Close', image1GrayTexture);
    
    % Wait for release of mouse button
    while any(buttons), [~,~,buttons] = GetMouse(win); end



    endTimeOnsetSurprise = GetSecs;
    
    timeElapsedOnsetSurprise = abs(endTimeOnsetSurprise - startTimeOnsetSurprise);
    timeElapsedMoveSurprise = abs(endTimeMoveSurprise - startTimeMoveSurprise);

    onsetTimeSurprise(surpriseTrial) = timeElapsedOnsetSurprise;
    moveTimeSurprise(surpriseTrial) = timeElapsedMoveSurprise;
    
    
    %Correct for circular space degrees
    angular_disparity=(currentColourDegree-(curAngle+randomAddition));
    if angular_disparity>180
        angular_disparity=angular_disparity-360;
    elseif angular_disparity<-180
        angular_disparity=angular_disparity+360;
    end
    
    
    angularDisparity2(surpriseTrial)=angular_disparity;

    Screen('DrawText', win, ['Angular Disparity Rate: ' num2str(round(abs(angular_disparity)))], centerX-125, centerY-525, [250 0 0]); 
    if abs(angular_disparity) <= 5
        Screen('DrawText', win, 'Excellent!', centerX-30, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 5 && abs(angular_disparity) <= 15
        Screen('DrawText', win, 'Great!', centerX-45, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 15 && abs(angular_disparity) <= 25
        Screen('DrawText', win, 'Nice!', centerX-30, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 25 && abs(angular_disparity) <= 35
        Screen('DrawText', win, 'Not Bad', centerX-45, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 35
        Screen('DrawText', win, 'Could be better', centerX-80, centerY-475, [250 0 0]);
    end

    Screen('Flip', win);
    WaitSecs(0.75); 

    previousColourDegree=currentColourDegree;


    if surpriseTrial==1
        endOfSurprisePractice= imread('endofsurprisepracticeENG.png');
        endOfSurprisePracticeTexture = Screen('MakeTexture', win, endOfSurprisePractice);
        Screen('DrawTexture', win, endOfSurprisePracticeTexture);


        % Flip the screen to show the text
        Screen('Flip', win);

        % Wait for a key press to continue
        KbWait;

        WaitSecs(2)
    end
    
    dataMatrix2 = [participantNumber2, trialNumber2, trueOrFalse, angularDisparity2, targetPresented2, distractorPresented, onsetTimeSurprise, moveTimeSurprise];
    
    % Specify the file name
    fileName2 = ['output_dataSurprise', num2str(participantNumber), '.csv'];
    
    % Write the matrix to a CSV file
    writematrix(dataMatrix2, fileName2);


end
    


%%%%%%%%SURPRISE MEMORY TASK ENDS%%%%%%%%%%%




disp('Surprise data saved successfully.');


endOfExperimentImage= imread('endofexperimentENG.png');
endOfExperimentImageTexture = Screen('MakeTexture', win, endOfExperimentImage);
Screen('DrawTexture', win, endOfExperimentImageTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;


% Clean up
  Screen('CloseAll');




  
  
  
  
  
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
