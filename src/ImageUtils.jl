#LoadImages.jl
module ImageUtils

using Images
using Gumbo
using AbstractTrees
using JLD

function singletif(impath::String,imname::String)
    img = load(impath)
    img = permutedims(img,(3,1,2))
    img = Float64.(img)
    good_indices = findall(x->x==1,img[20,20,:].>-999);
    img = img[:,:,good_indices]
    save("$imname.jld","data",img)
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


end #module LoadImages