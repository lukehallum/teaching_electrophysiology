function [resp, sigs] = NS2RoachRespVersusFreq(freq_test_HZ, num_repeats, threshold_VNORM)

% Acquisition parameters, etc. Also, create an audiorecorder
% object. Confused?  See comments in the accompanying 'test
% acquisition' script.
F_SAMP_HZ = 44.1e3;
N_BITS = 16;
ID_INPUT = 1;
r = audiorecorder(F_SAMP_HZ, N_BITS, 1, ID_INPUT);

% Make stimuli. Specifically, we'll make N different stimuli, where N is the
% number of frequencies contained in the argument 'freq_test_HZ'. Each trial is
% 3 sec duration: the first 1 sec is "baseline", ie., there's no stimulus; the
% next 2 sec involves the applied stimulus (within a Hann window).
PERIOD_TRIAL_S = 3;
T_S = transpose(linspace(0,PERIOD_TRIAL_S,1+PERIOD_TRIAL_S*F_SAMP_HZ));
WIN = [zeros(sum(T_S < 1),1); hann(sum(T_S >= 1))]; 
%WIN = [zeros(sum(T_S < 1),1); ones(sum(T_S >= 1),1)]; 
ID_OUTPUT = 3;
y = cell(length(freq_test_HZ),1);
y_ = cell(length(freq_test_HZ),1);
carrier = sin(2*pi*4000*T_S);
for iistim = 1:length(freq_test_HZ)
  %y{iistim} = WIN .* ((0.5 + 0.5*cos(2*pi*freq_test_HZ(iistim)*T_S)) .* carrier);
  y{iistim} = WIN .* cos(2*pi*freq_test_HZ(iistim)*T_S);
  y_{iistim} = audioplayer(y{iistim},F_SAMP_HZ,N_BITS,ID_OUTPUT);
end
% Baseline...
y{length(freq_test_HZ)+1} = 0*(WIN .* cos(2*pi*freq_test_HZ(iistim)*T_S));
y_{length(freq_test_HZ)+1} = audioplayer(y{length(freq_test_HZ)+1},F_SAMP_HZ,N_BITS,ID_OUTPUT);
freq_test_HZ = [freq_test_HZ 1.1*max(freq_test_HZ)];

% Main loop is here. First, determine the pseudorandomized
% sequence of trials.
seq_trials__ = repmat([1:length(freq_test_HZ)],[num_repeats 1]);
seq_trials_ = seq_trials__(:);
seq_trials = seq_trials_(randperm(length(seq_trials_)));
num_trials = length(seq_trials);
% Along the way, we'll update 2 figures. The first plots
% response against frequency. The second plots spike
% rasters.
resp = nan(num_trials,3);
sigs = cell(num_trials,1);
handle_rasters = figure;
RES_SP = ceil(sqrt(length(freq_test_HZ)));
subplot(RES_SP,RES_SP,1)
handle_rvf = figure; hold on
for iitrial = 1:num_trials

  id_stim = seq_trials(iitrial);
  this_y_ = y_{id_stim};
%Playback...
%id_stim = resp(iitrial,1);

  play(this_y_)
  record(r,PERIOD_TRIAL_S); pause(PERIOD_TRIAL_S)
  this_sig = getaudiodata(r, 'double');
  this_sig=this_sig-mean(this_sig);
  sigs{iitrial,1} = this_sig;
%Playback...
%this_sig = sigs{iitrial,1};

% Get snippets from 'this_sig'. Specifically, get snippets
% from first 1s of trial ("baseline"), the snippets from
% next 2s of trial ("stimulus").
  this_sig_ = this_sig > threshold_VNORM;
  if (sign(threshold_VNORM) == -1), this_sig_ = this_sig < threshold_VNORM; end
  this_sig__ = max(0,[0; diff(this_sig_)]);
% Recall the first 1 sec of the trial is "baseline" and the next 2 sec involve
% stimulation.  The actual sample count comprising 'this_sig' will vary a
% little from trial to trial. To simplify, let's not worry about that too much,
% assuming that the samples that we do have are evenly spaced from 0 to
% PERIOD_TRIAL_S.
  ix = (1:length(this_sig)) / length(this_sig);
  ix_spike = find(this_sig__ == 1);
  resp_baseline_IPS = sum(this_sig__(ix < 1/3));
  resp_IPS = sum(this_sig__(ix >= 1/3)) / 2;
  resp(iitrial,:) = [id_stim resp_baseline_IPS resp_IPS];

  figure(handle_rvf);
JITTER = 0.1*min(freq_test_HZ);
  plot(freq_test_HZ(id_stim)+JITTER*(rand-0.5),resp_baseline_IPS,'sr')
  plot(freq_test_HZ(id_stim)+JITTER*(rand-0.5),resp_IPS,'sk'); axis square; drawnow
  set(gca,'xscale','log','tickdir','out')
  xlabel('Stimulus frequency (Hz)')
  ylabel('Response (impulses per sec)')
 
  drawnow 

  num_trial_of_type = sum(double(seq_trials(1:iitrial) == id_stim));
  figure(handle_rasters);
  subplot(RES_SP,RES_SP,id_stim); hold on
  plot((ix_spike-1)/F_SAMP_HZ,repmat(num_trial_of_type,[1 length(ix_spike)]),'+k'); axis square; drawnow
  axis([0 PERIOD_TRIAL_S 0 1.2*num_repeats])
  xlabel('Time (s)')
  ylabel('Trial number')
  set(gca,'tickdir','out','xtick',0:ceil(PERIOD_TRIAL_S),'ytick',1:5:num_repeats)

end

return; % end of function
