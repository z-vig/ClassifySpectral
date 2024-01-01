#LoadImages.jl
module ImageUtils

using Images
using Gumbo
using AbstractTrees
using JLD2
using HDF5
using ProgressBars
using GLMakie
using StatsBase

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

function tifdir2hdf5(srcdir::String,dstdir::String)
    f_list = readdir(srcdir,join=true)
    stamp_ids = [i[1:end-4] for i ∈ readdir(srcdir,join=false)]
    iter = ProgressBar(1:length(f_list))

    h5file = h5open("$(dstdir)1.hdf5","w")

    for i ∈ iter
        tif = load(f_list[i])
        tif = permutedims(tif,(1,3,2))
        tif = convert(Array{Float32},tif)
        println(iter,typeof(tif))
        h5file[stamp_ids[i]] = tif
    end

    close(h5file)
end

function build_specgui(arr::Array{Float32,3},wvl_vals::Vector{Float64})
    im = arr[:,:,1]

    f = Figure(size=(1000,450))
    ax1 = GLMakie.Axis(f[1,1])
    ax1.title = "Gruithuisen Gamma"

    ax2 = GLMakie.Axis(f[1,2])

    ax3 = GLMakie.Axis(f[1,3])
    
    histdata = vec(im)

    sl_exp = IntervalSlider(f[2,2],range=range(minimum(histdata),maximum(histdata),100),startvalues=(percentile(histdata,1),percentile(histdata,99)))

    imstretch = lift(sl_exp.interval) do inter
        inter
    end

   
    bin_width = 2*iqr(histdata)/(length(histdata))^(1/3)
    bin_list = minimum(histdata):bin_width:maximum(histdata)
    bin_avg = [(bin_list[i]+bin_list[i+1])/2 for i ∈ eachindex(bin_list[1:end-1])]
    
    clist = lift(sl_exp.interval) do inter
        map(bin_avg) do val
            inter[1] < val < inter[2]
        end
    end

    hist!(ax2,histdata,bins=bin_list,color=clist,colormap=[:transparent,:red],strokewidth=0.1)
    im = image!(ax1,im,colorrange=imstretch)

    register_interaction!(ax1,:get_spectra) do event::MouseEvent,axis
        if event.type==MouseEventTypes.leftclick
            xpos = Int(round(event.data[1]))
            ypos = Int(round(event.data[2]))
            println("X:$xpos, Y:$ypos")
            lines!(ax3,wvl_vals,arr[xpos,ypos,:])
        end
    end

    butt = Button(f[2,3],label="Reset",tellwidth=false)
    on(butt.clicks) do click
        empty!(ax3)
    end
    f
end

end #module LoadImages