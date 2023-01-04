function [pipe,opt] = niak_pipeline_stability_surf(in,opt)
% Estimation of surface space cluster stability
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_STABILITY_SURF(IN,OPT)
% ______________________________________________________________________________
%
% INPUTS:
%
% IN.DATA
%   (string) full path to the structure containing the case by vertex value
%   matrix of surface measures (i.e. cortical thickness). The values must be
%   kept in a field with the name OPT.NAME_DATA
%
% IN.PART
%   (string, optional, default 'gb_niak_omitted') path to .mat file that
%   contains a matrix of VxK where V is the number of vertices on the
%   surface and K is the number of scales to be computed.
%
% IN.NEIGH
%   (string, optional, default 'gb_niak_omitted') path to .mat file, with a
%   variable called OPT.NAME_NEIGH. This is a VxW matrix, where each the
%   v-th row is the list of neighbours of vertex v (potentially paded with
%   zeros). If unspecified, the neighbourhood matrix is generated for the
%   standard MNI surface with ~80k vertices.
%
% OPT
%   (structure, optional) with the following fields:
%
%   NAME_DATA
%       (string, default 'data') the name of the fieldname in IN.DATA that
%       contains the data.
%
%   NAME_PART
%       (string, default 'part') the name of the fieldname in IN.PART that
%       contains the partition if one is provided.
%
%   NAME_NEIGH
%       (string, default 'neigh') if IN.NEIGH is specified, the name
%       of the variable coding for the neighbour matrix.
%
%   SCALE_GRID
%       (vector, optional) The range of scales for which stability will be
%       estimated on the atom level. This only has to be set if atom-level
%       stability estimation is to be performed - for example if stable
%       cores are to be generated or if a consensus partition should be
%       generated by the pipeline. If IN.PART is set to an external
%       partition and OPT.FLAG_CORES is set, then this will default to the
%       scale in IN.PART (NOT IMPLEMENTED YET).
%
%   SCALE_TAR
%       (vector, optional) if consensus clustering is chosen and
%       OPT.SCALE_TAR is not empty, then the replication scales will be
%       selected based on the scales in OPT.SCALE_TAR such that a
%       silhouette criterion is maximized.
%
%   SCALE_REP
%       (vector, optional)
%
%   FOLDER_OUT
%       (string, must be set) where to write the default outputs.
%
%   SAMPLING
%       (structure, optional)
%
%       TYPE
%           (string, default 'bootstrap') how to resample the time series.
%           Available options : 'bootstrap' , 'jacknife'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE :
%               bootstrap : None.
%               jacknife  : OPT.PERC is the percentage of observations
%                           retained in each sample (default 60%)
%
%   REGION_GROWING
%       (structure, optional) the options of NIAK_REGION_GROWING. The most
%       useful parameter is:
%
%       THRE_SIZE
%           (integer,default 80) threshold on the maximum region size
%           before merging (measured in number of vertices).
%
%   STABILITY_ATOM
%       (structure, optional) the options for niak_pipeline_stability_estimate
%
%       NB_SAMPS
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability matrices.
%
%       NB_BATCH
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability matrices.
%
%       SAMPLING
%           (structure, default OPT.SAMPLING)
%
%           TYPE
%               (string, default 'bootstrap') how to resample the time series.
%               Available options : 'bootstrap' , 'jacknife'
%
%           OPT
%               (structure, optional) the options of the sampling. Depends
%               on OPT.SAMPLING.TYPE:
%                   bootstrap : None.
%                   jacknife  : OPT.PERC is the percentage of observations
%                               retained in each sample (default 60%)
%
%   CONSENSUS
%       (structure, optional) with the following fields
%
%       RAND_SEED
%           (scalar, default 2) The specified value is used to seed the random
%           number generator with PSOM_SET_RAND_SEED. If left empty, no action
%           is taken.
%
%   MSTEPS
%       (structure, optional) with the following fields
%
%       PARAM
%           (scalar, default 0.05) if PARAM is comprised between 0 and 1, it is
%           the percentage of residual squares unexplained by the model.
%           If PARAM is larger than 1, it is assumed to be an integer, which is
%           used directly to set the number of components of the model.
%
%       NEIGH
%           (vector, default [0.7 1.3]) defines the local neighbourhood of
%           a number of clusters. If NEIGH has more than two elements, the
%           first and last element will be used to define the neighbourhood.
%
%   CORES
%       (structure, optional) with the following fields
%
%       TYPE
%           (string, default 'kmeans') defines the method used to generate
%           stable clusters.
%           Avalable options: 'highpass', 'kmeans'
%
%       OPT
%           (structure, optional) the options of the stable cluster method.
%           Depends on OPT.CORES.TYPE.
%
%           highpass : THRE (scalar, default 0.5) THRE constitutes the
%                           high-pass percentage cutoff for stability
%                           values (range 0 - 1)
%                      CONF (scalar, default 0.05) defines the confidence
%                           interval with respect to the stability
%                           threshold in percent (range 0 - 1)
%
%           kmeans   : None
%
%   STABILITY_VERTEX
%       (structure, optional) the options for the stability replication
%       using niak_brick_stability_surf.
%
%       NB_SAMPS
%           (integer, default 10) the number of replications per batch. The
%           final effective number of bootstrap samples is NB_SAMPS x NB_BATCH
%           (see below).
%
%       NB_BATCH
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability maps.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   TARGET_TYPE
%       (string, default 'cons') specifies the type of the target
%       clustering. Possible values are:
%
%           'cons'   : Consensus clustering based on the estimated stability
%                      of the data in IN.DATA. The scale space for the consensus
%                      clusters will be taken from OPT.SCALE
%           'plugin' : Plugin clustering based on a single pass of
%                      hierarchical clustering on the data in IN.DATA. The
%                      scale space for the plugin clustering will be taken
%                      from OPT.SCALE
%           'manual' : The target cluster will be supplied by the user. If
%                      this option is selected by the user, an appropriate
%                      target partition must be supplied in IN.PART.
%                      Alternatively, if IN.PART contains a file path,
%                      OPT.TARGET_TYPE will automatically be set to MANUAL.
%
%   FLAG_CORES
%       (boolean, default true) If this is set, we use the stable clusters
%       of the consensus partition.
%
%   FLAG_RAND
%       (boolean, default false) if the flag is true, the random number
%       generator is initialized based on the clock. Otherwise, the seeds of
%       the random number generator are set to fix values, and the pipeline is
%       fully reproducible.
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of IN, OUT and OPT.
% ______________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
%
% See licensing information in the code.
% Keywords : clustering, surface analysis, cortical thickness, stability
%            analysis, bootstrap, jacknife.

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
% ______________________________________________________________________________

