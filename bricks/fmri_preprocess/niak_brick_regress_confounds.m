function [files_in,files_out,opt]=niak_brick_regress_confounds(files_in,files_out,opt)
% Regress confounds from fMRI time series
%
% SYNTAX :
% NIAK_BRICK_REGRESS_CONFOUNDS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% FILES_IN
%   (structure) with the following fields:
%
%   FMRI
%      (string) the fmri time-series
%
%   CONFOUNDS
%      (string) the name of a file with (compressed) tab-separated values.
%      Each column corresponds to a "confound" effect.
%      see template/niak_confounds.json for a list of expected confounds.
%
% FILES_OUT
%      (string, default FOLDER_OUT/<base FMRI>_cor.<ext FMRI>) the name
%      of a 3D+t file. Same as FMRI with the confounds regressed out.
%
% OPT
%
%   FOLDER_OUT
%      (string, default folder of FMRI) the folder where the default outputs
%      are generated.
%
%   FLAG_SLOW
%      (boolean, default true) turn on/off the correction of slow time drifts
%
%   FLAG_HIGH
%      (boolean, default false) turn on/off the correction of high frequencies
%
%   FLAG_GSC
%      (boolean, default false) turn on/off global signal correction
%
%   FLAG_MOTION_PARAMS
%      (boolean, default true) turn on/off the removal of the 6 motion
%      parameters + the square of 6 motion parameters.
%
%   FLAG_WM
%      (boolean, default true) turn on/off the removal of the average
%      white matter signal.
%
%   FLAG_VENT
%      (boolean, default true) turn on/off the removal of the average
%      signal in the lateral ventricles.
%
%   FLAG_COMPCOR
%      (boolean, default false) turn on/off COMPCOR
%
%   FLAG_SCRUBBING
%      (boolean, default true) turn on/off the "scrubbing" of volumes with
%      excessive motion.
%
%   PCT_VAR_EXPLAINED
%      (boolean, default 0.95) the % of variance explained by the selected
%      PCA components when reducing the dimensionality of motion parameters.
%
%   FLAG_PCA_MOTION
%      (boolean, default true) turn on/off the PCA reduction of motion
%      parameters.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% See template/niak_confounds.json in the niak folder for a list of
%   admissible confound labels.
%
% The estimator of the global average using PCA is described in the
% following publication:
%
%   F. Carbonell, P. Bellec, A. Shmuel. Validation of a superposition model
%   of global and system-specific resting state activity reveals anti-correlated
%   networks. Brain Connectivity 2011 1(6): 496-510. doi:10.1089/brain.2011.0065
%
% For an overview of the regression steps as well as the "scrubbing" of
% volumes with excessive motion, see:
%
%   J. D. Power, K. A. Barnes, Abraham Z. Snyder, B. L. Schlaggar, S. E. Petersen
%   Spurious but systematic correlations in functional connectivity MRI networks
%   arise from subject motion
%   NeuroImage Volume 59, Issue 3, 1 February 2012, Pages 21422154
%
%   Note that the scrubbing is based solely on the FD index, and that DVARS is not
%   derived. The paper of Power et al. included both indices.
%
% For a description of the COMPCOR method:
%
%   Behzadi, Y., Restom, K., Liau, J., Liu, T. T., Aug. 2007. A component based
%   noise correction method (CompCor) for BOLD and perfusion based fMRI.
%   NeuroImage 37 (1), 90-101. http://dx.doi.org/10.1016/j.neuroimage.2007.04.042
%
%   This other paper describes more accurately the COMPCOR implemented in NIAK:
%   Chai, X. J., Castan, A. N. N., Ongr, D., Whitfield-Gabrieli, S., Jan. 2012.
%   Anticorrelations in resting state networks without global signal regression.
%   NeuroImage 59 (2), 1420-1428. http://dx.doi.org/10.1016/j.neuroimage.2011.08.048

