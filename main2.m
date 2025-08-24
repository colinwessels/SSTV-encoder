% Colin Wessels
% 8/23/2025

% This script takes in an image and outputs a .wav file encoded with
% Scottie 1 for SSTV (slow-scan television). 
% Relavent resources:
% http://www.barberdsp.com/downloads/Dayton%20Paper.pdf
% https://radio.clubs.etsit.upm.es/blog/2019-08-10-sstv-scottie1-encoder/
% https://github.com/CKegel/Web-SSTV
% https://www.n2wu.com/2021-01-31-sstv-in-matlab/
% https://www.mathworks.com/matlabcentral/answers/217746-implementing-a-sine-wave-with-linearly-changing-frequency
% for going back to image: https://github.com/colaclanth/sstv

clear

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
vis = cat(2,vis,tone(1300,30)); % Parity bit: "Even". To maintain a total of 4 "1"s.
vis = cat(2,vis,tone(1200,30)); % Stop bit

header = cat(2,calheader,vis);
header = cat(2, vox, header);

%% IMAGAE DATA
% Brightness conversion: 0 = 1500 Hz, 255 = 2300 Hz.
% freq = 1500+3.1372549*brightness
% 0.4320 ms per pixel, 138.240 ms per line for 320 cols.

t_pixel = 0.4320; % ms
t_vect = 0:1/Fs:t_pixel*size(source,2)/1000;
freq_const = 3.1372549;

signal = cat(2, header, tone(1200, 9)); % first line only sync pulse
for rownum = 1:size(source,1)
    line = tone(1500,1.5);           % Seperator pulse
    
    green_line = source(rownum,:,1); % Scan green line
    green_freq = green_line.*freq_const+1500;
    green_interp = interp1(1:length(green_freq),green_freq,linspace(1,length(green_freq),length(t_vect)), 'nearest');
    line = cat(2, line, sin(2*pi*cumsum(green_interp/Fs))); % see fmmod for using cumsum to find instantaneous phase.

    line = cat(2, line, tone(1500,1.5)); % Seperator pulse

    blue_line = source(rownum,:,2); % Scan blue line
    blue_freq = blue_line.*freq_const+1500;
    blue_interp = interp1(1:length(blue_freq),blue_freq,linspace(1,length(blue_freq),length(t_vect)), 'nearest');
    line = cat(2, line, sin(2*pi*cumsum(blue_interp/Fs)));

    line = cat(2, line, tone(1200,9));   % Sync pulse
    line = cat(2, line, tone(1500,1.5)); % Sync porc

    red_line = source(rownum,:,3); % Scan red line
    red_freq = red_line.*freq_const+1500;
    red_interp = interp1(1:length(red_freq),red_freq,linspace(1,length(red_freq),length(t_vect)), 'nearest');
    line = cat(2, line, sin(2*pi*cumsum(red_interp/Fs)));

    signal = cat(2,signal,line); % add line to signal
end


%% WRITE OUT
audiowrite("out.wav",signal,Fs,BitsPerSample=8);