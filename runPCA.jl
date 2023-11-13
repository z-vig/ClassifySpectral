#runPCA.jl

@time begin
using Plots;gr()
using Images, ImageView
using Statistics
using LinearAlgebra
using ClassifySpectral
using JLD

# test_im = load("Data/im_data1.jld")["data"]

test_im = load("Data/cont_rem.tif")
println(size(test_im))
test_im_array = permutedims(test_im,(3,1,2))
test_im_array = Float64.(test_im_array)
println(size(test_im_array))

mat,λvector,Cₓ,P,Cᵥ,Y = ClassifySpectral.run_PCA(test_im_array)

Y_image = reshape(transpose(Y),size(test_im_array))

imshow(test_im_array)
imshow(Gray.(Y_image))

variance_data = zeros(size(Cₓ)[1])
for i ∈ eachindex(Cₓ[:,1])
    variance_data[i] = Cᵥ[i,i]
end

display(Cᵥ)

println(
    "Total Variance: $(tr(Cᵥ))
    PC1: $(Cᵥ[end,end])
    PC2: $(Cᵥ[end-1,end-1])"
)

println(
    "Shape of Y: $(size(Y))"
)

p1 = plot(λvector,test_im_array[20,20,:])
display(p1)
p2 = plot(λvector,P[:,end],label="PC1")
plot!(λvector,P[:,end-1],label="PC2")
plot!(λvector,P[:,end-2],label="PC3")
ylabel!("Vector Weight")
xlabel!("Wavelength (μm)")
#plot!(λvector,P[:,])
savefig("G:/My Drive/Vector_Components_contrem.ps")
display(p2)
p3 = plot(reverse(100*variance_data./tr(Cᵥ))[1:10])
ylabel!("% Explained Variance")
xlabel!("Principal Component")
savefig("G:/My Drive/Explained_Variance_contrem.ps")
display(p3)
p4 = scatter(Y[end,1:10000],Y[end-1,1:10000],Y[end-2,1:10000])
xlabel!("PC1")
ylabel!("PC2")
zlabel!("PC3")
savefig("G:/My Drive/PC1_PC2_PC3_contrem.png")
display(p4)

end #time