function [files_in,files_out,opt] = niak_brick_network_stack(files_in, files_out, opt)
% Create network, mean and std stack 4D maps from individual functional maps
%
% SYNTAX:
% [FILE_IN,FILE_OUT,OPT] = NIAK_BRICK_NETWORK_STACK(FILE_IN,FILE_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   DATA.<SUBJECT>
%       (string) Containing the individual map (e.g. rmap_part,stability_maps, etc)
%       NB: assumes there is only 1 .nii.gz or mnc.gz map per individual.
%
%   MASK
%       (3D volume) a binary mask of the voxels that will be included in the
%       time*space array.
%
%   MODEL
%       (strings, default 'gb_niak_omitted') a .csv files coding for the
%       pheno data. Is expected to have a header and a first column
%       specifying the case IDs/names corresponding to the data in
%       FILES_IN.DATA
%
% FILES_OUT
%   (string, default 'network_stack.mat') absolute path to the output .mat
%   file containing the subject by voxel by network stack array.
%
% OPT
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   NETWORK
%       (int array, default all networks) A list of networks number in
%       individual maps
%
%   REGRESS_CONF
%       (Cell of string, Default {}) A list of variables name to be regressed out.
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT (structure) with the following fields:
%
%   STACK
%       (double array) SxVxN array where S is the number of subjects, V is
%       the number of voxels and N the number of networks (if N=1, Matlab
%       displays the array as 2 dimensional, i.e. the last dimension gets
%       squeezed)
%
%   PROVENANCE
%       (structure) with the following fields:
%
%       SUBJECTS
%           (cell array) Sx2 cell array containing the names/IDs of
%           subjects in the same order as they are supplied in
%           FILES_IN.DATA and FILES_OUT.STACK. The first column contains
%           the names as they are suppiled in FILES_IN.DATA whereas the
%           second column contains the (optional) names that are taken from
%           the model file in FILES_IN.MODEL
%
%       MODEL
%           (structure, optional) Only available if OPT.FLAG_CONF is set
%           to true and a correct model was supplied. Contains the
%           following fields:
%
%           MATRIX
%               (double array, optional) Contains the model matrix that was
%               used to perform the confound regression.
%
%           CONFOUNDS
%               (cell array, optional) Contains the names of the covariates
%               in the model that are regressed from the input data
%
%       VOLUME
%           (structure) with the following fields:
%
%           NETWORK
%               (double array) Contains the network ID or IDs in the same
%               order that they appear in FILES_OUT.STACK
%
%           SCALE
%               (double) The scale of the network solution of the input
%               data (i.e. how many networks were available in the input
%               data).
%
%           MASK
%               (boolean array) The binary brain mask that can be used to
%               map the vectorized data in FILES_OUT.STACK back into volume
%               space.
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.


%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NETWORK_STACK(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_network_stack'' for more info.')
end

% FILES_IN
files_in = psom_struct_defaults(files_in,...
           { 'data' , 'mask' , 'model'           },...
           { NaN    , NaN    , 'gb_niak_omitted' });

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

% Options
if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'network' , 'regress_conf' , 'flag_verbose' , 'flag_test' },...
      { ''           , []        , {}             , true           , false       });

% Check the output specification
if isempty(files_out) && ~strcmp(files_out, 'gb_niak_omitted')
    if isempty(opt.folder_out)
        error('Neither FILES_OUT nor OPT.FOLDER_OUT are specified. Won''t generate any outputs');
    else
        files_out = [niak_full_path(opt.folder_out) 'network_stack.mat'];
    end
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

opt.flag_conf = ~isempty(opt.regress_conf);

