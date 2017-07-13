% This script acquires a short sample of the extracellular
% voltage measured by the electrode and plots it.  Use this
% script to test your set-up, and also to decide on a
% threshold. Thresholding is a coarse way of picking
% single-cell activity from the recorded signal. In later
% analysis, we'll take a threshold crossing to mean that the
% fiber under study carried an action potential.
%
% v1.0 20140310 Luke Hallum

% Acquisition parameters. The only potentially tricky thing
% here is ID_INPUT.  At the time of writing, we're using the
% C-Media USB2Audio adapter; that means the ID_INPUT is
% likely to be '2'. Seem arcane? In Matlab do this: 
%
%   >> dinfo = audiodevinfo;
%   >> dinfo.input(1) % or 2, or 3...
%
F_SAMP_HZ = 44.1e3; % sampling frequency in Hertz
N_BITS = 16;        % resolution of each sample
ID_INPUT = 1;       % the ID of the input audio device
PERIOD_ACQ_S = 3;   % period in seconds of the acquisition

% First create an 'audiorecorder' object for later use in
% recording. Note that that object is converted to a column
% vector of doubles using function getaudiodata().
r = audiorecorder(F_SAMP_HZ, N_BITS, 1, ID_INPUT);
record(r,PERIOD_ACQ_S); pause(PERIOD_ACQ_S) % here, pause while recording, then return prompt...
sig = getaudiodata(r, 'double');
sig=sig-mean(sig);
figure; plot([0:(length(sig)-1)]/F_SAMP_HZ,sig); axis square
xlabel('Time (s)')
ylabel('Extracellular voltage (normalized)')
set(gca,'tickdir','out','xtick',0:ceil(PERIOD_ACQ_S))

