using Plots
using Measures

function PlotCity(data::LOAD_DATA)
 gr()

 x = [1:data.customer+2]
 y = [1:data.customer+2]
 z = vec(data.network)

 p = surface(x, y, z,

    color = :magma,             
    alpha = 1.0,                 
    
    colorbar = false,             
    
    linewidth = 4.0,              
    linecolor = :Ghostwhite,         
    
    title = "City Distance Graph",
    xlabel = "City A",
    ylabel = "City B",
    zlabel = "Distance Between Cities",

    background_color = :Black
)

 display(p)
 savefig(p,"City Graph Example.png")

   return nothing 
end


#  CURVING THE ARC 
function get_curve_points(x1, y1, x2, y2; offset_scale=0.15)
    mx, my = (x1 + x2) / 2, (y1 + y2) / 2
    dx, dy = x2 - x1, y2 - y1
    cx, cy = mx - offset_scale * dy, my + offset_scale * dx
    t = range(0, 1, length=30)
    curve_x = @. (1-t)^2 * x1 + 2*(1-t)*t * cx + t^2 * x2
    curve_y = @. (1-t)^2 * y1 + 2*(1-t)*t * cy + t^2 * y2
    return curve_x, curve_y
end

function PlotRoute(data::LOAD_DATA)
 gr()

 X = data.coordinates[:,1]
 Y = data.coordinates[:,2]
 N = length(X)

# Loosening the Graph 
 x_pad = (maximum(X) - minimum(X)) * 0.15
 y_pad = (maximum(Y) - minimum(Y)) * 0.15

 drone_served_indices = []
 for (i, j, k) in keys(y_i_j_k.data)
    if value(y_i_j_k[i, j, k]) > 0.5
        push!(drone_served_indices, j)
    end
 end

 p = plot(
    title  = "Flying Side Kick TSP Optimal Route",
    xlabel = "X Coordinate", ylabel = "Y Coordinate",
    
    xlims = (minimum(X) - x_pad, maximum(X) + x_pad), 
    ylims = (minimum(Y) - y_pad, maximum(Y) + y_pad),
    margin = 6mm,                 
    legend = :bottomright,           
    legendfontsize = 12,          
    guidefontsize = 14,           
    tickfontsize = 11,            
    titlefontsize = 16,           
    
    aspect_ratio = :equal,
    size = (1000, 1000),
    dpi = 700,                    
    fontfamily = "Computer Modern",
    framestyle = :semi,
    gridstyle = :dash,
    gridalpha = 0.15,
    
    background_color = :black,
    background_color_outside = :black,
    foreground_color_text = :white,
    foreground_color_grid = :gray,
    foreground_color_axis = :white,
    foreground_color_border = :white,
    legend_background_color = RGBA(0, 0, 0, 0.7), 
    legend_font_color = :white
 ) 

 # TRUCK ROUTE
 truck_legend = false # Checking whether truck has taken any route or not 
 for (i, j) in keys(x_i_j.data)
    if value(x_i_j[i, j]) > 0.5
        # Glow
        cx, cy = get_curve_points(X[i], Y[i], X[j], Y[j], offset_scale=0.15)
        plot!(cx,cy, linewidth=8, color=:cyan, alpha=0.2, label=nothing)
        # Core
        plot!(cx,cy, linewidth=2.5, color=:cyan, arrow=:arrow, 
            label=(truck_legend ? nothing : "Truck Path")
        )
       truck_legend = true
    end
 end

 # DRONE SORTIES 
 launch_legend = false # Confirming whether UV has taken any launch 
 recover_legend = false # Confirming whether UV has been Recovered 

 for (i, j, k) in keys(y_i_j_k.data)
    if value(y_i_j_k[i, j, k]) > 0.5
        # Launch Leg 
        cx, cy = get_curve_points(X[i], Y[i], X[j], Y[j], offset_scale=0.15)
        plot!(cx, cy, linewidth=8, color=:lime, alpha=0.2, label=nothing)
        plot!(cx, cy, linewidth=2.5, linestyle=:dash, color=:lime, arrow=:arrow, 
            label=(launch_legend ? nothing : "Drone Launch")
        )
        launch_legend = true

        #  Recovery Leg 
        cx2, cy2 = get_curve_points(X[j], Y[j], X[k], Y[k], offset_scale=0.15)
        plot!(cx2, cy2, linewidth=8, color=:magenta, alpha=0.2, label=nothing)
        plot!(cx2, cy2, linewidth=2.5, linestyle=:dash, color=:magenta, arrow=:arrow, 
            label=(recover_legend ? nothing : "Drone Recover")
        )
        recover_legend = true
    end
 end

 # MARKING THE CUSTOMER NODES SERVED BY TRUCK  
 truck_mask = [!(i in drone_served_indices) && i!=1 && i!=N for i in 1:N]
 scatter!(X[truck_mask], Y[truck_mask], marker=:pentagon, color=:black, ms=13, label=nothing)
 scatter!(X[truck_mask], Y[truck_mask], 
    marker = :pentagon, color = :dodgerblue, ms = 10, 
    series_annotations = text.((1:N)[truck_mask], 10, :white, :center), # Font size increased to 10
    markerstrokewidth = 1, markerstrokecolor = :white,
    label = "Truck Served Node"
 )

 #  MARKING THE CUSTOMER NODES SERVED BY DRONE 
 if !isempty(drone_served_indices)
    scatter!(X[drone_served_indices], Y[drone_served_indices], marker=:star8, color=:black, ms=15, label=nothing)
    scatter!(X[drone_served_indices], Y[drone_served_indices], 
        marker = :star8, color = :gold, ms = 12, 
        series_annotations = text.(drone_served_indices, 10, :black, :center),
        markerstrokewidth = 1, markerstrokecolor = :white,
        label = "Drone Served Node"
    ) 
 end

 # SETTING UP THE DEPOT 
 scatter!([X[1]], [Y[1]], marker=:hexagon, color=:black, ms=17, label=nothing)
 scatter!([X[1]], [Y[1]], 
    marker = :hexagon, color = :white, ms = 14, 
    series_annotations = text.("D", 11, :black, :center), # Font size increased to 11
    markerstrokewidth = 1, markerstrokecolor = :gray,
    label = "Depot" 
 )

 display(p)
 savefig(p,"Optimal Route Example.png")

   return nothing 
end
