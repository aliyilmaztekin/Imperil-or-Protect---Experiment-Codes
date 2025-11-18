% IN THE FINAL VERSION OF EXPERIMENT 4, THE SURPRISE PHASE HAS BEEN SCRAPPED

% Lead the participant into the surprise task
DrawFormattedText(window, leadInToSurprise, 'center', 'center', [128 128 128]);

% Flip to show it
Screen('Flip', window);

% Wait for space key
waitForSpace();

% Lead the participant into the surprise task
DrawFormattedText(window, surpriseInstructions, 'center', 'center', [128 128 128]);

% Flip to show it
Screen('Flip', window);

% Wait for space key
waitForSpace();

for surpriseTrial = 1:120

    %% FRAME 0: IMAGE RANDOMIZATION
    surpriseTargetImage = 0;
    surpriseFoilImage = 0;

    % Position the images based on a random index. 
    % 1 = position on the left 
    % 2 = position on the right
    surpriseDuo = [surpriseTargetImage surpriseFoilImage];           % two elements
    surpriseLottery = randi(2);          % randomly pick 1 or 2 

    leftImageTexture = surpriseDuo(surpriseLottery);                   % chosen element
    rightImageTexture = surpriseDuo(3 - (surpriseLottery));          % the unchosen element

    % When the positions are assigned, start drawing them on the screen

    Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);
    Screen('DrawTexture', window, leftImageTexture, [], leftImagePosition);
    Screen('DrawTexture', window, rightImageTexture, [], rightImagePosition);

    Screen('Flip', window);

    %% FRAME 1: RECOGNITION TASK

    % Lock down a response loop around the images until a response keyed in
    while true
    [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(leftKey)
                if leftImageTexture == surpriseTargetImage
                    trueOrFalse(surpriseTrial) = 1; % correct
                else
                    trueOrFalse(surpriseTrial) = 2; % incorrect
                    Screen('FillRect', window, [255 255 255]);
                    DrawFormattedText(window, surpriseWarning, 'center', 'center', [255 0 0]);
                    Screen('Flip', window);
                    WaitSecs(2.5);
                end

                break; % exit loop after left key handled

            elseif keyCode(rightKey)
                if rightImageTexture == surpriseTargetImage
                    trueOrFalse(surpriseTrial) = 1; % correct
                else
                    trueOrFalse(surpriseTrial) = 2; % incorrect
                    Screen('FillRect', window, [255 255 255]);
                    DrawFormattedText(window, surpriseWarning, 'center', 'center', [255 0 0]);
                    Screen('Flip', window);
                    WaitSecs(2.5);
                end

                break; % exit loop after right key handled
            end
        end
    end

    %% FRAME 2: PROBE DISPLAY

    % Increment the color wheel position by a random degree
    temp=Shuffle(0:45:315);
    randomAddition=temp(1);



    % Get the color degree of the probe image
    toBeTestedColorDegree = 0;

    Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);

    curTexture = texHandlesThrice();

    Screen('DrawTexture', window, curTexture, [], stimRect);

    % Show color report circle:

    Screen('FrameOval', window, [0 0 0], colorWheel.rect);

    % TIMESTAMP: The probe display has appeared in greyscale.  
    [~, greyscaleOnset] = Screen('Flip', window, retentionDisplay2Offset);

    % Center mouse
    SetMouse(centerX,centerY,window);

    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', originalImg);

    % Wait until the mouse moves:
    [curX,curY] = GetMouse(window);
    while (curX == centerX && curY == centerY)
      [curX,curY] = GetMouse(window);
    end

    % TIMESTAMP: The participant has made the first mouse movement. 
    firstMouseMovement = GetSecs();

    % Show object in correct color for current angle and wait for click:
    buttons = [];

    while ~any(buttons)  

      [curX,curY, buttons] = GetMouse(window);
      curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
      [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
      [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);


      if (curAngle ~= toBeTestedColorDegree) && round(curAngle) ~= 0 
        newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
        newRgb(:,:,4)=alpha;
        Screen('Close', curTexture);
        curTexture = Screen('MakeTexture', window, newRgb);
      end

      % Show stimulus:

      Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);

      % Draw frame and dot
      Screen('FrameOval', window, [0,0,0], colorWheel.rect);
      Screen('DrawLine', window, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);

      Screen('DrawTexture', window, curTexture, [], stimRect);   

      Screen('Flip', window);

      % Allow user to quit on each frame:
      [~,~,keys]=KbCheck;
      if keys(KbName('q')) && keys(KbName('7'))
        sca; error('User quit');
      end

    end

    % TIMESTAMP: MOUSE CLICK - RESPONSE IS MADE
    responseEnd = GetSecs;

    Screen('Close', curTexture);

    % Wait for release of mouse button
    while any(buttons), [~,~,buttons] = GetMouse(window); end

    % Wrap angles to [0,360)
    toBeTestedColorDegree = mod(toBeTestedColorDegree, 360);
    curAngle = mod(curAngle + randomAddition, 360);

    % Compute angular disparity
    angular_disparity = toBeTestedColorDegree - curAngle;
    % Wrap to [-180,180)
    angular_disparity = mod(angular_disparity + 180, 360) - 180;
    angularDisparity(trial) = angular_disparity;

    % Time from probe onset to first movement
    mouseOnsetDuration = mouseOnset - greyscaleOnset;
    mouseOnset(trial) = mouseOnsetDuration;

    % Time from first movement to click
    movementDuration = responseEnd - mouseOnset;
    decisionTime(trial) = movementDuration;

    % Full response time (onset → click)
    totalResponseTime = responseEnd - greyscaleOnset;
    RTActual(trial) = totalResponseTime;


    %% FRAME 3: FEEDBACK
    Screen('FillRect', window, [255 255 255], [0 0 screenWidth screenHeight]);

    % First line: Angular Disparity Rate
    disparityText = ['Angular Disparity Rate: ' num2str(round(abs(angular_disparity)))];
    bounds = Screen('TextBounds', window, disparityText);
    xPos = centerX - (bounds(3)-bounds(1))/2;
    yPos = centerY - 100;  % start above center
    Screen('DrawText', window, disparityText, xPos, yPos, textColor);

    % Second line: Feedback message
    if abs(angular_disparity) <= 5
        feedbackText = 'Excellent!';
    elseif abs(angular_disparity) > 5 && abs(angular_disparity) <= 15
        feedbackText = 'Great!';
    elseif abs(angular_disparity) > 15 && abs(angular_disparity) <= 25
        feedbackText = 'Nice!';
    elseif abs(angular_disparity) > 25 && abs(angular_disparity) <= 35
        feedbackText = 'Not Bad';
    else
        feedbackText = 'Could be better';
    end

    bounds = Screen('TextBounds', window, feedbackText);
    xPos = centerX - (bounds(3)-bounds(1))/2;
    yPos = yPos + lineSpacing;  % below the first line
    Screen('DrawText', window, feedbackText, xPos, yPos, textColor);

    [~, feedbackOnset] = Screen('Flip', window);
    feedbackOffset = feedbackOnset + feedbackDuration - ifi / 2; 



end
