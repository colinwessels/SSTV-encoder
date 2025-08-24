% SUPERSEEDED BY main2.m

clear

Fs = 44100;
t_pixel = 5; % ms
source = imread("input.jpg");
source(:,:,[1 2 3]) = source(:,:,[2 3 1]); % R G B --> G B R. 
source = double(source); % convert to double for multiplication later
%step1 = reshape(source,[],3); % col1 = R, col2 = G, col3 = B
%step1(:,[1 2 3]) = step1(:,[2 3 1]); % R G B --> G B R
%unwrapped = reshape(step1.',1,[]); % G B R G B R G B R ...

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
vis = cat(2,vis,tone(2300,30)); % Stop bit

header = cat(2,calheader,vis);
header = cat(2, vox, header);

%% IMAGAE DATA
% Brightness conversion: 0 = 1500 Hz, 255 = 2300 Hz.
% freq = 1500+3.1372549*brightness
% 0.4320 ms per pixel, 138.240 ms per line.
signal = cat(2, header, tone(1200, 9)); % first line only sync pulse
for rownum = 1:size(source,1)
    line = tone(1500,1.5);                                          % Seperator pulse
    for pixel = source(rownum,:,1)                                  % Green scan
        line = cat(2, line, tone(1500+3.1372549*pixel,t_pixel));
    end
    line = cat(2, line, tone(1500,1.5));                            % Seperator pulse
    for pixel = source(rownum,:,2)                                  % Blue scan
        line = cat(2, line, tone(1500+3.1372549*pixel,t_pixel));
    end
    line = cat(2, line, tone(1200,9));                              % Sync pulse
    line = cat(2, line, tone(1500,1.5));                            % Sync porch
    for pixel = source(rownum,:,3)                                  % Red scan
        line = cat(2, line, tone(1500+3.1372549*pixel,t_pixel));
    end
    signal = cat(2,signal,line);
end


%% WRITE OUT
audiowrite("out.wav",signal,Fs,BitsPerSample=8);