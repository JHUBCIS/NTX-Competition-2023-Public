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

% remove first ten seconds, and last 10 seconds
length = size(carTable);
length = length(1);
firstVal = carTable{1,1};
lastVal = carTable{length, 1};
dtx = duration(0, 0, 10);

while(carTable{1, 1} - firstVal < dtx)
    carTable(1,:) = [];
end
while(lastVal - carTable{end,1} < dtx)
    carTable(end, :) = [];
end


%% Reducing dimensions of mediapipe data (thumb, index+middle together, ring+pinky together)

for i = 1:height(carTable)
    carTable{i, 15} = (carTable{i, 11} + carTable{i, 12})/2;
    carTable{i, 16} = (carTable{i, 13} + carTable{i, 14})/2;
end

carTable = removevars(carTable, ["index", "middle", "ring", "little"]);
carTable = renamevars(carTable, ["Var15", "Var16"], ["index+middle", "ring+little"]);
%% Output final data to csv

currentTime = datetime;
formattedTime = datestr(currentTime, 'yyyymmdd_HHMMSS');
filename = strcat('combined_', formattedTime, '.csv');
writetable(carTable, filename);