%% Seting up default arguments
if ~exist('in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: [IN,OPT] = NIAK_PIPELINE_STABILITY_SURF(IN,OPT).\n Type ''help niak_pipeline_stability_surf'' for more info.')
end

% IN
list_fields   = { 'data' , 'part'            , 'neigh'           };
list_defaults = { NaN    , 'gb_niak_omitted' , 'gb_niak_omitted' };
in = psom_struct_defaults(in,list_fields,list_defaults);

% OPT
list_fields     = { 'name_data' , 'name_part' , 'name_neigh' , 'scale_grid' , 'scale_tar' , 'scale_rep' , 'folder_out' , 'sampling' , 'region_growing' , 'stability_atom' , 'consensus' , 'msteps' , 'cores'  , 'stability_vertex' , 'psom'   , 'target_type' , 'flag_cores' , 'flag_rand' , 'flag_verbose' , 'flag_test' };
list_defaults   = { 'data'      , 'part'      , 'neigh'      , []           , []          , []          , NaN          , struct()   , struct()         , struct()         , struct()    , struct() , struct() , struct()           , struct() , 'cons'        , false        , false       , true           , false       };
opt = psom_struct_defaults(opt, list_fields, list_defaults);
opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs'];

% Setup Region Growing Thresholds
opt.region_growing.region_growing = psom_struct_defaults(opt.region_growing,...
                                    { 'thre_size' },...
                                    { 80          });