%% Prepare the confounds
list_data = fieldnames(files_in.data);
if ~strcmp(files_in.model, 'gb_niak_omitted')

    % Load the model
    [conf_model, list_subject , cat_names] = niak_read_csv(files_in.model);

    % Check that all confounds can be found in the model
    mask_sanity = ~ismember(opt.regress_conf,cat_names);
    if any(mask_sanity)
        opt.regress_conf(mask_sanity);
        error('Some confounds (listed above) could not be found in the model')
    end

    % Find the confounds in the variable of the model
    mask_conf = ismember(cat_names,opt.regress_conf);
    conf_model = conf_model(:,mask_conf);

    % Remove subjects with NaN
    mask_nan = max(isnan(conf_model),[],2);
    if any(mask_nan)
        list_subject(mask_nan)
        warning(sprintf('I had to remove %i subjects (listed above) who had missing values in their confounds.',sum(mask_nan)));
    end
    conf_model = conf_model(~mask_nan,:);
    list_subject = list_subject(~mask_nan,:);

    % Remove subjects with no imaging data
    mask_data = ismember(list_subject,list_data);
    if any(~mask_data)
        list_subject(~mask_data)
        warning(sprintf('I had to remove %i subjects (listed above) who had missing imaging data.',sum(~mask_data)));
    end
    conf_model = conf_model(mask_data,:);
    list_subject = list_subject(mask_data,:);
else
    list_subject = fieldnames(files_in.data);
end

% Check the first subject file and see how many networks we have
n_input = length(list_subject);
[~, vol] = niak_read_vol(files_in.data.(list_subject{1}));
scale = size(vol, 4);
% If no scale has been supplied, use all networks
if isempty(opt.network)
    opt.network = 1:scale;
% Make sure all networks are there
elseif max(opt.network) > scale
    error(['You requested networks up to #%d to be investigated '...
           'but the specified input only has %d networks'], max(opt.network), scale);
end

%% Brick starts here
% Read the mask
[~, mask] = niak_read_vol(files_in.mask);
% Turn the mask into a boolean array
mask = logical(mask);
% Get the number of non-zero voxels in the mask
n_vox = sum(mask(:));
% Get the number of scales
n_scales = length(opt.network);

% Pre-allocate the output matrix. If we have more than one network, we'll
% repmat it
stack = zeros(n_input, n_vox, n_scales);

% Iterate over the input files
for in_id = 1:n_input
    % Get the name for the input field we need
    in_name = list_subject{in_id};
    % Load the corresponding path
    read_file = files_in.data.(in_name);
    if opt.flag_verbose
        fprintf('Reading %s now ...\n', read_file);
    end
    [~, vol] = niak_read_vol(read_file);

    % Loop through the networks and mask the thing
    for net_id = 1:length(opt.network)
        % Get the correct network number
        net = opt.network(net_id);
        % Mask the volume
        masked_vol = niak_vol2tseries(vol(:, :, :, net), mask);
        % Save the masked array into the stack variablne
        stack(in_id, :, net_id) = masked_vol;
    end
end

%% Regress confounds
if ~strcmp(files_in.model, 'gb_niak_omitted')&&opt.flag_conf

    % Set up the model structure for the regression
    opt_mod = struct;
    opt_mod.flag_residuals = true;
    m = struct;
    m.x = [ones(length(list_subject),1) conf_model];

    % Loop through the networks again for the regression
    for net_id = 1:length(opt.network)
        % Get the correct network
        m.y = stack(:, :, net_id);
        [res] = niak_glm(m, opt_mod);
        % Store the residuals in the confound stack
        stack(:, :, net_id) = res.e;
    end
end

% Build the provenance data
provenance = struct;
% Get the subjects
provenance.subjects = cell(n_input, 2);
% First column are the input field names
provenance.subjects(:, 1) = list_subject;
% Second column is so far undefined

% Add the model information
if ~strcmp(files_in.model, 'gb_niak_omitted')
    provenance.model = struct;
    provenance.model.matrix = m.x;
    provenance.model.confounds = opt.regress_conf;
end

% Add the volume information
provenance.volume.network = opt.network;
% Store the scale of the prior networks
provenance.volume.scale = scale;
% Save the brain mask to map the data back into volume space
provenance.volume.mask = mask;
% Region mask is missing so far

% Save the stack matrix
save(files_out, 'stack', 'provenance');
