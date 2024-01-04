module ClassifySpectral
export ImageUtils,run_PCA,ParamImage

using Statistics
using MultivariateStats
using Clustering
using LinearAlgebra

include("ImageSmoothing.jl")
include("ImageUtils.jl")

struct ParamImage
    smooth_rfl::Array{Array{Float32}}
end

function spec_angle(refspec::Vector{Float64})

end


function run_PCA(data_matrix::Array{Float64},imshape::Tuple)

    Cₓ = cov(data_matrix,dims=1,corrected=true)
    P = eigvecs(Cₓ)[:,end:-1:1]

    Cᵥ = diagm(vec(eigvals(Cₓ)[end:-1:1]))
    #Cᵥ = transpose(P)*Cₓ*P
    Y = P*transpose(data_matrix)
    @info P[1:10,1:10]
    @info transpose(data_matrix)[1:10,1:10]
    @info Y[1:10]

    #Y = reshape(transpose(Y),imshape)

    #pca_run = PCA(principalratio=1)

    return Cₓ,P,Cᵥ,Y
end

function run_kmeans(data_matrix,k::Int64)

    result = kmeans(data_matrix,k)

    return result
end


end # module ClassifySpectral
