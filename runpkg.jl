@time begin
    using ClassifySpectral
    using Plots
    using JLD
    
    #img = ImageUtils.singletif("C:/Data/rfl_cropped/m3t20090418t020644.tif","im_data1")
    #ImageUtils.labelλ(img,"C:/Data/m3t20090418t020644_v01_rfl.img.vrt")

    img = load("Data/im_data1.jld")["data"]
    
    file = open("wvl_data.txt","r")
    λvector = parse.(Float64,readlines(file))
    close(file)
    
    λ₁ = 1000.0
    λ₂ = 2000.0
    
    λ₁_index = ImageUtils.findλ(λ₁,λvector)[1]
    λ₂_index = ImageUtils.findλ(λ₂,λvector)[1]
    
    rfl1 = vec(img[:,:,λ₁_index])
    rfl2 = vec(img[:,:,λ₂_index])
    
    X = 27
    Y = 54

    smoothed_im,smoothed_λvector = ClassifySpectral.ImageSmoothing.movingavg(img,λvector,9)

    println(size(smoothed_im),size(smoothed_λvector))

    plot(λvector,img[X,Y,:],label="Raw")
    plot!(smoothed_λvector,smoothed_im[X,Y,:],label="Smooth")

    # println(smoothed_im[X,Y,:])

    #plot(rfl1[1:10000],rfl2[1:10000],seriestype=:scatter,label="Reflectance Data")

    end #time end