opt.region_growing.name_data = opt.name_data;
opt.region_growing.name_neigh = opt.name_neigh;

% Setup Sampling Defaults
opt.sampling = psom_struct_defaults(opt.sampling,...
               { 'type'     , 'opt'    },...
               { 'jacknife' , struct() });

% Setup Stability Atom Defaults
opt.stability_atom = psom_struct_defaults(opt.stability_atom,...
                     { 'nb_samps' , 'nb_batch' , 'sampling'   , 'clustering' },...
                     { 100        , 100        , opt.sampling , struct()     });
opt.stability_atom.estimation = rmfield(opt.stability_atom, 'sampling');
opt.stability_atom = rmfield(opt.stability_atom, {'nb_samps' , 'nb_batch'});
opt.stability_atom.folder_out = opt.folder_out;
opt.stability_atom.flag_test = true;
opt.stability_atom.estimation.scale_grid = opt.scale_grid;
opt.stability_atom.estimation.name_data = 'data_roi';
opt.stability_atom.average.name_job = 'average_atom';
opt.stability_atom.sampling = opt.sampling;

% Setup Consensus Clustering Defaults (XX WIP XX)
opt.consensus = psom_struct_defaults(opt.consensus,...
                { 'rand_seed' },...
                { 2           });
opt.consensus.scale_tar = opt.scale_tar;
opt.consensus.name_roi = 'part_roi';
opt.consensus.scale_grid = opt.scale_grid;

% Setup Mstep Defaults
opt.msteps = psom_struct_defaults(opt.msteps,...
             { 'param' , 'neigh'   },...
             { 0.05    , [0.7 1.3] });
opt.msteps.name_nb_classes = 'scale_grid';

% Setup Cores Defaults - put them in stacked hierarchy because this is what
% niak_brick_stability_surf_cores expects
opt.cores.cores = psom_struct_defaults(opt.cores,...
                  { 'type'   , 'opt'    },...
                  { 'kmeans' , struct() });

% Setup Stability Vertex Defaults
opt.stability_vertex = psom_struct_defaults(opt.stability_vertex,...
                       { 'nb_samps' , 'nb_batch', 'clustering' },...
                       { 10         , 100       , struct       });
opt.stability_vertex.name_data = opt.name_data;
opt.stability_vertex.name_part = opt.name_part;
opt.stability_vertex.name_neigh = opt.name_neigh;
opt.stability_vertex.region_growing = opt.region_growing.region_growing;
opt.stability_vertex.sampling = opt.sampling;

