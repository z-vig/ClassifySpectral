#get_specgui.jl
@time begin

using ClassifySpectral
using HDF5
using Distances
using GLMakie
using StatsBase
using ProgressBars
using Clustering
using Statistics

function smooth_im(h5path)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[2]])
    close(h5file)

    wvl = [parse(Float64,i) for i in readlines(open("wvl_data.txt"))]

    smooth_arr,smooth_λ = ClassifySpectral.ImageProcessing.movingavg(arr,wvl,9)

    h5file = h5open("Data/gd_region_smoothed.hdf5","r+")
    h5file["nw"] = smooth_arr
    close(h5file)
end

function convert_tifs()
    srcdir = "C:/Users/zvig/Desktop/python_code/M3_Gruithuisen_Region/Data/Pipeline_Out_10-23-23/rfl_cropped"

    dstdir = "Data/gd_region"

    ImageUtils.tifdir2hdf5(srcdir,dstdir)
end

function run_ui(h5path1,h5path2,index)
    h5file1 = h5open(h5path1,"r")
    h5file2 = h5open(h5path2,"r")
    im_arr = read(h5file1[keys(h5file1)[index]])
    spec_arr = read(h5file2[keys(h5file2)[index]])

    im_arr = im_arr[:,end:-1:1,:]
    spec_arr = spec_arr[:,end:-1:1,:]

    wvl_str = readlines(open("smoothed_wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    f_image,f = ImageUtils.build_specgui(im_arr,spec_arr,wvl)

    return f_image,f
end

function get_kmeans(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[1]])
    close(h5file)
    #arr = arr[:,end:-1:1,:]

    #Eliminating shadey pixels
    mean_arr = mean(arr,dims=3)
    bad_coords = Tuple.(findall(mean_arr.<0.05))
    bad_imcoords = CartesianIndex.([i[1:2] for i in bad_coords])
    arr[bad_imcoords,:].=-9999

    wvl_str = readlines(open("wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    #ImageUtils.build_specgui(smooth_arr,smooth_λ)
    arr_shape = size(arr)

    flat_arr = reshape(arr,arr_shape[1]*arr_shape[2],arr_shape[3])
    shade_ind = findall(flat_arr[:,1].==-9999)
    good_ind = findall(flat_arr[:,1].!=-9999)
    flat_arr_noshade = flat_arr[good_ind,:]

    flat_arr_noshade = transpose(flat_arr_noshade)
    println(size(flat_arr_noshade))

    K = 2

    R = ClassifySpectral.run_kmeans(flat_arr_noshade,K)

    clusters = assignments(R)
    c = counts(R)
    println(c)

    clusters_with_shade = zeros(size(flat_arr,1))
    println(size(clusters_with_shade))
    clusters_with_shade[good_ind] .= clusters
    clusters_with_shade[shade_ind] .= -9999

    cluster_map = reshape(clusters_with_shade,arr_shape[1],arr_shape[2])
    println(size(cluster_map))

    cluster_avs = zeros(K,size(arr,3))
    for i in unique(clusters_with_shade)
        if i!=-9999
            println(i)
            cluster_avs[Int(i),:].=vec(mean(arr[cluster_map.==i,:],dims=1))
        end
    end

    f= Figure()
    ax = GLMakie.Axis(f[1,2])

    sl = Slider(f[1,1],horizontal=false, range=range(0,1,1000),startvalue=1)

    alph = lift(sl.value) do x
        x
    end

    image!(ax,arr[:,end:-1:1,1],alpha=1,colorrange=(0,0.2),lowclip=:black)
    image!(ax,cluster_map[:,end:-1:1],colormap=[:red,:green,:blue,:purple,:brown],colorrange=(1,5),lowclip=:transparent,alpha=alph,interpolate=false)

    f2 = Figure()
    ax2 = GLMakie.Axis(f2[1,1])
    λ = [parse(Float64,i) for i in readlines(open("smoothed_wvl_data.txt"))]
    color_list = [:red,:green,:blue]
    for i in eachindex(cluster_avs[:,1])
        println(i)
        lines!(ax2,λ,cluster_avs[i,:],label="Cluster $i",color=color_list[i])
    end

    f2[1,2]=Legend(f2,ax2,colorrange=(1,3))

    display(GLMakie.Screen(),f)
    display(GLMakie.Screen(),f2)

    return f,f2
end

function silhouette_val(h5path)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[1]])
    close(h5file)

    #Eliminating shadey pixels
    mean_arr = mean(arr,dims=3)
    bad_coords = Tuple.(findall(mean_arr.<0.05))
    bad_imcoords = CartesianIndex.([i[1:2] for i in bad_coords])
    arr[bad_imcoords,:].=-9999

    arr_shape = size(arr)
    flat_arr = reshape(arr,arr_shape[1]*arr_shape[2],arr_shape[3])
    shade_ind = findall(flat_arr[:,1].==-9999)
    good_ind = findall(flat_arr[:,1].!=-9999)
    flat_arr_noshade = flat_arr[good_ind,:]

    flat_arr_noshade = transpose(flat_arr_noshade)
    rand_ind = rand(1:size(flat_arr_noshade,2),5000)
    random_dist = pairwise(Euclidean(),flat_arr_noshade[:,rand_ind])
    svals = []
    for K in tqdm(2:8)
        R = ClassifySpectral.run_kmeans(flat_arr_noshade,K)
        rand_clusters = assignments(R)[rand_ind]
        sval = mean(silhouettes(rand_clusters,random_dist))
        push!(svals,sval)
    end

    for i in eachindex(svals)
        println("For $(i+1) Clsuters: $(svals[i])")
    end
end

#convert_tifs()
#f_im,f = get_kmeans("Data/gd_region_smoothed.hdf5",1)
#silhouette_val("Data/gd_region_smoothed.hdf5")
f_im,f = run_ui("Data/gd_region_smoothed.hdf5","Data/gd_region_smoothed.hdf5",1)
#smooth_im("Data/gd_region.hdf5")

end #time