#LoadImages.jl
module ImageUtils

using Images
using Gumbo
using AbstractTrees
using JLD2
using ProgressMeter

function dataloadin(folder_path::String)
    imgpaths = readdir(folder_path,join=true)
    imgnames = [i[1:end-4] for i ∈ readdir(folder_path)]
    all_data::Array{Array{Float32,3}} = []
    p = Progress(length(imgpaths);desc="Loading TIFF Data...")
    for i ∈ eachindex(imgpaths)
        push!(all_data,load(imgpaths[i])["data"])
        next!(p)
    end
    return all_data[2]
end

function savejld2(folder_path)
    imgpaths = readdir(folder_path,join=true)
    imgnames = [i[4:end-16] for i ∈ readdir(folder_path)]

    p = Progress(length(imgpaths);desc="Saving TIFF Data as JLD2")
    for i ∈ eachindex(imgpaths)
        img = ImageUtils.singletif(imgpaths[i],imgnames[i])
        next!(p)
    end
end

function singletif(impath::String,imname::String)
    img = load(impath)
    img = permutedims(img,(3,1,2))
    img = Float32.(img)
    good_indices = findall(x->x==1,img[10,10,:].>-999);
    img = img[:,:,good_indices]
    save("D:/ice_data_sample/obs_cropped_jld2/$imname.jld2","data",img)
    return img
end

function labelλ(img_array::Array{Float64},vrt_path::String)

    good_indices = findall(x->x==1,img_array[20,20,:].>-999);
    doc = parsehtml(read(vrt_path,String));

    data = collect(PreOrderDFS(doc.root));
    index_list = [i+6 for i in 1:15:15*256]
    wvl_list = [parse(Float64,replace(data[i][1].text," nm"=>"")) for i in index_list]
    wvl_list=wvl_list[good_indices]

    file = open("./wvl_data.txt","w")
    for λ in wvl_list
        write(file,"$λ\n")
    end
    close(file)
end

function findλ(target_val::Float64,arrayin::Vector{Float64})
    min_diff = 9999
    min_index::Int = 0
    for i in eachindex(arrayin)
        if abs(arrayin[i]-target_val)<min_diff
            min_diff::Float32 = abs(arrayin[i]-target_val)
            min_index = i
        end
    end
return min_index, arrayin[min_index]
end

function getλ(txtpath::String)
    file = open(txtpath,"r")
    λvector = parse.(Float64,readlines(file))
    close(file)
    return λvector
end

end #module LoadImages