% Note that a maximum number of (# degrees of freedom)/2 are removed through compcor.
%
% Copyright (c) Christian L. Dansereau, Felix Carbonell, Pierre Bellec
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pca, glm, confounds, motion parameters

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% FILES_IN
list_fields    = { 'fmri' , 'confounds' };
list_defaults  = { NaN    , NaN         };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% FILES_OUT
list_fields    = { 'filtered_data'   , 'scrubbing'       };
list_defaults  = { 'gb_niak_omitted' , 'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% OPTIONS
list_fields    = { 'flag_compcor' , 'nb_vol_min' , 'flag_scrubbing' , 'thre_fd' , 'flag_slow' , 'flag_high' ,  'folder_out' , 'flag_verbose', 'flag_motion_params', 'flag_wm', 'flag_vent' , 'flag_gsc' , 'flag_pca_motion', 'flag_test', 'pct_var_explained'};
list_defaults  = { false          , 40           , true             , 0.5       , true        , false       , ''            , true          , true                , true     , true        , false      , true             , false      , 0.95               };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

[path_f,name_f,ext_f] = niak_fileparts(files_in.fmri);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.filtered_data)
    files_out.filtered_data = cat(2,opt.folder_out,filesep,name_f,'_cor',ext_f);
end

if isempty(files_out.scrubbing)
    files_out.scrubbing = cat(2,opt.folder_out,filesep,name_f,'_scrub.mat');
end

if opt.flag_test
    return
end

%% Read the fMRI dataset
if opt.flag_verbose
    fprintf('Reading the fMRI dataset ...\n%s\n',files_in.fmri);
end
[hdr_vol,vol] = niak_read_vol(files_in.fmri); % fMRI dataset
y = reshape(vol,[size(vol,1)*size(vol,2)*size(vol,3) size(vol,4)])'; % organize the fMRI dataset as a time x space array

%% Read the confounds
if opt.flag_verbose
    fprintf('Reading the confounds...\n%s\n',files_in.confounds);
end
tab = niak_read_csv_cell(files_in.confounds);
x = str2double(tab(2:end,:));
all_labels = tab(1,:);

%% Scrubbing
if opt.flag_verbose
    fprintf('Scrubbing frames exhibiting large motion ...\n')
end
mask_scrubbing = x(:,strcmp(all_labels,'scrub'));
fd = x(:,strcmp(all_labels,'FD'));
fd = fd(1:end-1);
hdr_vol.extra.mask_scrubbing = mask_scrubbing;

%% Build model
x2 = [];
labels = {};

%% Slow time drifts
if opt.flag_slow
    if opt.flag_verbose
        fprintf('Adding slow time drifts ...\n')
    end
    mask_slow = strcmp(all_labels,'slow_drift');
    x2 = [x2 x(:,mask_slow)];
    labels = [labels all_labels(mask_slow)];
else
    if opt.flag_verbose
        fprintf('Ignoring slow time drifts...\n')
    end
end

%% High frequencies
if opt.flag_high
    if opt.flag_verbose
        fprintf('Adding high frequency noise...\n')
    end
    mask_high = strcmp(all_labels,'high_freq');
    x2 = [x2 x(:,mask_high)];
    labels = [labels all_labels(mask_high)];
else
    if opt.flag_verbose
        fprintf('Ignoring high frequency noise...\n')
    end
end

%% Motion parameters
rot = niak_normalize_tseries(x(:,ismember(all_labels,{'motion_rx','motion_ry','motion_rz'})));
tsl = niak_normalize_tseries(x(:,ismember(all_labels,{'motion_tx','motion_ty','motion_tz'})));
motion_param = [rot,tsl,rot.^2,tsl.^2];
if opt.flag_pca_motion
    [eig_val,motion_param] = niak_pca(motion_param',opt.pct_var_explained);
end
if opt.flag_motion_params
    if opt.flag_verbose
        fprintf('Adding high frequency noise...\n')
    end
    x2 = [x2 motion_param];
    labels = [labels repmat({'motion'},[1 size(motion_param,2)])];
else
    if opt.flag_verbose
        fprintf('Ignoring motion parameters...\n')
    end
end

%% Add white matter average
if opt.flag_wm
    if opt.flag_verbose
       fprintf('Adding white matter average...\n')
    end
    mask_wm = strcmp(all_labels,'wm_avg');
    x2 = [x2 x(:,mask_wm)];
    labels = [labels all_labels(mask_wm)];
else
    if opt.flag_verbose
        fprintf('Ignoring white matter average...\n')
    end
end

%% Add ventricle average
if opt.flag_vent
    if opt.flag_verbose
       fprintf('Adding ventricular average...\n')
    end
    mask_vent = strcmp(all_labels,'vent_avg');
    x2 = [x2 x(:,mask_vent)];
    labels = [labels all_labels(mask_vent)];
else
    if opt.flag_verbose
        fprintf('Ignoring ventricular average...\n')
    end
end

%% Add Global signal
if opt.flag_gsc
    if opt.flag_verbose
       fprintf('Adding global signal...\n')
    end
    mask_gs = strcmp(all_labels,'global_signal_pca');
    x2 = [x2 x(:,mask_gs)];
    labels = [labels all_labels(mask_gs)];
else
    if opt.flag_verbose
        fprintf('Ignoring global signal...\n')
    end
end

%% Add Compcor
if opt.flag_compcor
    if opt.flag_verbose
       fprintf('Adding COMPCOR...\n')
    end
    mask_compcor = strcmp(all_labels,'compcor');
    x2 = [x2 x(:,mask_compcor)];
    labels = [labels all_labels(mask_compcor)];
else
    if opt.flag_verbose
        fprintf('Ignoring COMPCOR...\n')
    end
end

%% Add custom regressors
mask_manual = strcmp(all_labels,'manual');
if any(mask_manual)
    if opt.flag_verbose
       fprintf('Adding user-specified confounds...\n')
    end
    x2 = [x2 x(:,mask_manual)];
    labels = [labels all_labels(mask_manual)];
end

%% Regress confounds
if ~isempty(x2)
    if opt.flag_verbose
        fprintf('Regressing the confounds...\n    Total number of confounds: %i\n    Total number of time points for regression: %i\n',size(x,2),sum(~mask_scrubbing))
    end

    %% Normalize data
    y_mean = mean(y(~mask_scrubbing,:),1); % Exclude time points with excessive motion to estimate mean/std
    y_std  =  std(y(~mask_scrubbing,:),[],1);
    y = (y-repmat(y_mean,[size(y,1),1]))./repmat(y_std,[size(y,1) 1]);
    x2_mean = mean(x2(~mask_scrubbing,:),1); % Exclude time points with excessive motion to estimate mean/std
    x2_std = std(x2(~mask_scrubbing,:),[],1);
    x2 = (x2-repmat(x2_mean,[size(x2,1),1]))./repmat(x2_std,[size(x2,1) 1]);

    %% Run the regression
    model.y = y(~mask_scrubbing,:);
    model.x = x2(~mask_scrubbing,:);
    opt_glm.flag_beta = true;
    res = niak_glm(model,opt_glm); % Run the regression excluding time points with excessive motion
    y = y - x2*res.beta; % Generate the residuals for all time points combined
    y = y + repmat(y_mean,[size(y,1) 1]); % put the mean back in the time series
    vol_denoised = reshape(y',size(vol));

else

    warning('Found no confounds to regress! Leaving the dataset as is')
    vol_denoised = vol;

end

%% Save the fMRI dataset after regressing out the confounds
if ~strcmp(files_out.filtered_data,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Saving results in %s ...\n',files_out.filtered_data);
    end
    hdr_vol.file_name = files_out.filtered_data;
    if isfield(hdr_vol,'extra')
        % Store the regression covariates in the extra .mat companion that comes with the 3D+t dataset
        hdr_vol.extra.confounds = x2;
        hdr_vol.extra.labels_confounds = labels(:);
    end
    niak_write_vol(hdr_vol,vol_denoised);
end

%% Save the scrubbing parameters
if ~strcmp(files_out.scrubbing,'gb_niak_omitted')
    save(files_out.scrubbing,'mask_scrubbing','fd');
end
