@time begin
using Plots
#using Statistics
using ImageView
using JLD2
using FileIO
using Printf
using ProgressMeter
using ClassifySpectral

function run_test_pca()
    λvector = ClassifySpectral.ImageUtils.getλ("smoohted_wvl_data.txt")

    test_img = ImageUtils.dataloadin("D:/ice_data_sample/rfl_smooth_jld2")
    pixperband = length(test_img[:,:,1])
    numbands = size(test_img)[end]
    data_matrix=zeros(Float32,(pixperband,numbands))
    for i ∈ eachindex(test_img[1,1,:])
        data_matrix[:,i] = vec(test_img[:,:,i])
    end
    Cₓ,P,Cᵥ,Y = run_PCA(data_matrix,size(test_img))
    jld_dict = Dict("C_x"=>Cₓ,"P"=>P,"C_v"=>Cᵥ,"Y"=>Y)
    save("Data/PCA_results/stamp2.jld2",jld_dict)
end

function plot_pca_results(pca_dict)
    Cₓ = pca_dict["C_x"]
    P = pca_dict["P"]
    Cᵥ = pca_dict["C_v"]
    Y = pca_dict["Y"]
end

run_test_pca()
pca_dict = load("Data/PCA_results/stamp2.jld2")
plot_pca_results(pca_dict)


end #time