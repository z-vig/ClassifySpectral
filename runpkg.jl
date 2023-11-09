@time begin
    using ClassifySpectral
    using Plots
    using JLD
    
    #img = ImageUtils.singletif("C:/Data/m3t20090418t020644_rfl.tif","im_data1")
    #ImageUtils.labelλ(img,"C:/Data/m3t20090418t020644_v01_rfl.img.vrt")

    img = load("im_data1.jld")["data"]
    
    file = open("wvl_data.txt","r")
    λvector = parse.(Float64,readlines(file))
    close(file)
    
    λ₁ = 1000.0
    λ₂ = 2000.0
    
    λ₁_index = ImageUtils.findλ(λ₁,λvector)[1]
    λ₂_index = ImageUtils.findλ(λ₂,λvector)[1]
    
    rfl1 = vec(img[:,:,λ₁_index])
    rfl2 = vec(img[:,:,λ₂_index])
    
    #plot(rfl1[1:10000],rfl2[1:10000],seriestype=:scatter,label="Reflectance Data")

    end #time end