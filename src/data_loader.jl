using Distances 
using Random


mutable struct LOAD_DATA
    network::Array{AbstractFloat,2}  
    coordinates::Array{AbstractFloat,2}
    customer::Integer
    depot_begin::Integer 
    depot_end::Integer 
    ϵ:: AbstractFloat
    t_speed::  AbstractFloat 
    uv_speed:: AbstractFloat  
    uv_eligible_node::Vector
    truck_travel_time::Array{AbstractFloat,2} 
    uv_travel_time_3d_coordinates::Array{AbstractFloat,3} 
    uv_travel_time_2d_coordinates::Array{AbstractFloat,2} 
    s_l:: AbstractFloat 
    s_r:: AbstractFloat 

    function LOAD_DATA() 
        new()
    end
end 


function BuildRandomCity(data::LOAD_DATA, nodes::Integer)


    dimension = nodes + 2  
    coordinates::Array{AbstractFloat,2} = rand(1:500,dimension,2)
    city_graph::Array{AbstractFloat,2} = zeros(dimension,dimension) 

    coordinates[dimension,1] = coordinates[1,1]
    coordinates[dimension,2] = coordinates[1,2]

    for i in 1:dimension
        for j = 1:dimension
            city_graph[i,j] = euclidean([coordinates[i,1],coordinates[i,2]],[coordinates[j,1],coordinates[j,2]])
        end
    end

    data.customer = nodes 
    data.depot_begin = 1
    data.depot_end = nodes + 2 

    data.coordinates = coordinates
    data.network = city_graph

    return city_graph
end


function BuildTruckTravelTime(data::LOAD_DATA,network::Array{AbstractFloat,2}, speed::AbstractFloat)
    
    rows,cols = size(network)
    truck_travel_time::Array{AbstractFloat,2} = zeros(rows,cols)

    for i in 1:rows
        for j in 1:cols
            truck_travel_time[i,j] = network[i,j] / speed
        end
    end
    
    data.truck_travel_time = truck_travel_time

    return nothing 
 end


function BuildUvTravelTime3DCoordinates(data::LOAD_DATA, network::Array{AbstractFloat,2}, speed::AbstractFloat, total_endurance:: AbstractFloat, eligible_node::Vector)
        row,col = size(network)
        page = row
        uv_travel_time::Array{AbstractFloat,3} = fill(0.0,row,col,page)

        for i in 1 : row 
            for j in 1 : col 
                for k in 1 : page
                    if(j in eligible_node)
                        drone_endurance = (network[i,j] + network[j,k]) / speed
                        if(drone_endurance <= total_endurance)
                            uv_travel_time[i,j,k] = drone_endurance
                        end
                    end 
                end
            end
        end 

    data.uv_travel_time_3d_coordinates = uv_travel_time   

    return nothing                 
 end


function BuildUvTravelTime2DCoordinates(data::LOAD_DATA, network::Array{AbstractFloat,2}, speed::AbstractFloat, total_endurance:: AbstractFloat, eligible_node::Vector)
    
        row,col = size(network)

        uv_travel_time::Array{AbstractFloat,2} = fill(0.0,row,col)

        for i in 1 : row 
            for j in 1 : col 
                    if(j in eligible_node)
                        drone_endurance = network[i,j] / speed
                        if(drone_endurance <= total_endurance)
                            uv_travel_time[i,j] = drone_endurance
                        end
                    end 
            end
        end 

    data.uv_travel_time_2d_coordinates = uv_travel_time 

    return nothing
end

function SetTruckInformation(data::LOAD_DATA, network::Array{AbstractFloat,2}, speed::AbstractFloat)
    
    data.t_speed = speed

    BuildTruckTravelTime(data,network,speed)

    return nothing
end

function SetUvInformation(data::LOAD_DATA, network::Array{AbstractFloat,2}, speed::AbstractFloat, endurance::AbstractFloat, eligible_node::Vector)

    data.uv_speed = speed
    data.ϵ = endurance
    data.uv_eligible_node = eligible_node

    BuildUvTravelTime2DCoordinates(data, network, speed, endurance, eligible_node)
    BuildUvTravelTime3DCoordinates(data, network, speed, endurance, eligible_node)

    return nothing 
end

function SetServiceInformation(data::LOAD_DATA, launchtime::AbstractFloat, recovertime::AbstractFloat)

    data.s_l = launchtime
    data.s_r = recovertime 

    return nothing 
end