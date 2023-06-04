% Open port to receive ALC UDP messages
hUdp = PnetClass(14001);
hUdp.initialize()

%% Preview EMG
StartStopForm([]);
numChannels = 16;
numSamples = 10;
h = LivePlot(numChannels,1500);
while StartStopForm
    cellNewData = hUdp.getAllData;
    for i = 1:length(cellNewData)
        thisDataArray = typecast(cellNewData{i},'single');
        thisData = reshape(thisDataArray,[numSamples, numChannels]);
        for j = 1:size(thisData,1)
            h.putdata(thisData(j,:));
        end
    end
    drawnow
end

%% Check Log Parsing Parameters
% example datestamp from log (in milliseconds)
convertTime = @(posixtime)datetime(posixtime,'ConvertFrom','posixtime','TimeZone','America/New_York');
t = 1673812602974;
convertTime(t/1000); %15-Jan-2023 14:56:42

v = ['00008035000040360000E0360000803500004036000080B50000A0B6000080B50000E0B600004036000010370000A0B6000040B60000E0B60000A0360000A036000040B6000080B5000010B700004' ...
    '0360000103700004036000040B6000040360000E036000030B7000040B60000A0360000E0B6000040B6000040B6000080B50000803500008035000010B70000A036000080B50000E0B600008035000' ...
    '0E0B60000A0B6000080B50000303700004036000040B6000040B6000010B70000A036000010B7000080B5000040B6000010370000A0B6000080B50000A0B6000080350000403600008035000040B60' ...
    '0008035000040360000A0B60000E0B600003037000040360000A0360000E0B6000080350000E0B600004036000080350000803500004036000040B60000E0360000A0B600003037000040B6000040B' ...
    '600004036000080B500008035000010B7000010370000A0B60000E0B60000A036000040B60000A0B60000403600004036000010B70000A0360000E0B600001037000080B5000040B60000A03600008' ...
    '0350000803500004036000080B500004036000080B50000A036000030B70000E036000040360000A0B6000080B50000403600001037000040B60000A0B600001037000080350000E0B60000A036000' ...
    '040B6000040360000E036000080B5000040360000A0B60000E036000040B600008035000040B6000040B6000010370000803500008035000080B50000403600004036000030B70000A0B6000010370' ...
    '00010B7000080B50000A0B60000A036000010B7000080B5000010370000E0B600004036000080B5000080350000303700007037000080350000A0B60000E0B600008035000080B50000E0B60000E03' ...
    '6000030B70000A036'];
f = double(typecast(uint8(hex2dec(reshape(v,2,[])')),'single'));
numChannels = 16;
numSamples = 10;
emgData = reshape(f,[numSamples, numChannels]);


%%  Feature Stream
hUdp = PnetClass(23456);
hUdp.initialize()

%%
StartStopForm([]);
numChannels = 16;
numFeatures = 4;
iFeature = 1;  % 1=MAV 2=CurveLen 3=ZC 4 = SSC
h = LivePlot(numChannels,100);
while StartStopForm
    cellNewData = hUdp.getAllData;
    for i = 1:length(cellNewData)
        thisDataArray = typecast(cellNewData{i},'single');
        thisData = thisDataArray(iFeature:numFeatures:numChannels*numFeatures);
        h.putdata(thisData);
    end
    drawnow
end
