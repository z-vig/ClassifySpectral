@time begin
using Plots
using Images,ImageView
using Statistics
using ClassifySpectral
using TiffImages

ice_data_path = "Z:/D/Data/Ice_Pipeline_Out_9-7-23/rfl_smooth/"
smooth_files = readdir(ice_data_path,join=true)

smooth_files[1]

end #time
