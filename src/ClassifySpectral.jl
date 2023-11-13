module ClassifySpectral
export ImageUtils,run_PCA

using Statistics
using MultivariateStats

include("ImageUtils.jl")
include("ImageSmoothing.jl")


function run_PCA(input_img::Array{Float64})
    λvector = ImageUtils.getλ("smoohted_wvl_data.txt")
    pixperband = length(input_img[:,:,1])
    numbands = size(input_img)[end]
    data_matrix=zeros(Float64,(pixperband,numbands))
    for i ∈ eachindex(input_img[1,1,:])
        data_matrix[:,i] = vec(input_img[:,:,i])
    end

    #Normalizing...
    #col_mean = repeat(mean(data_matrix,dims=1),outer=(pixperband,1))
    # col_mean = mean(data_matrix,dims=1)
    # col_std = std(data_matrix,dims=1)
    # for i ∈ eachindex(data_matrix[1,:])
    #     data_matrix[:,i] .-= col_mean[i]
    # end

    #Removing continuum removal hinge points
    # data_matrix = data_matrix[:,2:end-1]
    # λvector = λvector[2:end-1]

    #PCA Package
    Cₓ = cov(data_matrix,dims=1,corrected=true)
    P = eigvecs(Cₓ)
    Cᵥ = transpose(P)*Cₓ*P
    Y = transpose(P)*transpose(data_matrix)

    #pca_run = PCA(principalratio=1)

    return data_matrix,λvector,Cₓ,P,Cᵥ,Y
end


end # module ClassifySpectral
