using GLMakie
using MLDatasets
using Distances
using Clustering
using DataFrames
using StatsBase
using HDF5
using ClassifySpectral
using Statistics

rescale(A; dims=1) = (A .- mean(A, dims=dims)) ./ max.(std(A, dims=dims), eps())
normal(A,dims=1) = (A .- minimum(A))./(maximum(A.-minimum(A)))

λ =  parse.(Float64,readlines(open("smoothed_wvl_data.txt")))

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

function dendrogram(h, image, feats, coords; color = :blue, kwargs...)

    f = Figure()
    ax = GLMakie.Axis(f[1, 2])
    sl = Slider(f[1, 1],horizontal=false,range=range(0,maximum(h.heights),1000),startvalue=0)
    butt = Button(f[2,2],tellwidth=false,label="Plot Cluster Spectra")
        

    height_tracker = lift(sl.value) do val
        val
    end

    cluster_tracker = lift(sl.value) do val
        cluster_list = cutree(h,h=val)
        cluster_list = [range(0,1,maximum(cluster_list))[i] for i in cluster_list]
        return cluster_list
    end

    println(size(to_value(cluster_tracker)))
    f1 = Figure()
    ax1 = GLMakie.Axis(f1[1,1])
    image!(ax1,image[:,:,1],interpolate=false,colorrange=(0,0.2),lowclip=:red)
    scatter!(ax1,coords,color=cluster_tracker,colorrange=(0,1),markersize=9)
    
    hlines!(ax,height_tracker,minimum(h.order),maximum(h.order))
    
    for (x, y) in zip(treepositions(h; kwargs...)...)
        lines!(ax,x, y; color)
    end

    f2 = Figure()
    ax2 = GLMakie.Axis(f2[1,1])

    on(butt.clicks) do click
        empty!(ax2)
        cluster_vals = to_value(cluster_tracker)
        unique_clusters = unique(cluster_vals)
        
        feats_clusters = hcat(feats,cluster_vals)
        println("# of Clusters: $(length(unique_clusters))")
        
        for i in eachindex(unique_clusters)
            lines!(ax2, λ, vec(mean(feats_clusters[feats_clusters[:,end].==unique_clusters[i],1:end-1],dims=1)),color=i,colormap=:viridis,colorrange=(1,length(unique_clusters)))
        end
    end

    display(GLMakie.Screen(),f)
    display(GLMakie.Screen(),f1)
    display(GLMakie.Screen(),f2)
end


function run_hc(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[index]])
    #arr = arr[:,end:-1:1,:]
    close(h5file)

    #Eliminating shadey pixels
    std_arr = std(arr,dims=3)
    bad_coords = Tuple.(findall(std_arr.<0.02))
    bad_imcoords = CartesianIndex.([i[1:2] for i in bad_coords])
    arr[bad_imcoords,:].=-9999

    #arr = arr[:,end:-1:1,:]

    # wvl_str = readlines(open("wvl_data.txt"))
    # wvl = map(x->parse(Float64,x),wvl_str)

    wvl_str = readlines(open("smoothed_wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)


    # smooth_arr,smooth_λ = ClassifySpectral.ImageSmoothing.movingavg(arr,wvl,9)
    # h5file = h5open("Data/gd_region_smoothed.hdf5","w")
    # h5file["gamma"] = smooth_arr
    # close(h5file)
    
    # #ImageUtils.build_specgui(smooth_arr,smooth_λ)
    arr_shape = size(arr)
    feats = reshape(arr,arr_shape[1]*arr_shape[2],arr_shape[3])
    feats = feats[findall(feats[:,1].!=-9999),:]
    #Rescaling!
    #feats = rescale(feats,dims=1)
    feats = mapslices(normal,feats,dims=2)

    coords = Tuple.(findall(arr[:,:,1] .!= -9999))

    println(size(feats))
    println(size(coords))

    println("getting distance matrix...")

    subset_ind = sample(eachindex(feats[:,1]),5000,replace=false)
    feats_subset = feats[subset_ind,:]
    println(size(feats_subset))
    subset_coords = coords[subset_ind]

    d = pairwise(Euclidean(),transpose(feats_subset))
    println(d==transpose(d))
    clust_result = hclust(d)

    dendrogram(clust_result,arr,feats_subset,subset_coords,useheight=true)
    # dendrogram(clust_result_list[2])

    # close(h5file)
end

function test_hc()
    iris = Iris()
    targs = iris.targets
    feats = iris.features

    feat_arr = Matrix(feats)
    d = pairwise(Euclidean(),transpose(feat_arr))
    h = hclust(d)

    dendrogram(h, feats, useheight=true)
end

run_hc("Data/gd_region_smoothed.hdf5",1)
#test_hc()