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

function get_kmeans(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[index]])
    #arr = arr[:,end:-1:1,:]

    wvl_str = readlines(open("smoothed_wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    # smooth_arr,smooth_λ = ClassifySpectral.ImageSmoothing.movingavg(arr,wvl,9)
    #ImageUtils.build_specgui(smooth_arr,smooth_λ)
    arr_shape = size(arr)

    flat_arr = reshape(arr,arr_shape[1]*arr_shape[2],arr_shape[3])

    flat_arr = transpose(flat_arr)
    println(size(flat_arr))
    R = ClassifySpectral.run_kmeans(flat_arr,3)

    clusters = assignments(R)
    c = counts(R)
    println(c)

    cluster_map = reshape(clusters,arr_shape[1],arr_shape[2])
    println(size(cluster_map))

    f= Figure()
    ax = GLMakie.Axis(f[1,2])

    sl = Slider(f[1,1],horizontal=false, range=range(0,1,1000),startvalue=1)

    alph = lift(sl.value) do x
        x
    end
    image!(ax,arr[:,end:-1:1,1],alpha=1)
    image!(ax,cluster_map[:,end:-1:1],colormap=[:red,:green,:blue],alpha=alph)

    f
end

#convert_tifs()
get_kmeans("Data/gd_region.hdf5",1)
#run_ui("Data/gd_region_smoothed.hdf5",1)

end #time