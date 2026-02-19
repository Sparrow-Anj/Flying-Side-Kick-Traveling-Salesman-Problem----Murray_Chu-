include("src/data_loader.jl")
include("src/model.jl")
include("src/plotter.jl")

data = LOAD_DATA()

city = BuildRandomCity(data,15)
SetTruckInformation(data, city, 75.0)
SetUvInformation(data, city, 113.0, 50.0, [2,5,6,8,12,7,13,14])
SetServiceInformation(data, 5.0, 5.0)

(model, x_i_j, y_i_j_k)  = CreateModel(data)

optimize!(model)

optimized_value = objective_value(model)

PlotCity(data)
PlotRoute(data)


