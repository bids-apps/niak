function [] = niak_visu_part(part,opt)
% Give a representation of a partition as a binary adjacency square matrix.
%
% SYNTAX :
% [] = NIAK_VISU_PART(PART,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PART
%       (vector) PART(i) is the number of the cluster of region i.
%
% OPT
%       (structure) with the following fields:
%
%       NB_CLUSTERS
%           (integer, default max(PART(:))) The number of clusters to use
%
%       LABELS
%           (cell of strings) LABELS{J} is the label of cluster J.
%
%       TYPE_MAP
%           (string, default 'jet') the colormap used to display the clusters
%           (options: 'jet', 'hotcold' or 'none').
%           If map is 'none', the current colormap is used.
%           'jet': matlab's jet
%           'jet_white': same as matlab's jet, except that zero is mapped to white.
%
%       FLAG_LABELS
%           (boolean, default false) If FLAG_LABELS is true, labels of the
%           clusters are displayed.
%
%       FLAG_COLORBAR
%           (boolean, default true) if FLAG_COLORBAR is true, a colorbar is
%           displayed with the number of regions.
%
% _________________________________________________________________________
% OUTPUTS:
%
% a figure with a matrix representation of the partition
%
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_THRESHOLD_HIERARCHY, NIAK_THRESHOLD_STABILITY
%
% _________________________________________________________________________
% COMMENTS
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : visualization, partition, clustering

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

%% Options
gb_name_structure = 'opt';
gb_list_fields   = { 'nb_clusters' , 'labels' , 'type_map' , 'flag_labels' , 'flag_colorbar' };
gb_list_defaults = { []            , []       , 'jet'      , false         , true            };
niak_set_defaults

if isempty(nb_clusters)
    nb_clusters = max(part);
end

list_clusters = unique(part(part~=0));
list_clusters = list_clusters(:)';

if isempty(labels)
    labels = cell([nb_clusters 1]);
end

for num_c = list_clusters
    if isempty(labels{num_c})
        labels{num_c} = cat(2,'C',num2str(num_c));
    end
end

switch type_map
    case 'jet'
        coul_masks = jet(nb_clusters*10);
        colormap(coul_masks);
    case 'jet_white'
        coul_masks = jet(nb_clusters*10);
        for num_u = 1:(nb_clusters+1)
            if num_u==1
                coul_masks(1:5,:) = repmat([1 1 1],[5 1]);
            elseif num_u == (nb_clusters+1)
                coul_masks((nb_clusters*10)-4:(nb_clusters*10),:) = repmat(coul_masks((num_u-1)*10,:),[5 1]);
            else
                coul_masks((6+(num_u-2)*10):(5+(num_u-1)*10),:) = repmat(coul_masks((num_u-1)*10,:),[10 1]);
            end
        end
        colormap(coul_masks);
    case 'hotcold'
        c1 = hot(128);
        c2 = c1(:,[3 2 1]);
        coul_masks = [c2(length(c1):-1:1,:) ; c1];
        colormap(coul_masks);
    case 'none'
    otherwise
        warning('%s is an unknown color map, I am not setting the color map',type_map)

end

nb_rois = length(part);
part_m = zeros([nb_rois nb_rois]);

for num_c = list_clusters
    part_m(part==num_c,part==num_c) = num_c;
end

switch type_map
    case 'hotcold'
        imagesc(part_m,[-nb_clusters,nb_clusters]);
    otherwise
        imagesc(part_m,[0,nb_clusters]);

end

if flag_labels
    for num_c1 = list_clusters
        for num_c2 = list_clusters
            xt = mean(find(part==num_c1));
            yt = mean(find(part==num_c2));
            if num_c1 == num_c2
                h = text(xt,yt,labels{num_c1},'HorizontalAlignment','center','VerticalAlignment','middle');
            end
            set(h,'fontSize',12);
        end
    end
end

axis('square');

if flag_colorbar
    colorbar
end
