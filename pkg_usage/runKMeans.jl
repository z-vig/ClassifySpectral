@time begin
using ClassifySpectral
using JLD2

function get_kmeans_results()
    pca_results = load("Data/PCA_results/gruit_gamma.jld2")
    Y = convert(Array,pca_results["Y"])

    pixperband = length(Y[:,:,1])
    numbands = size(Y)[end]
    data_matrix=zeros(Float32,(numbands,pixperband))
    for i ∈ eachindex(Y[1,1,:])
        data_matrix[i,:] = vec(Y[:,:,i])
    end
    @info size(data_matrix)

    kmeans_results = ClassifySpectral.run_kmeans(data_matrix,3)

    return kmeans_results
end

results = get_kmeans_results()
size(assignments(results))

end #time