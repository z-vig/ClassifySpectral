#ImageUtils.jl
module ImageUtils

using Images
using Gumbo
using AbstractTrees
using JLD2
using HDF5
using ProgressBars
using GLMakie
using StatsBase
using PolygonOps

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

    h5file = h5open("$(dstdir).hdf5","w")

    for i ∈ iter
        tif = load(f_list[i])
        tif = permutedims(tif,(1,3,2))
        tif = convert(Array{Float32},tif)
        println(iter,typeof(tif))
        h5file[stamp_ids[i]] = tif
    end

    close(h5file)
end

function build_specgui(arr::Array{Float64,3},wvl_vals::Vector{Float64})
    im = arr[:,:,100]
    imcoords = vec([[x,y] for x in 1:size(im,1),y in 1:size(im,2)])
    imcoords = hcat([i[1] for i in imcoords],[i[2] for i in imcoords])

    f_image = Figure()
    ax_im = GLMakie.Axis(f_image[1,1])
    ax_im.title = "Reflectance Image"

    f = Figure(size=(750,450))

    ax1 = GLMakie.Axis(f[1,1])

    ax2 = GLMakie.Axis(f[1,2])
    
    histdata = vec(im)

    sl_exp = IntervalSlider(f[2,1],range=range(minimum(histdata),maximum(histdata),100),startvalues=(percentile(histdata,1),percentile(histdata,99)))

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

    hist!(ax1,histdata,bins=bin_list,color=clist,colormap=[:transparent,:red],strokewidth=0.1)
    im = image!(ax_im,im,colorrange=imstretch)

    pllist = []
    pslist = []
    num_spectra = 0
    register_interaction!(ax_im,:get_spectra) do event::MouseEvent,axis
        if event.type==MouseEventTypes.leftclick
            if num_spectra<10
                num_spectra += 1
            else
                num_spectra = 1
            end
            xpos = Int(round(event.data[1]))
            ypos = Int(round(event.data[2]))
            println("X:$xpos, Y:$ypos")
            pl = lines!(ax2,wvl_vals,arr[xpos,ypos,:],color=num_spectra,colormap=:tab10,colorrange=(1,10),linestyle=:dash)
            ps = scatter!(ax_im,xpos,ypos,color=num_spectra,colormap=:tab10,colorrange=(1,10),markersize=5)
    
            push!(pllist,pl)
            push!(pslist,ps)
        end
    end

    slist = []
    coordlist::Vector{Tuple{Float64,Float64}} = []
    register_interaction!(ax_im,:area_spectra) do event::KeysEvent, axis
        if all([i in event.keys for i in [Keyboard.q,Keyboard.left_shift]])
            mp = mouseposition(ax_im)
            xpos = mp[1]
            ypos = mp[2]
            s = scatter!(ax_im,xpos,ypos,color=:Red)
            push!(slist,s)
            push!(coordlist,(xpos,ypos))
        end
    end

    f_image[2, 1] = buttongrid = GridLayout(tellwidth = false)
    poly_list = []

    b_select = Button(f_image,label="Plot Selection")
    b_clear = Button(f_image,label="Clear Selection")
    buttongrid[1,1:2] = [b_select,b_clear]

    area_spectra_num = 0
    allist = []
    on(b_select.clicks) do x
        if area_spectra_num<10
            area_spectra_num += 1
        else
            area_spectra_num = 1
        end


        for s in slist
            s.color = :transparent
        end
        println(length(coordlist))
        p = poly!(ax_im,coordlist,strokewidth=1,color=area_spectra_num,colormap=:tab10,colorrange=(1,10),alpha=0.5)
        push!(poly_list,p)

        function run_inpolygon(pt)
            polyg = [[first(i),last(i)] for i in coordlist]
            push!(polyg,polyg[1])
            return inpolygon(pt,polyg)
        end
        
        formatted_coords = hcat([first(i) for i in coordlist],[last(i) for i in coordlist])
        min_x = minimum(formatted_coords[:,1])
        max_x = maximum(formatted_coords[:,1])
        min_y = minimum(formatted_coords[:,2])
        max_y = maximum(formatted_coords[:,2])

        formatted_boxdata = []
        for (x,y) in zip(imcoords[:,1],imcoords[:,2])
            if x>min_x && x<max_x && y>min_y && y<max_y
                push!(formatted_boxdata,[x,y])
            end
        end
        inside_test = run_inpolygon.(formatted_boxdata)

        selection = [(i[1],i[2]) for i in formatted_boxdata[inside_test.==1]]
        formatted_boxdata = []

        selected_spectra = zeros(length(selection),239)
        for i in eachindex(selection)
            selected_spectra[i,:] = arr[selection[i]...,:]
        end
        #println(mean(selected_spectra,dims=1))
        al = lines!(ax2,wvl_vals,vec(mean(selected_spectra,dims=1)),color=area_spectra_num,colormap=:tab10,colorrange=(1,10))
        
        push!(allist,al)
        coordlist = []
        
    end

    on(b_clear.clicks) do x
        for s in slist
            delete!(ax_im,s)
        end
        for p in poly_list
            delete!(ax_im,p)
        end
        for ps in pslist
            delete!(ax_im,ps)
        end
        for pl in pllist
            delete!(ax2,pl)
        end
        for al in allist
            delete!(ax2,al)
        end

        slist = []
        poly_list = []
        pslist = []
        pllist = []
        allist = []
        coordlist = []
    end
    
    butt = Button(f[2,2],label="Reset",tellwidth=false)
    on(butt.clicks) do click
        empty!(ax2)
    end
    display(GLMakie.Screen(),f_image)
    display(GLMakie.Screen(),f)
end

end #module ImageUtils