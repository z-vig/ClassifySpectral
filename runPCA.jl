#runPCA.jl

@time begin
using Plots;gr()
using Images, ImageView
using Statistics
using LinearAlgebra
using ClassifySpectral


test_im = load("Data/cont_rem.tif")
test_im = permutedims(test_im,(3,1,2))
test_im = Float64.(test_im)

mat,λvector = ClassifySpectral.run_PCA(test_im)

mat = mat[:,2:end-1]
λvector = λvector[2:end-1]

reduced_mat = mat[:,end-5:end-1]
Cₓ = cov(mat)
display(Cₓ)

imshow(Cₓ)

variance_data = zeros(size(Cₓ)[1])
for i ∈ eachindex(Cₓ[:,1])
    variance_data[i] = Cₓ[i,i]
end

P = eigvecs(Cₓ)



p1 = plot(λvector,test_im[20,20,:])
p2 = plot(λvector,variance_data)
display(p2)
end #time
