using ClassifySpectral
using HDF5
using GLMakie

function removing_continuum()
    h5file= h5open("Data/gd_region_smoothed.hdf5")
    im = read(h5file[keys(h5file)[1]])
    close(h5file)

    λ = [parse(Float64,i) for i in readlines(open("smoothed_wvl_data.txt"))]
    contrem = ClassifySpectral.ImageSmoothing.convexhull_removal(im,λ)

    # println(continuum[1,1])

    h5savefile = h5open("Data/gd_region_continuum.hdf5","w")
    h5savefile["gamma"] = contrem
    close(h5savefile)

    # TESTX = rand(1:size(im,1))
    # TESTY = rand(1:size(im,2))

    # f = Figure()
    # ax = GLMakie.Axis(f[1,1])
    # lines!(ax,λ,continuum_removed[TESTX,TESTY])
    # ax.title = "$TESTX, $TESTY"
    # f
end

removing_continuum()