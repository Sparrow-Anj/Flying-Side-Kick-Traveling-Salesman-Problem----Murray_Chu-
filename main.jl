include("src/data_loader.jl")
include("src/model.jl")
include("src/plotter.jl")

data = LOAD_DATA()

city = BuildRandomCity(data,20)
SetTruckInformation(data, city, 65.0)
SetUvInformation(data, city, 113.0, 50.0,[2,5,8,12,13,15,17,19])
SetServiceInformation(data, 1.25, 1.25)

(model, x_i_j, y_i_j_k)  = CreateModel(data)

optimize!(model)

optimized_value = objective_value(model)

PlotCity(data)
PlotRoute(data)


