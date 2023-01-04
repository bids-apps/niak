function [pipeline,opt] = niak_pipeline_connectome(files_in,opt)
% Generation of connectome in resting-state fMRI
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_CONNECTOME(FILES_IN,OPT)
%
% ___________________________________________________________________________________
% INPUTS
%
% FILES_IN
%   (structure) with the following fields :
%
%   NETWORK
%      (string) a file name of a mask of brain networks (network I is filled
%      with Is, 0 is for the background). The analysis will be done at the level
%      of these networks.
%
%   FMRI.(SUBJECT).(SESSION).(RUN)
%      (string) a 3D+t fMRI dataset. The fields <SUBJECT>, <SESSION> and <RUN> can be
%      any arbitrary string.
%
%   SEEDS
%      (string, default 'gb_niak_omitted') the name of a .csv file with a list of seeds.
%      If omitted, all seeds are included, and seed I is labeld "seedI".
%
% OPT
%   (structure) with the following fields :
%
%   LABEL_NETWORK
%      (string, default 'rois') the label for the network.
%
%   CONNECTOME
%      (structure) see the OPT argument of NIAK_BRICK_CONNECTOME.
%
%   FOLDER_OUT
%      (string) where to write the results of the pipeline.
%
%   FLAG_P2P
%      (boolean, default true) turn on/off the generation of point-to-point
%      connectivity estimates (a .csv FILES_IN.SEEDS file must be provided)
%
%   FLAG_GLOBAL_PROP
%      (boolean, default true) turn on/off the generation of global network
%      properties.
%
%   FLAG_LOCAL_PROP
%      (boolean, default true) turn on/off the generation of local network
%      properties.
%
%   FLAG_RMAP
%      (boolean, default true) turn on/off the generation of correlation
%      maps.
%
%   REPORT_RMAP
%      (structure, optional) with the following fields:
%      AVG.THRESH (scalar, default [-0.15 0.25]) if empty, does nothing.
%        If a scalar, any value below threshold becomes transparent. If two values,
%        anything between these two values become transparent.
%      AVG.LIMITS (vector 1x2, default [-0.3 0.5]) the limits for the colormap.
%        By defaut it is using [min,max]. If a string is specified, the function
%        will implement an adaptative strategy.
%      IND.THRESH (scalar, default [-0.15 0.35]) if empty, does nothing.
%        If a scalar, any value below threshold becomes transparent. If two values,
%        anything between these two values become transparent.
%      IND.LIMITS (vector 1x2, default [-0.5 0.8]) the limits for the colormap.
%        By defaut it is using [min,max]. If a string is specified, the function
%        will implement an adaptative strategy.
%
%   PSOM
%      (structure, optional) the options of the pipeline manager. See the
%      OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%      Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_SYM
%      (boolean, default true) if true use a symmetric MNI template background,
%      otherwise use an asymmetric one.
%
%   FLAG_RAND
%      (boolean, default false) some of the graph measures (such as the
%      modularity) have some random components, which means that slight
%      variations of the measure will be observed if the measure is repeated
%      multiple times. By default, NIAK will control the seeds of the random
%      number generator to guarantee that the measures are identical if the
%      analysis were replicated. If FLAG_RAND is set to true, then the clock
%      is used to set the random number generator, and two runs of the pipeline
%      can generate different results.
%
%   FLAG_TEST
%      (boolean, default false) If FLAG_TEST is true, the pipeline will
%      just produce a pipeline structure, and will not actually process
%      the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the
%      data.
%
%   FLAG_VERBOSE
%      (boolean, default true) Print some advancement infos.
%
% _________________________________________________________________________
% OUTPUTS :
%
% PIPELINE
%   (structure) describe all jobs that need to be performed in the
%   pipeline. This structure is meant to be use in the function
%   PSOM_RUN_PIPELINE.
%
% OPT
%   (structure) same as input, but updated for default values.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_CONNECTOME, NIAK_BRICK_GRAPH_PROP, NIAK_BRICK_RMAP
%
% _________________________________________________________________________
% COMMENTS:
%
%  The measure 'Dcentrality' is described in the following paper:
%   Buckner et al. Cortical Hubs Revealed by Intrinsic Functional Connectivity:
%   Mapping, Assessment of Stability, and Relation to
%   Alzheimers Disease. The Journal of Neuroscience, February 11, 2009.
%
% Some of the measures employed here depend on function from the "brain connectivity toolbox"
%   https://sites.google.com/site/bctnet/Home/functions
% This software has to be installed to generate the networks properties, and is described
% in the following paper:
%   Rubinov, M., Sporns, O., Sep. 2010.
%   Complex network measures of brain connectivity: Uses and interpretations.
%   NeuroImage 52 (3), 1059-1069.
%   URL http://dx.doi.org/10.1016/j.neuroimage.2009.10.003
%
% The .csv FILES_IN.SEEDS can take two forms.
% Example 1, (world) coordinates in stereotaxic space:
%
%         ,   x ,  y ,  z
% NET1    ,  12 ,  7 , 33
% NET2    ,  45 , -3 , 27
%
% With that method, the pipeline will load FILES_IN.NETWORK, extract the number
% of the networks corresponding to the coordinates, and associate them to labels
% NET1 and NET2. WARNING: the labels for the ROI must be acceptable as field names
% for matlab, i.e. no special characters (+ - / * space) and relatively short.
%
% Example 2, string and numeric labels:
%
%        , index
% NET1   , 3010
% NET2   , 3020
%
% In this case, the index refers to the number associated with one network.
% The labels will be attached.
%
% With both methods, the first row does not really matter. It is still important that the row is present,
% and that the intersection of first column and first row is left empty.
%
% If two rows are associated with the same parcel, the pipeline will throw an error. This can
% occur in particular with method 1.
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Griatrie de Montral
%               Dpartement d'informatique et de recherche oprationnelle
%               Universit de Montral, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, fMRI, connectome

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
niak_gb_vars

