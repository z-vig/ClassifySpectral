#runPCA.jl

@time begin
using Plots
using Images, ImageView
using Statistics
using LinearAlgebra
using ClassifySpectral
using TiffImages

# test_im = load("Data/im_data1.jld")["data"]

test_im = TiffImages.load("Data/gruit.tif")
#println(size(test_im))
#test_im_array = permutedims(test_im,(3,1,2))
test_im_array = Float64.(test_im)
#println(size(test_im_array))

λvector = ClassifySpectral.ImageUtils.getλ("smoohted_wvl_data.txt")
pixperband = length(test_im_array[:,:,1])
numbands = size(test_im_array)[end]
data_matrix=zeros(Float64,(pixperband,numbands))
for i ∈ eachindex(test_im_array[1,1,:])
    data_matrix[:,i] = vec(test_im_array[:,:,i])
end
@info size(data_matrix)


Cₓ,P,Cᵥ,Y = ClassifySpectral.run_PCA(data_matrix,size(test_im_array))
jld_dict = Dict("Cx"=>Cₓ,"P"=>P,"Cv"=>Cᵥ,"Y"=>Y,"data_matrix"=>data_matrix)
save("Data/PCA_results/gruit_gamma.jld2",jld_dict)

Y = reshape(transpose(Y),size(test_im_array))
# imshow(test_im_array)
# imshow(Gray.(Y))
# imshow(abs.(Cₓ))
#save("C:/Users/zvig/Desktop/python_code/M3_Gruithuisen_Region/Data Products/PC2.tif",Gray.(Y_image))

variance_data = zeros(size(Cₓ)[1])
for i ∈ eachindex(Cₓ[:,1])
    variance_data[i] = Cᵥ[i,i]
end

# display(Cᵥ)

println(
    "Total Variance: $(tr(Cᵥ))
    PC1: $(Cᵥ[1,1])
    PC2: $(Cᵥ[2,2])"
)

println(
    "Shape of Y: $(size(Y))"
)

p1 = plot(λvector,test_im_array[20,20,:])
display(p1)
p2 = plot(λvector,P[:,1],label="PC1")
plot!(λvector,P[:,2],label="PC2")
plot!(λvector,P[:,3],label="PC3")
ylabel!("Vector Weight")
xlabel!("Wavelength (μm)")
#plot!(λvector,P[:,])
#savefig("G:/My Drive/Vector_Components_contrem.ps")
display(p2)
p3 = plot((100*variance_data./tr(Cᵥ))[1:10])
ylabel!("% Explained Variance")
xlabel!("Principal Component")
#savefig("G:/My Drive/Explained_Variance_contrem.ps")
display(p3)
p4 = scatter(vec(Y[:,:,1])[1:4:end],vec(Y[:,:,2])[1:4:end])#,vec(Y[:,:,3])[1:4:end])
xlabel!("PC1")
ylabel!("PC2")
#zlabel!("PC3")
#savefig("G:/My Drive/PC1_PC2_PC3_smooth.png")
display(p4)

#display(Y)

end #time