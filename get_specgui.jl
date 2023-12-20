#get_specgui.jl
@time begin

using ClassifySpectral
using HDF5
using GLMakie

function convert_tifs()
    srcdir = "C:/Users/zacha/Python Code/M3_Gruithuisen_Region/Data/Pipeline_Out_10-29-23/rfl_cropped"

    dstdir = "Data/gd_region"

    ImageUtils.tifdir2hdf5(srcdir,dstdir)

end

function build_specgui()
    h5file = h5open("Data/gd_region.hdf5","r")
    arr = read(h5file[keys(h5file)[1]])
    close(h5file)



    f = Figure(size=(400,450))
    ax = Axis(f[1,1])
    hidedecorations!(ax)
    ax.title = "Gruithuisen Gamma"
    sl_exp = Slider(f[2,1],range=0:0.001:1,startvalue=0.5)

    cstretch = @lift((0,$(sl_exp.value)))
    image!(ax,arr[:,end:-1:1,1],xticks=[],colorrange=cstretch)

    f
end

function test_makie()
    f = Figure(size=())
    ax = Axis(f[1,1])
    x = range(0,10,100)
    y = sin.(x)
    scatter!(ax,x,y,
    color = :red,
    )
    f
end

#convert_tifs()
build_specgui()
#test_makie()

end #time