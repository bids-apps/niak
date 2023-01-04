function [files_in,files_out,opt] = niak_brick_stability_tseries(files_in,files_out,opt)
% Estimate the stability of a stochastic clustering on time series.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_TSERIES(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
% (struct)
%   DATA
%       (string or cell of strings) the name(s) of one or multiple .mat file,
%       which contains one variable TS (OPT.NAME_DATA). TS(:,I) is the time
%       series of region I.
%
%   PART_REF
%       (string, optional) path to a .mat fie containing an array of dimensions
%       V by K where V is the number of atoms in FILES_IN.TSERIES and K is
%       the number of scales to be investigated. If kcores is used to generate
%       the atom level stability maps, part_ref has to be set as the
%       reference partition.
%
% FILES_OUT
%   (string) A .mat file which contains the following variables :
%
%   STAB
%       (array) STAB(:,s) is the vectorized version of the stability matrix
%       associated with OPT.NB_CLASSES(s) clusters.
%
%   SCALE_GRID or NB_CLASSES
%       (vector) The vector of scales for which stability was estimated.
%
%   PART
%       (matrix N*S) PART(:,s) is the consensus partition associated with
%       STAB(:,s), with the number of clusters optimized using the summary
%       statistics.
%
%   ORDER
%       (matrix N*S) ORDER(:,s) is the order associated with STAB(:,s) and
%       PART(:,s) (see NIAK_PART2ORDER).
%
%   SIL
%       (matrix S*N) SIL(s,n) is the mean stability contrast associated with
%       STAB(:,s) and n clusters (the partition being defined using HIER{s},
%       see below).
%
%   INTRA
%       (matrix, S*N) INTRA(s,n) is the mean within-cluster stability
%       associated with STAB(:,s) and n clusters (the partition being defined
%       using HIER{s}, see below).
%
%   INTER
%       (matrix, S*N) INTER(s,n) is the mean maximal between-cluster stability
%       associated with STAB(:,s) and n clusters (the partition being defined
%       using HIER{s}, see below).
%
%   HIER
%       (cell of array) HIER{S} is the hierarchy associated with STAB(:,s)
%
%
% OPT
%   (structure) with the following fields:
%
%   NAME_DATA
%       (string, default 'tseries'). The name of the variable in the input
%       file(s) that contains the timeseries
%
%   SCALE_GRID or NB_CLASSES
%       (vector of integer) the number of clusters (or classes) that will
%       be investigated. This will be exposed to NIAK_STABILITY_TSERIES as
%       OPT.NB_CLASSES in order to keep naming conventions
%       This parameter will overide the parameters specified in
%       CLUSTERING.OPT_CLUST
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
%
%   NB_SAMPS
%       (integer, default 100) the number of samples to use in the
%       bootstrap Monte-Carlo approximation of stability.
%
%   NORMALIZE
%       (structure, default NORMALIZE.TYPE = 'mean_var') the temporal
%       normalization to apply on the individual time series before
%       clustering. See OPT in NIAK_NORMALIZE_TSERIES.
%
%   SAMPLING
%
%       TYPE
%           (string, default 'bootstrap') how to resample the time series.
%           Available options : 'bootstrap' , 'mplm', 'scenario', 'jackid'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE :
%               'jackid' : jacknife subsampling, identical distribution. By
%                   default uses 60% timepoints. Can be controlled by
%                   opt.sampling.opt.perc.
%               'bootstrap' : see the description of the OPT
%                   argument in NIAK_BOOTSTRAP_TSERIES. Default is
%                   OPT.TYPE = 'CBB' (a circular block bootstrap is
%                   applied).
%               'mplm' : see the description of the OPT argument in
%                   NIAK_SAMPLE_MPLM.
%               'scenario' : see the description of the OPT argument in
%                   NIAK_SIMUS_SCENARIO
%
%   CLUSTERING
%       (structure, optional) with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options :
%               'kmeans': k-means (euclidian distance)
%               'kcores' : k-means cores
%               'hierarchical_e2': a HAC based on the eta-square distance
%                   (see NIAK_BUILD_ETA2)
%               'hierarchical' : a HAC based on a squared
%                   euclidian distance.
%
%       OPT
%           (structure, optional) options that will be  sent to the
%           clustering command. The exact list of options depends on
%           CLUSTERING.TYPE:
%               'kmeans' : see OPT in NIAK_KMEANS_CLUSTERING
%               'hierarchical' or 'hierarchical_e2': see OPT in
%               NIAK_HIERARCHICAL_CLUSTERING
%
%   CONSENSUS
%       (structure, optional) This structure describes
%       the clustering algorithm used to estimate a consensus clustering on
%       each stability matrix, with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 'hierarchical'
%
%       OPT
%           (structure, default see NIAK_HIERARCHICAL_CLUSTERING) options
%           that will be  sent to the  clustering command. The exact list
%           of options depends on CLUSTERING.TYPE:
%              'hierarchical' : see NIAK_HIERARCHICAL_CLUSTERING
%
%   FLAG_TEST
%       (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update the defaults of FILES_IN, FILES_OUT and OPT.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints
%       some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY, NIAK_PIPELINE_STABILITY_REST
% _________________________________________________________________________
% COMMENTS:
%
% For more details, see the description of the stability analysis on a
% individual fMRI time series in the following reference :
%
% P. Bellec; P. Rosa-Neto; O.C. Lyttelton; H. Benalib; A.C. Evans,
% Multi-level bootstrap analysis of stable clusters in resting-State fMRI.
% Neuroimage 51 (2010), pp. 1126-1139
%
% Copyright (c) Pierre Bellec
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series, consensus

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_TSERIES(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_tseries'' for more info.')
end

%% Check if files_in is a string/cell of strings for backwards compatibility
if ischar(files_in) || iscellstr(files_in)
    files_in = struct('data',files_in);
end
%% Files in
list_fields   = { 'data' , 'part_ref'        };
list_defaults = { NaN    , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in, list_fields, list_defaults);

%% Files out
if ~ischar(files_out)
    error('FILES_OUT should be a string!')
end

%% Options
list_fields   = { 'name_data' , 'rand_seed' , 'normalize' , 'nb_samps' , 'scale_grid' , 'nb_classes' , 'clustering' , 'consensus' , 'sampling' , 'flag_verbose' , 'flag_test'  };
list_defaults = { 'tseries'   , []          , struct()    , 100        , []           , []           , struct()     , struct()    , struct()   , true           , false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if isempty(opt.scale_grid) && isempty(opt.nb_classes)
    error('Please specify either opt.scale_grid or opt.nb_classes')
end

if ~isempty(opt.nb_classes)
    flag_nb_classes = true;
    opt.scale_grid = opt.nb_classes;
else
    flag_nb_classes = false;
end
opt = rmfield(opt,'nb_classes');

% Save scale_grid for saving
scale_grid = opt.scale_grid;

% Expose scale_grid as nb_classes to niak_stability_tseries
opt.nb_classes = opt.scale_grid;
nb_classes = opt.nb_classes;

% Setup Normalize Defaults
opt.normalize = psom_struct_defaults(opt.normalize,...
                { 'type'     },...
                { 'mean_var' });

% Setup Clustering Defaults
opt.clustering = psom_struct_defaults(opt.clustering,...
                 { 'type'         , 'opt'    },...
                 { 'hierarchical' , struct() });

% Setup Sampling Defaults
sampling_opt.type = 'cbb';
opt.sampling = psom_struct_defaults(opt.sampling,...
               { 'type'      , 'opt'        },...
               { 'bootstrap' , sampling_opt });

% Setup Consensus Defaults
opt.consensus = psom_struct_defaults(opt.consensus,...
                { 'type'         },...
                { 'hierarchical' });

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Check if we need to get a reference partition for kcores
if strcmp(opt.clustering.type, 'kcores')
    if ~strcmp(files_in.part_ref, 'gb_niak_omitted')
        % Get the reference partition and hand it over to the clustering
        % options field
        part_f = load(files_in.part_ref);
        opt.clustering.opt.target_part = part_f.part;
        if isfield(part_f, 'scale_tar')
            opt.clustering.opt.target_scale = part_f.scale_tar;
        end
    else
        error(['FILES_IN.PART_REF has to be set when OPT.CLUSTERING.TYPE '...
               'is kcores']);
    end

    % Check if the number of scales in the reference partition is
    % sufficient for the number of scales defined in opt.scale_grid
    if length(opt.clustering.opt.target_scale) < length(opt.nb_classes)
        % The supplied partition does not have enough scales
        error(['The reference partition supplied in FILES_IN.PART_REF '...
               'has only %d scales but %d scales are requested in '...
               'OPT.SCALE_GRID. Please supply a reference partition with '...
               'the same number of scales as OPT.SCALE_GRID'],...
              length(opt.clustering.opt.target_scale), length(opt.nb_classes));
    end
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the time series
if opt.flag_verbose
    fprintf('Read the time series ...\n');
end

if ischar(files_in.data)
    files_in.data = {files_in.data};
end

for num_f = 1:length(files_in.data)
    data = load(files_in.data{num_f}, opt.name_data);
    if num_f == 1
        tseries = niak_normalize_tseries(data.(opt.name_data), opt.normalize);
    else
        tseries = [tseries ; niak_normalize_tseries(data.(opt.name_data), opt.normalize)];
    end
end
tseries = niak_normalize_tseries(tseries, opt.normalize);

%% Stability matrix
opt_s = rmfield(opt,{'name_data','scale_grid','flag_test','consensus','rand_seed'});
stab = niak_stability_tseries(tseries,opt_s);

%% Consensus clustering
opt_c.clustering = opt.consensus;
opt_c.flag_verbose = opt.flag_verbose;
[part, order, sil, intra, inter, hier] = niak_consensus_clustering(stab,opt_c);

%% Save outputs
if opt.flag_verbose
    fprintf('Save outputs ...\n');
end

if flag_nb_classes
    save(files_out,'stab','nb_classes','part','hier','order','sil','intra','inter')
else
    save(files_out,'stab','scale_grid','part','hier','order','sil','intra','inter')
end
