%% Section 1. Manage paths and files
clear

dataLocation = uigetdir();

searchTerm = strcat(dataLocation,'/*.dcm');
files = dir(searchTerm);
numFiles = size(files,1);

%% Section 2. Extract the slice locations and corresponding tube currents
sliceLocation = zeros(numFiles,1);
tubeCurrent = zeros(numFiles,1);

fpop = msgbox("Processing data ... please wait!");

for i=1:numFiles
    
    imagePath = fullfile(files(i).folder,files(i).name);
   
    dicomMeta = dicominfo(imagePath);
    
    tagName = dicomlookup('20','1041'); % Slice Location
    sliceLocation(i) = dicomMeta.(tagName); % mm
    
    tagName = dicomlookup('18','1151'); % X-Ray Tube Current
    tubeCurrent(i) = dicomMeta.(tagName); % mAs
end

if ishandle(fpop)
    close(fpop)
end

[~,I] = sort(sliceLocation);

tubeCurrent = tubeCurrent(I);
sliceLocation = sliceLocation(I);

%% Section 3. Generate a synthetic radiograph
[rawDicomVolume, ~, ~] = dicomreadVolume(dataLocation);

rawDicomVolume = squeeze(rawDicomVolume);
dicomVolume = rawDicomVolume*dicomMeta.RescaleSlope + dicomMeta.RescaleIntercept ...
    + 1000; 

dicomVolume(dicomVolume<-24) = 0;

syntheticRadiographAP = squeeze(mean(dicomVolume,1));
syntheticRadiographLAT = squeeze(mean(dicomVolume,2));

%% Section 4. Plot results
fh = figure();
fh.WindowState = 'maximized';
fh.Visible = 'on';

% Subplot 1
subplot(2,2,1)

colormap gray;

sliceLocationMin = min(sliceLocation); 
sliceLocationMax = max(sliceLocation); 
numPixels = size(syntheticRadiographAP,1);
imgXValues = linspace(sliceLocationMin, sliceLocationMax, numFiles);
imgYValues = linspace(0, numPixels-1, numPixels);

imagesc(imgXValues,imgYValues,flip(syntheticRadiographAP))
axis xy

title('Synthetic radiograph of phantom (anterior-posterior)')
xlabel('Distance [mm]')
ylabel('Pixel [#]')

% Subplot 2
subplot(2,2,2)

colormap gray;

imagesc(imgXValues,imgYValues,flip(syntheticRadiographLAT))
axis xy

title('Synthetic radiograph of phantom (lateral)')
xlabel('Distance [mm]')
ylabel('Pixel [#]')

% Subplot 3
subplot(2,2,3)

plot(sliceLocation,tubeCurrent)
ylim([0 1.05*max(tubeCurrent)])
xlim([min(sliceLocation) max(sliceLocation)])

title('Tube current modulation')
xlabel('z-axis position [mm]')
ylabel('Tube current [mA]')

% Subplot 4
subplot(2,2,4)

colormap gray;

tubeCurrentMin = 0;
tubeCurrentMax = max(max(tubeCurrent))*1.05;
imgYValues = linspace(tubeCurrentMin, tubeCurrentMax, numFiles);

imagesc(imgXValues, imgYValues,flip(syntheticRadiographLAT))
axis xy
hold on

plot(sliceLocation, tubeCurrent, '.');
xlabel('z-axis position [mm]')
ylabel('Tube current [mA]')

title('Tube current modulation and synthetic radiograph')
xlim([min(sliceLocation) max(sliceLocation)])
ylim([0 1.05*max(tubeCurrent)])
