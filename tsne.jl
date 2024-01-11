using GLMakie
using DataFrames
using MLDatasets
using LinearAlgebra
using Statistics
using TSne
using HDF5

function test_tsne()
    rescale(A; dims=1) = (A .- mean(A, dims=dims)) ./ max.(std(A, dims=dims), eps())

    arr = ImageUtils.gethdf5("Data/gd_region_smoothed.hdf5")

    feats = reshape(arr,)


end

test_tsne()