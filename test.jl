using Images, ImageView
using JLD
using Statistics
using FileIO

im = load("Data/smooth_im1.tif")

println("Image of Size: $(size(im)) Loaded")

float_im = Float64.(im)
#float_im[(float_im.<0.004).||(float_im.>0.14)] .= -9999
#save("Data/smooth_im_corrected.tif",Gray.(float_im))

std_im = std(float_im,dims=3)
println(size(std_im))

min_index = findall(av_im.==minimum(av_im))[1]
println(
    "Minimum: $(minimum(av_im)) @ $(Tuple(min_index))
    Maximum $(maximum(float_im))"
)

for band ∈ eachindex(float_im[1,1,:])
    findall(float_im[:,:,band].>0.05)
end

guidict = imshow(float_im)
#idx = annotate!(guidict,AnnotationPoint())

p1 = histogram(vec(std_im),alpha=0.5)
histogram!(vec(float_im[:,:,10]),alpha=0.5)
display(p1)