%% Checking that FILES_IN is in the correct format
list_fields   = { 'network' , 'fmri' , 'seeds'           };
list_defaults = { NaN       , NaN    , 'gb_niak_omitted' };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Options
list_fields   = { 'report_rmap' , 'flag_sym' , 'flag_rand' , 'label_network' , 'flag_p2p' , 'flag_rmap'   , 'flag_global_prop' , 'flag_local_prop' , 'connectome' , 'psom'   , 'folder_out' , 'flag_verbose' , 'flag_test' };
list_defaults = { struct        , true       , false       , 'rois'          , true       , true          , true               , true              , struct()     , struct() , NaN          , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out 'logs' filesep];

%% Background template
if opt.flag_sym
    background.vol  = [GB_NIAK.path_niak filesep 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a.mnc.gz'];
    background.mask = [GB_NIAK.path_niak filesep 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a_mask.mnc.gz'];
else
    background.vol  = [GB_NIAK.path_niak filesep 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_asym_09a.mnc.gz'];
    background.mask = [GB_NIAK.path_niak filesep 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask.mnc.gz'];
end

%% Get the list of seeds and associated labels
if ~strcmp(files_in.seeds,'gb_niak_omitted')
    [seeds,labels_seed,ly] = niak_read_csv(files_in.seeds);
    [hdr,mask] = niak_read_vol(files_in.network);
    if size(seeds,2) == 1
        % Method 1: the user specified the indices of the parcels
        list_seed = seeds;
        mask_ok = ismember(list_seed,unique(mask));
        if any(~mask_ok)
            error('The following seeds are listed in the .csv FILES_IN.SEEDS but do not correspond to any parcels',char(labels_seed(~mask_ok)))
        end
    elseif size(seeds,2) == 3
        % Method 2: world coordinates
        list_seed = zeros(size(seeds,1),1);
        coord_v = niak_coord_world2vox(seeds,hdr.info.mat);
        for num_s = 1:length(list_seed)
            list_seed(num_s) = mask(coord_v(num_s,1),coord_v(num_s,2),coord_v(num_s,3));
        end
    end
    %% Sanity check on the seeds
    for num_s = 1:length(list_seed)
        if opt.flag_verbose
            fprintf('Adding seed %s (parcel number %i)\n',labels_seed{num_s},list_seed(num_s));
        end
    end
    if length(unique(list_seed))~=length(list_seed)
        error('The same parcel was associated with multiple rows in the seeds .csv file')
    end
    if length(unique(labels_seed))~=length(labels_seed)
        error('The same label was associated with multiple rows in the seeds .csv file')
    end
else
    [hdr,mask] = niak_read_vol(files_in.network);
    list_seed = unique(mask(:));
    list_seed = list_seed(list_seed~=0);
    labels_seed = cell(length(list_seed),1);
    for ll = 1:length(list_seed)
        labels_seed{ll} = sprintf('seed%i',list_seed(ll));
    end
end

opt.graph_prop = struct;

%% Add global network properties, if required
if opt.flag_global_prop
    opt.graph_prop.global_efficiency.type  = 'global_efficiency';
    opt.graph_prop.avg_clustering.type = 'avg_clustering';
    opt.graph_prop.modularity.type = 'modularity';
end

%% Add local network properties, if required
if opt.flag_local_prop

    %% Add measures of degree centrality
    for x = 1:length(list_seed)
        opt.graph_prop.(['Dcentrality_' labels_seed{x}]).param = list_seed(x);
        opt.graph_prop.(['Dcentrality_' labels_seed{x}]).type = 'Dcentrality';
    end

    %% Add measures of local clustering
    for x = 1:length(list_seed)
        opt.graph_prop.(['clustering_' labels_seed{x}]).param = list_seed(x);
        opt.graph_prop.(['clustering_' labels_seed{x}]).type = 'clustering';
    end

    %% Add measures of local efficiency
    for x = 1:length(list_seed)
        opt.graph_prop.(['local_eff_' labels_seed{x}]).param = list_seed(x);
        opt.graph_prop.(['local_eff_' labels_seed{x}]).type = 'local_efficiency';
    end
end

%% Add point-to-point connectivity, if required
if opt.flag_p2p
    for x = 1:length(list_seed)
        for y = x:length(list_seed)
            opt.graph_prop.(['p2p_' labels_seed{x} '_X_' labels_seed{y}]).param(1) = list_seed(x);
            opt.graph_prop.(['p2p_' labels_seed{x} '_X_' labels_seed{y}]).param(2) = list_seed(y);
            opt.graph_prop.(['p2p_' labels_seed{x} '_X_' labels_seed{y}]).type = 'p2p';
        end
    end
end

%% Add correlation maps, if required
if opt.flag_rmap
    for x = 1:length(list_seed)
        opt.rmap.ind_seeds.(labels_seed{x}) = list_seed(x);
    end
end

%% Loop over networks
pipeline = struct();
network = opt.label_network;

% Re-organize inputs
[files_tseries,list_subject] = sub_input(files_in);

%% Copy the networks
[~,~,ext_f] = niak_fileparts(files_tseries.(list_subject{1}){1});
pipeline = struct();
clear job_in job_out job_opt
job_in.source      = files_in.network;
job_in.target      = files_tseries.(list_subject{1}){1};
job_out            = [folder_out 'network_' network ext_f];
job_opt.interpolation    = 'nearest_neighbour';
pipeline = psom_add_job(pipeline,['mask_' network],'niak_brick_resample_vol',job_in,job_out,job_opt);

%% Select the networks
clear job_in job_out job_opt
pipeline.(['select_' network]).files_in = pipeline.(['mask_' network]).files_out;
pipeline.(['select_' network]).files_out = [folder_out 'select_' network ext_f];
pipeline.(['select_' network]).opt.list_seed = list_seed;
pipeline.(['select_' network]).command = ['[hdr,vol] = niak_read_vol(files_in); ' ...
           'vol2 = zeros(size(vol)); ' ...
           'for ss = 1:length(opt.list_seed); ' ...
           '    vol2(vol==opt.list_seed(ss)) = ss; ' ...
           'end; ' ...
           'hdr.file_name = files_out; ' ...
           'niak_write_vol(hdr,vol2);'];

%% Mask the background
clear job_in job_out job_opt
pipeline.mask_background.files_in = background;
pipeline.mask_background.files_out = [folder_out 'template' ext_f];
pipeline.mask_background.command = ['[hdr,vol] = niak_read_vol(files_in.vol);' ...
                                    '[hdr,mask] = niak_read_vol(files_in.mask);' ...
                                    'vol(~mask) = max(vol(:));' ...
                                    'hdr.file_name = files_out;' ...
                                    'niak_write_vol(hdr,vol);'];

%% Save the pipeline parameters
pipeline.pipe_params.command = 'save(files_out,''-struct'',''opt'')';
pipeline.pipe_params.files_out = [opt.folder_out 'pipe_parameters.mat'];
pipeline.pipe_params.opt.opt = opt;
pipeline.pipe_params.opt.files_in = files_in;

%% Run the estimation of connectomes
for num_s = 1:length(list_subject)
    clear in out jopt
    subject = list_subject{num_s};
    name_job = sprintf('connectome_%s',subject);
    in.fmri = files_tseries.(subject);
    in.mask = pipeline.(['mask_' network]).files_out;
    out = [folder_out 'connectomes' filesep 'connectome_' network '_' subject '.mat'];
    jopt = opt.connectome;
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_connectome',in,out,jopt);
end

%% Generate graph properties
list_mes = fieldnames(opt.graph_prop);
list_mes = list_mes(~ismember(list_mes,{'flag_verbose','flag_test'}));
if ~isempty(list_mes)
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        name_job_in = sprintf('connectome_%s',subject);
        clear in out jopt
        name_job = sprintf('graph_prop_%s_%s',network,subject);
        in = pipeline.(name_job_in).files_out{1};
        out = [folder_out 'graph_prop' filesep name_job '.mat'];
        jopt = opt.graph_prop;
        if opt.flag_rand
            jopt.rand_seed = [];
        else
            jopt.rand_seed = double(niak_datahash(subject));
            jopt.rand_seed = jopt.rand_seed(1:min(length(jopt.rand_seed),625));
        end
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_graph_prop',in,out,jopt);
    end

    clear in out jopt
    name_job = ['summary_graph_prop_' network];
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        in.(subject) = pipeline.(['graph_prop_' network '_' subject]).files_out;
    end
    out = [folder_out name_job '.csv'];
    jopt.flag_verbose = true;
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_graph_summary',in,out,jopt);
end

%% Generate functional connectivity maps
if opt.flag_rmap

    list_maps = cell(length(list_subject),length(labels_seed));
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        clear in out jopt
        in.fmri = psom_files2cell(files_in.fmri.(subject));
        if num_s == 1
            [path_f,name_f,ext_f] = niak_fileparts(in.fmri{1});
        end
        for num_seed = 1:length(labels_seed)
            seed = labels_seed{num_seed};
            in.seeds.(seed) = pipeline.(['mask_' network]).files_out;
            if num_s == 1
                out.seeds.(seed) = [folder_out 'rmap_seeds' filesep 'mask_' seed ext_f];
            else
                out.seeds = 'gb_niak_omitted';
            end
            out.maps.(seed)  = [folder_out 'rmap_seeds' filesep 'rmap_' subject '_' seed ext_f];
            list_maps{num_s,num_seed} = out.maps.(seed);
        end
        name_job = ['rmap_seeds_' subject];
        jopt = opt.rmap;
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_rmap',in,out,jopt);
    end

    %% Compute the average map for each seed
    for num_seed = 1:length(labels_seed)
        seed = labels_seed{num_seed};
        clear in out jopt
        in = list_maps(:,num_seed);
        out = [folder_out 'rmap_seeds' filesep 'average_rmap_' seed ext_f];
        jopt.operation = 'vol = zeros(size(vol_in{1})); for num_m = 1:length(vol_in), vol = vol + vol_in{num_m}; end, vol = vol / length(vol_in);';
        pipeline = psom_add_job(pipeline,['average_rmap_' seed],'niak_brick_math_vol',in,out,jopt);
    end
end

%% Generate report
clear in jopt
in.background = pipeline.mask_background.files_out;
in.network = pipeline.(['select_' network]).files_out;
in.params = pipeline.pipe_params.files_out;
if opt.flag_rmap
    for num_seed = 1:length(labels_seed)
        in.average.(seed) = pipeline.(['average_rmap_' seed]).files_out;
        for num_s = 1:length(list_subject)
            seed = labels_seed{num_seed};
            subject = list_subject{num_s};
            in.individual.(seed).(subject) = pipeline.(['rmap_seeds_' subject]).files_out.maps.(seed);
        end
    end
end
jopt = opt.report_rmap;
jopt.folder_out = [opt.folder_out filesep 'report'];
jopt.flag_test = true;
pipeline = psom_merge_pipeline(pipeline,niak_report_connectome(in,jopt));

%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%
function [files_tseries,list_subject] = sub_input(files_in);
files_tseries = files_in.fmri;
list_subject = fieldnames(files_tseries);
for num_s = 1:length(list_subject)
    subject  = list_subject{num_s};
    files_subject = files_tseries.(subject);
    list_session = fieldnames(files_subject);
    nb_data = 1;
    for num_sess = 1:length(list_session)
        list_run = fieldnames(files_subject.(list_session{num_sess}));
        for num_r = 1:length(list_run)
             files_tmp{nb_data} = files_subject.(list_session{num_sess}).(list_run{num_r});
             nb_data = nb_data + 1;
        end
    end
    files_tseries.(subject) = files_tmp;
end
