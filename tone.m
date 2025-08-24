function [x] = tone(freq,duration,Fs)
%Tone: generate an 16-bit depth sine wave tone called x: of frequency 
%freq (Hz) with sample frequency Fs (also Hz) 
%for a duration of duration (ms)
%   Detailed explanation goes here
if nargin < 3
    Fs = 11025;
end
t = 0:1/Fs:duration/1000;
x = sin(2*pi*freq*t);
end