module ClassifySpectral
export ImageUtils,run_PCA

using Statistics
using MultivariateStats

include("ImageUtils.jl")
include("ImageSmoothing.jl")


function run_PCA(data_matrix::Array{Float64})

    #PCA Package
    Cₓ = cov(data_matrix,dims=1,corrected=true)
    P = reverse(eigvecs(Cₓ))
    Cᵥ = transpose(P)*Cₓ*P
    Y = P*transpose(data_matrix)

    #pca_run = PCA(principalratio=1)

    return Cₓ,P,Cᵥ,Y
end


end # module ClassifySpectral
