using GLMakie
using DataFrames
using MLDatasets
using LinearAlgebra
using Statistics
using TSne
using HDF5

function test_tsne()
    rescale(A; dims=1) = (A .- mean(A, dims=dims)) ./ max.(std(A, dims=dims), eps())

    train = MNIST(:train)
    feats = train.features
    targs = train.targets

    datain = reshape(permutedims(feats[:,:,1:2500],(3,1,2)),2500,size(feats,1)*size(feats,2))
    println(mean(datain),std(datain))
    
    X = rescale(datain,dims=1)

    Y = tsne(X,2,50,1000,20.0)

    println(size(Y))
    h5file = h5open("Data/tsne_result.hdf5","w")
    h5file["result"] = Y
    close(h5file)

    f = Figure()
    ax = GLMakie.Axis(f[1,1])
    image!(ax,feats[:,end:-1:1,1])
    f
    # M = fit(TSNE, feats)
    # R = predict(M)
end

test_tsne()