%% Sanity checks
% Conditions:
%   - External Partition without cores (no scales - rep from part)
%   - External Partition with cores (grid - could be taken from part but
%     isn't)
%   - Plugin without cores (tar - rep can be set to tar)
%   - Plugin with cores (tar - grid can be set to tar)
%   - Consensus without cores (grid + tar - rep is determined by consensus)
%   - Consensus with cores (grid + tar - cores use the same grid)
%   - MSTEP without cores (grid - tar and rep are determined by mstep)
%   - MSTEP with cores (grid - core uses the same grid)

method          = 'None';
scale_finding   = 'None';
stab_est        = 'None';
cores           = 'None';

if ~strcmp(in.part, 'gb_niak_omitted') && ~strcmp(opt.target_type, 'manual')
    % A partition has been supplied, the target type will be forced to
    % manual
    warning(['\n\nA target partition was supplied by the user. Target cluster '...
             'type will be forced to manual!\n    old target type: '...
             '%s\n    target: %s\n\n'], opt.target_type, in.part);
    opt.target_type = 'manual';
end

switch opt.target_type
    case 'manual'
        % User wants to use an external partition
        method = sprintf('An external partition from %s will be used.',...
                         in.part);
        if strcmp(in.part, 'gb_niak_omitted')
            % User has not supplied an external partition
            error(['A target partition is required because of OPT.TARGET_TYPE '...
                   '= ''manual'' but none was supplied by the user!\n']);

        elseif opt.flag_cores && isempty(opt.scale_grid)
            % User wants to compute stable cores for the external partition but
            % hasn't supplied a scale to compute stability for - this could be
            % taken from the partition at some point but at the moment it has
            % to be supplied
            error(['Stable cores will be computed because of OPT.FLAG_CORES = '...
                   'true but OPT.SCALE_GRID is empty. Please provide a grid '...
                   'scale for every supplied external partition to compute '...
                   'stable cores!\n']);

        elseif opt.flag_cores
            % Stability cores will be estimated
            stab_est = sprintf(['The stability of the external partition '...
                        'will be estimated using %s.'], opt.cores.cores.type);
            cores = ['The stable cores of the external partition will be '...
                     'used as targets.'];
        end

    case 'plugin'
        % User wants to use a plugin clustering
        method = 'A plugin partition will be generated.';
        if isempty(opt.scale_tar)
            % User has not supplied a scale to generate plugin clusters with
            error(['A plugin clustering will be generated because '...
                   'OPT.TARGET_TYPE = ''plugin'' but OPT.SCALE_TAR is empty. '...
                   'Please provide the scales to generate the plugin clusters '...
                   'with in OPT.SCALE_TAR!\n']);
        elseif opt.flag_cores && isempty(opt.scale_grid)
            % User wants to generate stable cores of the plugin cluster but
            % has not specified the grid scale for the atom level stability
            % estimation. OPT.SCALE_GRID will be set to OPT.SCALE_TAR
            warning(['Stable cores will be computed for the plugin clusters.'...
                     ' Since no dedicated grid scale was supplied in '...
                     'OPT.SCALE_GRID the values in OPT.SCALE_TAR will '...
                     'be used.\n']);
            opt.scale_grid = opt.scale_tar;
        elseif opt.flag_cores
            % Stability cores will be estimated
            stab_est = sprintf(['The stability of the plugin partition '...
                        'will be estimated using %s.'], opt.cores.cores.type);
            cores = ['The stable cores of the plugin partition will be '...
                     'used as targets.'];
        end

    case 'cons'
        % User wants to generate a consensus clustering
        method = 'A consensus partition will be generated.';
        if isempty(opt.scale_grid)
            % User has not specified the grid scale to generate atom level
            % stability on
            error(['Consensus clustering will be run because of '...
                   'OPT.TARGET_TYPE = ''cons'' but OPT.SCALE_GRID is empty. '...
                   'Please provide the grid scales in OPT.SCALE_GRID!\n']);

        elseif any(~ismember(opt.scale_tar, opt.scale_grid))
            % User has specified a target scale of which at least some
            % scales are not members in the grid scale
            error(['At least some target scales in OPT.SCALE_TAR are not '...
                   'present in the provided grid scale OPT.SCALE_GRID. '...
                   'When consensus clustering is selected, OPT.SCALE_TAR '...
                   'must be a subset of OPT.SCALE_GRID!\n']);
        elseif ~isempty(opt.scale_rep)
            % User has specified a target scale and a replication scale. In
            % this case, the replication scale will be overwritten by the
            % consensus brick
            warning(['A target scale and a replication scale were supplied. '...
                     'The replication scale in OPT.SCALE_REP will be '...
                     'overwritten by the consensus clustering process.\n']);
            opt.scale_rep = [];
        end

        if isempty(opt.scale_tar)
            % User has not specified a target scale - thus MSTEP will be
            % run to determine a target scale
            scale_finding = ['MSTEP will be run to determine the optimal '...
                             'consensus target and replication scales based '...
                             'on the dataset.'];
            if opt.flag_cores
                % Stability cores will be estimated
                stab_est = sprintf(['The stability of the MSTEP derived '...
                                    'partition will be estimated using '...
                                    '%s.'],  opt.cores.cores.type);
                cores = ['The stable cores of the MSTEP derived partition '...
                         'will be used as targets.'];
            end

        elseif ~isempty(opt.scale_tar)
            scale_finding = ['The optimal replication scales for the '...
                             'target scales specified in OPT.SCALE_TAR '...
                             'will be determined.'];
            if opt.flag_cores
                % Stability cores will be estimated
                stab_est = sprintf(['The stability of the consensus '...
                                    'partition will be estimated using '...
                                    '%s.'],  opt.cores.cores.type);
                cores = ['The stable cores of the consensus partition will '...
                         'be used as targets.'];
            end
        end


    otherwise
        % User has specified a target type that is not implemented
        error(['The target type specified in OPT.TARGET_TYPE is '...
               'not implemented']);
end

% Give a summary of the requested parameters
message = '# PIPELINE SUMMARY: #';
box_mask = repmat('#', [length(message),1]);
end_message = '# END OF PIPELINE SUMMARY #';
box_end_mask = repmat('#', [length(end_message),1]);
fprintf('%s\n%s\n%s\n', box_mask, message, box_mask);
fprintf('Clustering           : %s\n', method);
fprintf('Scale Optimization   : %s\n', scale_finding);
fprintf('Stability Estimation : %s\n', stab_est);
fprintf('Stable Cores         : %s\n', cores);
fprintf('%s\n%s\n%s\n\n', box_end_mask, end_message, box_end_mask);

%% Start assembling the pipeline
pipe = struct;
% Get the neighbourhood matrix if none has been specified
if strcmp(in.neigh,'gb_niak_omitted')
    pipe.adjacency_matrix.command = sprintf(['ssurf = niak_read_surf('''','...
                                             'true,true); %s = ssurf.neigh;'...
                                             'save(files_out,''%s'');'],...
                                            opt.name_neigh, opt.name_neigh);
    pipe.adjacency_matrix.files_in = in.neigh;
    pipe.adjacency_matrix.files_out = [opt.folder_out 'neighbourhood.mat'];

else
    pipe.adjacency_matrix.files_in = in.neigh;
    output = [opt.folder_out 'neighbourhood.mat'];
    pipe.adjacency_matrix.command = sprintf('copyfile(files_in,''%s'');',...
                                            output);
    pipe.adjacency_matrix.files_out = output;
end

in.neigh = pipe.adjacency_matrix.files_out;

% Run Region Growing
reg_in = rmfield(in, 'part');
reg_out = [opt.folder_out sprintf('%s_region_growing_thr%d.mat',...
           opt.name_data, opt.region_growing.region_growing.thre_size)];
reg_opt = opt.region_growing;
pipe = psom_add_job(pipe, 'region_growing', ...
                    'niak_brick_stability_surf_region_growing',...
                    reg_in, reg_out, reg_opt);

% Check if we need to run the stability estimation
if opt.flag_cores || strcmp(opt.target_type, 'cons')
    % We need to run the stability estimation
    stab_est_in = struct('data', pipe.region_growing.files_out,...
                         'part_ref', in.part,...
                         'part_roi', pipe.region_growing.files_out);
    stab_est_in.data = pipe.region_growing.files_out;
    stab_est_opt = opt.stability_atom;
    pipe_stab_est = niak_pipeline_stability_estimate(stab_est_in, stab_est_opt);
    % Merge back the stability estimation pipeline with this pipeline
    pipe = psom_merge_pipeline(pipe, pipe_stab_est);

end

% See which target option is requested
switch opt.target_type
    case 'cons'
        % Perform Consensus Clustering
        cons_out = sprintf('%sconsensus_partition.mat',opt.folder_out);
        cons_in.stab = pipe.average_atom.files_out;
        cons_in.roi = pipe.region_growing.files_out;
        cons_opt = opt.consensus;
        pipe = psom_add_job(pipe, 'consensus', ...
                            'niak_brick_stability_consensus', ...
                            cons_in, cons_out, cons_opt);
        in.part = pipe.consensus.files_out;
        core_in.stab = pipe.consensus.files_out;

        % See if mstep should run
        if isempty(opt.consensus.scale_tar)
            % Run MSTEPS
            mstep_in = pipe.consensus.files_out;
            mstep_out.msteps = sprintf('%smsteps.mat',opt.folder_out);
            mstep_out.table = sprintf('%smsteps_table.mat',opt.folder_out);
            mstep_opt = opt.msteps;
            mstep_opt.rand_seed = 1;

            pipe = psom_add_job(pipe,'msteps',...
                                'niak_brick_msteps',...
                                mstep_in, mstep_out, mstep_opt);

            % Create partition from mstep
            mpart_in.cons       = pipe.consensus.files_out;
            mpart_in.roi        = pipe.region_growing.files_out;
            mpart_in.msteps     = pipe.msteps.files_out.msteps;
            mpart_out = sprintf('%smsteps_part.mat',opt.folder_out);
            mpart_opt = struct;

            pipe = psom_add_job(pipe, 'msteps_part',...
                                'niak_brick_stability_surf_msteps_part',...
                                mpart_in, mpart_out, mpart_opt);

            in.part = pipe.msteps_part.files_out;
            core_in.stab = pipe.msteps_part.files_out;
        end

    case 'plugin'
        % Perform Plugin Clustering
        plug_in = pipe.region_growing.files_out;
        plug_opt.scale_tar = opt.scale_tar;
        plug_opt.scale_rep = opt.scale_rep;
        plug_out = sprintf('%splugin_partition.mat',opt.folder_out);
        pipe = psom_add_job(pipe, 'plugin', ...
                            'niak_brick_stability_surf_plugin',...
                            plug_in, plug_out, plug_opt);
        in.part = pipe.plugin.files_out;
        if opt.flag_cores
            core_in.stab = pipe.average_atom.files_out;
        end

    case 'manual'
        % Manual Partition was supplied
        if opt.flag_cores
            core_in.stab = pipe.average_atom.files_out;
        end

    otherwise
        % The selected target is not implemented yet
        error(['The selected OPT.TARGET_TYPE (%s) is not implemented yet.\n'...
               'Exiting!\n'],opt.target_type);
end

% Check if stable cores are to be performed
if opt.flag_cores
    % Run Stable Cores
    core_in.part = in.part;
    core_in.roi = pipe.region_growing.files_out;
    core_out = sprintf('%sstab_core.mat',opt.folder_out);
    core_opt = opt.cores;

    pipe = psom_add_job(pipe, 'stable_cores', ...
                        'niak_brick_stability_surf_cores',...
                        core_in, core_out, core_opt);
    in.part = pipe.stable_cores.files_out;

end

% Run the vertex level stability estimation
for boot_batch_id = 1:opt.stability_vertex.nb_batch
    % Options
    boot_batch_opt = rmfield(opt.stability_vertex, 'nb_batch');

    if ~opt.flag_rand
        boot_batch_opt.rand_seed = boot_batch_id;
    end

    % Add job
    boot_batch_out = sprintf('%sstab_vertex_%d.mat',...
                             opt.folder_out, boot_batch_id);
    batch_name = sprintf('stab_vertex_%d', boot_batch_id);
    batch_clean_name = sprintf('clean_%s', batch_name);
    pipe = psom_add_job(pipe,batch_name, ...
                        'niak_brick_stability_surf',...
                        in, boot_batch_out, boot_batch_opt);
    pipe = psom_add_clean(pipe,batch_clean_name,pipe.(batch_name).files_out);
    avg_in{boot_batch_id} = boot_batch_out;
end

% Average over the results
avg_out = [opt.folder_out 'surf_stab_average.mat'];
avg_opt.flag_verbose = opt.flag_verbose;
avg_opt.name_scale_in = 'scale_tar';
avg_opt.name_scale_out = 'scale_tar';
avg_opt.name_data = 'scale_name';
pipe = psom_add_job(pipe,'average','niak_brick_stability_average', ...
                    avg_in, avg_out, avg_opt);

% And connect the outputs to the silhouette criterion machine
sil_in.stab = pipe.average.files_out;
sil_in.part = in.part;
sil_out = [opt.folder_out 'surf_silhouette.mat'];
sil_opt.flag_verbose = opt.flag_verbose;
pipe = psom_add_job(pipe, 'silhouette', 'niak_brick_stability_surf_contrast',...
                    sil_in, sil_out, sil_opt);

% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end
