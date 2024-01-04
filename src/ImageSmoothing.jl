#ImageSmoothing.jl
module ImageSmoothing

using Statistics
using LazySets
using Interpolations
using StaticArrays

function movingavg(input_image::Array{Float32,3},input_λvector::Vector{Float64},box_size::Int)
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
        upperlim_subset = av_subset.+(2*sd_subset)
        lowerlim_subset = av_subset.-(2*sd_subset)

        
        subset_img[(subset_img.<lowerlim_subset).||(subset_img.>upperlim_subset)].=0.0
        wiseav_missingvals = convert(Array{Union{Float64,Missing}},subset_img)
        wiseav_missingvals[wiseav_missingvals.==0.0].=missing

        wiseav_denom = size(wiseav_missingvals)[3].-sum(ismissing.(wiseav_missingvals),dims=3)

        avg_im[:,:,band] = sum(subset_img,dims=3)./wiseav_denom
        avg_im = convert(Array{Float32},avg_im)
        #println("$(avg_im[20,20,band])...$band")
    end

    avg_λvector = input_λvector[split_index+1:size(input_image)[3]-split_index]

    return avg_im,avg_λvector
    println("Size of Image: $(size(input_image))")
end

function convexhull_removal(image::Array{Float32,3},λ)
    #Make sure the image has dimension 3 as the spectral dimension

    #Augmenting ends of spectra
    augim = zeros(size(image,1),size(image,2),size(image,3)+2)
    augim[:,:,2:end-1] = image
    augim[:,:,1] = minimum(image,dims=3).-1
    augim[:,:,end] = minimum(image,dims=3).-1

    augλ = zeros(size(λ,1)+2)
    augλ[2:end-1] = λ
    augλ[1] = λ[1]-1
    augλ[end] = λ[end]+1

    # augim2d = map(CartesianIndices(axes(augim)[1:2])) do i
    #     vec([[val,wvl] for (val,wvl) in zip(augim[Tuple(i)...,:],augλ)])
    # end
    
    coord_arr = [(x,y) for x in 1:size(augim,1),y in 1:size(augim,2)]
    function run_cvhx(pt)
        x = first(pt)
        y = last(pt)
        pts = [[i,j] for (i,j) in zip(augim[x,y,:],augλ)]
        [i[1] for i in convex_hull(pts)][2:end-1]
    end

    function run_cvhy(pt)
        x = first(pt)
        y = last(pt)
        pts = [[i,j] for (i,j) in zip(augim[x,y,:],augλ)]
        [i[2] for i in convex_hull(pts)][2:end-1]
    end

    hull_arr_y = run_cvhx.(coord_arr)
    hull_arr_x = run_cvhy.(coord_arr)

    #println(hull_arr_x[1,1])

    function run_linearinterp(pt)
        xs = hull_arr_x[pt...]
        ys = hull_arr_y[pt...]
        lin_interp = linear_interpolation(xs,ys,extrapolation_bc=Interpolations.Line())
        return lin_interp.(λ)
    end

    continuum = run_linearinterp.(coord_arr)
    continuum = permutedims([continuum[I][k] for k=eachindex(continuum[1,1]),I=CartesianIndices(continuum)],(2,3,1))

    im_contrem = image./continuum

    return continuum#im_contrem

end

end #module ImageSmoothing