#ImageSmoothing.jl
module ImageSmoothing

using Statistics

function movingavg(input_image::AbstractArray,input_λvector::Vector{Float64},box_size::Int)
    if box_size%2==0
        throw(DomainError(box_size,"Box Size must be odd!"))
    end

    split_index::Int = (box_size-1)/2
    avg_im_size = (size(input_image)[1:2]...,size(input_image)[3]-(2*split_index))
    avg_im = zeros(avg_im_size)

    for band ∈ 1:size(avg_im)[3]
        subset_img = input_image[:,:,band:band+(2*split_index)]
        av_subset = mean(subset_img,dims=3)
        sd_subset = std(subset_img,dims=3)
        upperlim_subset = av_subset.+(2*sd_im)
        lowerlim_subset = av_subset.-(2*sd_im)
        wise_subset = subset_img[]

        avg_im[:,:,band] = 

        #println("$(avg_im[20,20,band])...$band")
    end

    avg_λvector = input_λvector[split_index+1:size(input_image)[3]-split_index]

    return avg_im,avg_λvector
    println("Size of Image: $(size(input_image))")
end

end #module ImageSmoothing