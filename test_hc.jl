using StatsBase
using DataFrames
using MLDatasets
using GLMakie
using Clustering
using Distances

function treepositions(hc::Hclust; useheight = true, orientation = :vertical)
    order = StatsBase.indexmap(hc.order)
    nodepos = Dict(-i => (float(order[i]), 0.0) for i in hc.order)
    xs = []
    ys = []
    for i in 1:size(hc.merges, 1)
        x1, y1 = nodepos[hc.merges[i, 1]]
        x2, y2 = nodepos[hc.merges[i, 2]]
        xpos = (x1 + x2) / 2
        ypos = useheight ?  hc.heights[i] : (max(y1, y2) + 1)
        nodepos[i] = (xpos, ypos)
        push!(xs, [x1, x1, x2, x2])
        push!(ys, [y1, ypos, ypos, y2])
    end
    if orientation == :horizontal
        return ys, xs
    else
        return xs, ys
    end
end

function dendrogram(h; color = :blue, kwargs...)
    f = Figure()
    sl = Slider(f[1,1],range=range(minimum(h.heights),maximum(h.heights),100),startvalue=0,horizontal=false)
    ax2 = GLMakie.Axis(f[1, 2])
    
    h_tracker = lift(sl.value) do x
        x
    end

    track_clust = lift(sl.value) do x
        cluster_list = cutree(h,h=x)
        cluster_list = [range(0,1,maximum(cluster_list))[i] for i in cluster_list]
        println(cluster_list)
        for (x, y, col) in zip(treepositions(h; kwargs...)...,cluster_list)
            lines!(x, y; color=col,colormap=:acton,colorrange=(0,1))
        end
    end

    hlines!(ax2,h_tracker,1,maximum(h.order))


    display(f)
end

function iris_plot()
    iris = Iris()
    targs = iris.targets
    feats = iris.features
    feat_arr = Matrix(feats)

    d = pairwise(Euclidean(),transpose(feat_arr))
    clust = hclust(d)
    dendrogram(clust)
end

iris_plot()

