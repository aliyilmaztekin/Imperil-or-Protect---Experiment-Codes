%% Imperil Experiment 7
% Reshapes raw data to a long-format .mat file, ready for analysis

addpath('/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment7/prolific_pilot_data');
sbj2save = setdiff(1:10, [2, 5, 9]);

for curSbj = setdiff(5:10, 9)
    curTable = sprintf('imperil_exp7_pilot_%d.xlsx', curSbj);

    rawTable = readtable(curTable);

    cords = [rawTable.click_x(13:end), rawTable.click_y(13:end)];
    thetas = rawTable.click_theta(13:end);
    error = rawTable.abs_angular_error(13:end);
    binEdges = linspace(0, 180, 181);
    histogram(error, binEdges);

    break

    % nTrials = numel(thetas);
    % fprintf('%d trials, class %s\n', nTrials, class(thetas));
    % 
    % figure
    % subplot(1,3,1)
    % plot(1:nTrials, thetas, 'o-')
    % xlabel('Trial'); ylabel('Reported colour (deg)')
    % ylim([0 360]); yticks(0:45:360)
    % 
    % subplot(1,3,2)
    % polarhistogram(deg2rad(thetas), 36)
    % title('Reported colour')
    % 
    % subplot(1,3,3)
    % scatter(cords(:,1), cords(:,2), 20, 1:nTrials, 'filled')
    % axis equal; colorbar
    % title('Raw click position')

 

    % 
    % xAxis = 1:360;
    % figure
    % plot(1:360,thetas')
    % xticks(1:360)





    
    % The raw output contains data irrelevant to the analysis. Extract only the
    % important things.
    
    % Trial count (col6)
    % Repetition index (col9)
    % Context change index (col10)
    % Probing index (col13)
    % Angular error (signed) (col23)
    % Angular error (abs) (col24)
    % Reaction time (onset) (col28)
    % Reaction time (full) (col27)
    
    trial = 1:660;
    
    % First 12 trials are training. So we start at row 13. 
    rep = rawTable.rep(13:end);
    cont = rawTable.cond_context(13:end);
    probe = rawTable.probe(13:end);
    signError = rawTable.angular_error(13:end);
    absError = rawTable.abs_angular_error(13:end);
    rtOnset = rawTable.move_onset(13:end);
    rtFull = rawTable.rt(13:end);
    prolificID = rawTable.participant_id(13:end);
    
    format shortG % Turn off scientific notation
    resultsMatrix = [repelem(curSbj, 660, 1), trial', rep, cont, probe, signError, absError, rtOnset, rtFull];
    
    % Check how many responses were timed out
    countMiss = sum(ismissing(resultsMatrix(:,7)));
    
    % Performance metrics
    globalAvg = mean(absError,'omitnan');
    globalRt = mean(rtFull, 'omitnan');
    
    funForm = ('Participant ID: %d. Average Error is %3.2f with an average RT of %4.2f; %d trials missing\n');
   
    fprintf(funForm, curSbj, globalAvg, globalRt, countMiss);

    % if ismember(curSbj, sbj2save)
    % 
    %     outputDest = '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment7/pilot2analyze';
    %     if ~isfile(outputDest)
    %         mkdir(outputDest);
    %     end
    % 
    %     relativeDIR = [outputDest '/imperil7_beh_' num2str(curSbj) '.mat'];
    %     save(relativeDIR, "resultsMatrix");
    % 
    % end
end





% % % Some descriptive stats:
% % mean(resultsMatrix(:,end), 'omitnan')
% % mean(resultsMatrix(:,6), 'omitnan')
% 
% % Condition-wise error
% cond1 = resultsMatrix(:,2)==1 & resultsMatrix(:,3)==0 & resultsMatrix(:,4)==1;
% cond2 = resultsMatrix(:,2)==1 & resultsMatrix(:,3)==1 & resultsMatrix(:,4)==1;
% cond3 = resultsMatrix(:,2)==5 & resultsMatrix(:,3)==0 & resultsMatrix(:,4)==1;
% cond4 = resultsMatrix(:,2)==5 & resultsMatrix(:,3)==1 & resultsMatrix(:,4)==1;
% 
% combinedCond = [resultsMatrix(cond1,8);resultsMatrix(cond2,8);resultsMatrix(cond3,8);resultsMatrix(cond4,8)];
% binSubs = repelem([1 2 3 4]', sum(cond1 == 1), 1);
% 
% condAvgs = accumarray(binSubs, combinedCond, [4, 1], @(x) mean(x, 'omitnan'), NaN);
% 
% names = {'rep1 no-change (r)', 'rep1 change (r)', 'rep5 no-change (r)', 'rep5 change (r)'};
% for k = 1:numel(condAvgs)
%     fprintf('%-16s %6.3f\n', names{k}, condAvgs(k));
% end
% 
% repAvgs = accumarray(resultsMatrix(resultsMatrix(:,4) == 2,2), resultsMatrix(resultsMatrix(:,4) == 2,6), [6 1], ...
%                      @(x) mean(x,'omitnan'), NaN);
% 
% figure
% plot(1:6, repAvgs)
% xticks(1:6)