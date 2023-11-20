module ClassifySpectral
export ImageUtils,run_PCA,ParamImage

using Statistics
using MultivariateStats

include("ImageUtils.jl")
include("ImageSmoothing.jl")

struct ParamImage
    smooth_rfl::Array{Array{Float32}}
end

function spec_angle(refspec::Vector{Float64})

end


function run_PCA(data_matrix::Array{Float32},imshape::Tuple)

    Cₓ = cov(data_matrix,dims=1,corrected=true)
    P = eigvecs(Cₓ)[:,end:-1:1]
    Cᵥ = transpose(P)*Cₓ*P
    Y = P*transpose(data_matrix)

    Y = reshape(transpose(Y),imshape)

    #pca_run = PCA(principalratio=1)

    return Cₓ,P,Cᵥ,Y
end

function run_kmeans(data_matrix::Array{Float32})

    result = kmeans(data_matrix)

end


end # module ClassifySpectral
