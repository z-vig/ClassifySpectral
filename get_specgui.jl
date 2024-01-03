#get_specgui.jl
@time begin

using ClassifySpectral
using HDF5
using Distances
using GLMakie
using StatsBase
using ProgressBars
using Clustering

function convert_tifs()
    srcdir = "C:/Users/zvig/Desktop/python_code/M3_Gruithuisen_Region/Data/Pipeline_Out_10-23-23/rfl_cropped"

    dstdir = "Data/gd_region"

    ImageUtils.tifdir2hdf5(srcdir,dstdir)

end

function run_ui(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[index]])
    #arr = arr[:,end:-1:1,:]

    wvl_str = readlines(open("smoothed_wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    ImageUtils.build_specgui(arr,wvl)
end

function run_kmeans(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[index]])
    close(h5file)
    #arr = arr[:,end:-1:1,:]

    wvl_str = readlines(open("wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    smooth_arr,smooth_λ = ClassifySpectral.ImageSmoothing.movingavg(arr,wvl,9)

    h5file = h5open("Data/gd_region_smoothed.hdf5","w")
    h5file["gamma"] = smooth_arr
    close(h5file)

    #ImageUtils.build_specgui(smooth_arr,smooth_λ)
    # arr_shape = size(smooth_arr)

    # flat_arr = reshape(smooth_arr,arr_shape[1]*arr_shape[2],arr_shape[3])

    # println("getting distance...")
    # iter = ProgressBar(1:2)
    # clust_result_list = []
    # for i ∈ iter
    #     subset_ind = sample(1:size(flat_arr)[1],9000,replace=false)
    #     arr_subset = flat_arr[subset_ind,:]


    #     d = pairwise(Euclidean(),transpose(arr_subset),dims=2)

    #     clust_result = hclust(d)
    #     push!(clust_result_list,clust_result)
    #     set_postfix(iter,Size=size(d))
    # end

    # println(size(clust_result_list[1].merges))
end

#convert_tifs()
run_kmeans("Data/gd_region.hdf5",1)
#run_ui("Data/gd_region.hdf5",1)

end #time