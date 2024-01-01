#get_specgui.jl
@time begin

using ClassifySpectral
using HDF5
using Distances
using GLMakie

function convert_tifs()
    srcdir = "C:/Users/zacha/Python Code/M3_Gruithuisen_Region/Data/Pipeline_Out_10-29-23/rfl_cropped"

    dstdir = "Data/gd_region"

    ImageUtils.tifdir2hdf5(srcdir,dstdir)

end

function run_ui(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[index]])
    arr = arr[:,end:-1:1,:]

    wvl_str = readlines(open("wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    ImageUtils.build_specgui(arr,wvl)
end

function run_kmeans(h5path,index)
    h5file = h5open(h5path,"r")
    arr = read(h5file[keys(h5file)[index]])
    arr = arr[:,end:-1:1,:]

    wvl_str = readlines(open("wvl_data.txt"))
    wvl = map(x->parse(Float64,x),wvl_str)

    smooth_arr,smooth_λ = ClassifySpectral.ImageSmoothing.movingavg(arr,wvl,9)
    println(findall(isnan.(smooth_arr)))

    f = Figure()
    ax = Axis(f[1,1])
    image!(ax,smooth_arr[:,:,1])
    f
    #ImageUtils.build_specgui(smooth_arr,wvl)
end

run_kmeans("Data/gd_region.hdf5",1)
#run_ui("Data/gd_region.hdf5",2)

end #time