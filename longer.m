clear

% this takes longer than main2 (a minute or so) but the output is higher quality.

Fs = 11025;
source = imread("GzFl8H7acAArWLm.jpeg");
source(:,:,[1 2 3]) = source(:,:,[2 3 1]); % R G B --> G B R. 
source = double(source); % convert to double for multiplication later

%% HEADER
% VOX tone
vox = tone(1900,100);
vox = cat(2,vox,tone(1500,100));
vox = cat(2,vox,tone(1900,100));
vox = cat(2,vox,tone(1500,100));
vox = cat(2,vox,tone(2300,100));
vox = cat(2,vox,tone(1500,100));
vox = cat(2,vox,tone(2300,100));
vox = cat(2,vox,tone(1500,100));

% Calibration Header
calheader = tone(1900,300);                  % leader tone
calheader = cat(2,calheader,tone(1200,10));  % break
calheader = cat(2,calheader,tone(1900,300)); % leader tone

% VIS Code: Scottie 1 is 60d (0111100). Least significant bit first.
vis = tone(1200,30);            % Start bit
vis = cat(2,vis,tone(1300,30)); % Bit 0: "0". 1 = 1100 Hz, 0 = 1300 Hz.
vis = cat(2,vis,tone(1300,30)); % Bit 1: "0".
vis = cat(2,vis,tone(1100,30)); % Bit 2: "1".
vis = cat(2,vis,tone(1100,30)); % Bit 3: "1".
vis = cat(2,vis,tone(1100,30)); % Bit 4: "1".
vis = cat(2,vis,tone(1100,30)); % Bit 5: "1".
vis = cat(2,vis,tone(1300,30)); % Bit 6: "0".
vis = cat(2,vis,tone(1300,30)); % Parity bit: "Even". Should be same as Bit 0.
vis = cat(2,vis,tone(1200,30)); % Stop bit

header = cat(2,calheader,vis);
header = cat(2, vox, header);

%% IMAGAE DATA
% Brightness conversion: 0 = 1500 Hz, 255 = 2300 Hz.
% freq = 1500+3.1372549*brightness
% 0.4320 ms per pixel, 138.240 ms per line for 320 cols.

t_pixel = 0.4320/1000;
sep_pulse = 1.5/1000;
sync_pulse = 9/1000;

duration = t_pixel*numel(source) + (sync_pulse+sep_pulse*3)*size(source,1) + sync_pulse; % duration after header in s
            % pixel brightnesses      seperator and sync pulses             first line sep
t_vect = 0:1/Fs:duration;
signal = zeros(1,length(t_vect));
freq_const = 3.1372549;

signal(t_vect < sync_pulse) = 1200; % first line only sync pulse
time = sync_pulse;
for rownum = 1:size(source,1)
    signal(t_vect >= time & t_vect < time+sep_pulse) = 1500; % Seperator pulse
    time = time+sep_pulse;
    
    for pixel = source(rownum,:,1) % Scan green line
        signal(t_vect >= time & t_vect < time+t_pixel) = pixel*freq_const+1500;
        time = time+t_pixel;
    end

    signal(t_vect >= time & t_vect < time+sep_pulse) = 1500; % Seperator pulse
    time = time+sep_pulse;

    for pixel = source(rownum,:,2) % Scan blue line
        signal(t_vect >= time & t_vect < time+t_pixel) = pixel*freq_const+1500;
        time = time+t_pixel;
    end

    signal(t_vect >= time & t_vect < time+sync_pulse) = 1200;% Sync pulse
    time = time + sync_pulse;
    signal(t_vect >= time & t_vect < time+sep_pulse) = 1500; % Sync porch
    time = time+sep_pulse;

    for pixel = source(rownum,:,3) % Scan red line
        signal(t_vect >= time & t_vect < time+t_pixel) = pixel*freq_const+1500;
        time = time+t_pixel;
    end
end

data = cat(2,header,sin(2*pi*cumsum(signal/Fs))); % see fmmod for using cumsum to get instantaneous phase

%% WRITE OUT
audiowrite("out.wav",data,Fs,BitsPerSample=8);