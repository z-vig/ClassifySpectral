using GLMakie
using PolygonOps

f = Figure()
ax = Axis(f[1,1])

plotted_data = hcat(randn(10000),randn(10000))
scatter!(ax,plotted_data)

mutable struct MyInteraction
    allow_left_click::Bool
    allow_right_click::Bool
end

function Makie.process_interaction(interaction::MyInteraction, event::MouseEvent, axis)
    if interaction.allow_left_click && event.type === MouseEventTypes.leftclick
        println("Left click in correct mode")
    end
    if interaction.allow_right_click && event.type === MouseEventTypes.rightclick
        println("Right click in correct mode")
    end
end

slist = []
coordlist::Vector{Tuple{Float64,Float64}} = []
function Makie.process_interaction(interaction::MyInteraction, event::KeysEvent, axis)
    interaction.allow_left_click = Keyboard.p in event.keys
    interaction.allow_right_click = Keyboard.r in event.keys
    if all([i in event.keys for i in [Keyboard.q,Keyboard.left_shift]])
        mp = mouseposition(ax)
        xpos = mp[1]
        ypos = mp[2]
        s = scatter!(ax,xpos,ypos,color=:Red)
        push!(slist,s)
        push!(coordlist,(xpos,ypos))
    end
end

f[2, 1] = buttongrid = GridLayout(tellwidth = false)


poly_list = []

b2 = Button(f,label="Plot Selection")
b = Button(f,label="Clear Selection")
buttongrid[1,1:2] = [b,b2]

on(b.clicks) do x
    for s in slist
        delete!(ax,s)
    end
    for p in poly_list
        delete!(ax,p)
    end


    global slist = []
    global poly_list = []
    global coordlist = []
end

on(b2.clicks) do x
    for s in slist
        s.color = :transparent
    end

    function run_inpolygon(pt)
        polyg = [[first(i),last(i)] for i in coordlist]
        push!(polyg,polyg[1])
        return inpolygon(pt,polyg)
    end
    min_x = minimum(plotted_data[:,1])
    max_x = maximum(plotted_data[:,2])
    inside_test = run_inpolygon.(formatted_data)
    println(size(inside_test))
    p = poly!(ax,coordlist,color=:green,strokewidth=1)
    push!(poly_list,p)
end

register_interaction!(ax, :left_and_right, MyInteraction(false, false))

f