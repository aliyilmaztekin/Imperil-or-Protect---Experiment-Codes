function waitForSpace()
% WAITFORSPACE Waits until the participant presses the SPACE key
%   Includes a small delay to reduce CPU usage and avoids multiple detections

spaceKey = KbName('space');  % get key code for space

while true
    [keyIsDown, ~, keyCode] = KbCheck;  % check keyboard
    if keyIsDown && keyCode(spaceKey)
        % Wait until key is released to avoid multiple detections
        while KbCheck; end
        break;  % exit loop
    end
    WaitSecs(0.01);  % 10 ms delay to reduce CPU usage
end
end
