% post processing script


% remove old times
carTable = removevars(bigTable, "New mediapipe times");
carTable = removevars(carTable, "time");

% rearrange to where EMG time is leftmost column
carTable = movevars(carTable, "New EMG times", "Before", "currentData_1");

%output final data to csv
currentTime = datetime;
formattedTime = datestr(currentTime, 'yyyymmdd_HHMMSS');
filename = strcat('combined_', formattedTime, '.csv');
writetable(carTable, filename);