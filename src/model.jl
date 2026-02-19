using JuMP
using HiGHS

function CreateModel(data::LOAD_DATA)

 model = Model(HiGHS.Optimizer)

 set_time_limit_sec(model, 900.0) # Forcing the model to stop after 15 minutes 


 # Decision Variables 

 @variable(model,
   
 x_i_j[i in data.depot_begin : data.customer+1, j in 2 : data.depot_end; 

 i != j],

 lower_bound = 0.0,

 upper_bound = 1.0,

 binary = true)

 @variable(model,

 y_i_j_k[i in data.depot_begin : data.customer+1, j in 2 : data.customer + 1, k in 2 : data.depot_end; 

 (i != j) && (j in data.uv_eligible_node) && (k != i && k != j) && (data.uv_travel_time_3d_coordinates[i,j,k]<= data.ϵ)], 

 lower_bound = 0.0,


 upper_bound = 1.0,

 binary = true)


 # Auxiallary Decision variable 

 @variable(model, 

 p_i_j[i in data.depot_begin : data.customer+1, j in 2 : data.customer + 1; 

 i != j], 

 lower_bound = 0.0,

 upper_bound = 1.0, 

 binary = true)


 # Time variable for truck and uv 

 @variable(model, 

 t_i[data.depot_begin : data.depot_end] >=0)

 @variable(model, 

 tprime_i[data.depot_begin : data.depot_end] >=0)

 
 # Sub routine constraint variable 

 @variable(model, 1 <= u[2: data.depot_end] <= data.customer + 2)


 # Constraints 

 @constraint(model,

 [j in 2 : data.customer + 1],

 sum(x_i_j[i,j] 

 for i in data.depot_begin : data.customer+1 if (i != j)) +
 
 sum(y_i_j_k[i,j,k] 

 for i in data.depot_begin : data.customer + 1, k in 2 : data.depot_end 

 if (i!=j) && (k != i && k != j) && (data.uv_travel_time_3d_coordinates[i,j,k]<= data.ϵ) && (j in data.uv_eligible_node)) == 1)


 @constraint(model, 

 sum(x_i_j[1,j] for j in 2 : data.depot_end) == 1)

 @constraint(model, 

 sum(x_i_j[i,data.depot_end] for i in data.depot_begin : data.customer+1)==1)

 @constraint(model, 

 [i in 2:data.customer+1, j in 2:data.depot_end; 

 i != j],

 u[i] - u[j] + 1 <= (data.customer + 2) * (1 - x_i_j[i, j]))

 @constraint(model, 

 [j in 2 : data.customer + 1],

 sum(x_i_j[i,j] for i in data.depot_begin : data.customer + 1 

 if i != j) == 

 sum(x_i_j[j,k] for k in 2 : data.depot_end 

 if k != j))

 @constraint(model, 

 [i in data.depot_begin : data.customer + 1],

 sum(y_i_j_k[i,j,k] for j in 2 : data.customer + 1,  k in 2 : data.depot_end 

 if (i!=j) && (k!=i && k!=j) && (j in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[i,j,k]<= data.ϵ)) <= 1 )
 
 @constraint(model,

 [k in 2 : data.depot_end],

 sum(y_i_j_k[i,j,k]

 for i in data.depot_begin : data.customer + 1, j in 2 : data.customer + 1

 if (i!=j) && (k!=i && k!=j) && (j in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ)) <= 1 )


 @constraint(model, 
 
 [i in 2 : data.customer+1, j in 2 : data.customer + 1, k in 2 : data.depot_end; 

 (i != j) && (k!=i && k!=j) && (j in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[i,j,k]<= data.ϵ)],

 2*y_i_j_k[i,j,k] <= 

 sum(x_i_j[h,i] for h in data.depot_begin : data.customer+1 if h != i) + 

 sum(x_i_j[l,k] for l in 2 : data.customer+1 

 if l != k))

 @constraint(model, 

 [j in 2 : data.customer+1, k in 2 : data.depot_end;

 (k!=j) && (j in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[1,j,k]<= data.ϵ)],

 y_i_j_k[1,j,k] <= 

 sum(x_i_j[h,k] for h in data.depot_begin : data.customer+1 

 if h != k))

 @constraint(model, 

 [i in 2 : data.customer + 1 , k in 2 : data.depot_end; 

 i != k],

 u[k] - u[i]  >= 

 1 - (data.customer+2) *

 (1 - sum(y_i_j_k[i,j,k] for j in 2 : data.customer + 1 

 if (i != j) && (k != j) && (j in data.uv_eligible_node) && data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ)))

 
 # BIG M CALCULATION : IT DECIDES THE PRIORI 
 # SINCE FINDING THE LONGEST PATH IN A FULLY CONNECTED GRAPH IS AN NP-HARD PROBLEM. SO WE ARE MAKING A LOOSE UPPER BOUND 

 max_edge = maximum(data.truck_travel_time)

 M = (data.customer+2) * (max_edge) # CONSIDER A FULLY CONNECTED GRAPH WITH THE EQUAL MAX_EDGE BETWEEN ALL OF THEM 

 @constraint(model,

 [i in 2 : data.customer + 1],

 tprime_i[i] >= t_i[i] - M * (1 -

 sum(sum(y_i_j_k[i,j,k] for k in 2 : data.depot_end 

 if (k!=j && k!=i) && (j in data.uv_eligible_node) && data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ) 
    
 for j in 2 : data.customer + 1 

 if (i!=j))))

 @constraint(model,

 [i in 2 : data.customer + 1],

 tprime_i[i] <= t_i[i] + M * (1 -

 sum(sum(y_i_j_k[i,j,k] for k in 2 : data.depot_end 

 if (k!=j && k!=i) && (j in data.uv_eligible_node) && data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ) 
    
 for j in 2 : data.customer + 1 

 if (i!=j))))

 @constraint(model,

 [k in 2 : data.depot_end],

 tprime_i[k] >= t_i[k] - M * (1 -

 sum(sum(y_i_j_k[i,j,k] for j in 2 : data.customer + 1 

 if (i != data.depot_end) && (k!=j && k!=i) && (j in data.uv_eligible_node) && data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ) 
    
 for i in data.depot_end : data.customer + 1 

 if (i!=k))))
    
 @constraint(model,

 [k in 2 : data.depot_end],

 tprime_i[k] <= t_i[k] + M * (1 -

 sum(sum(y_i_j_k[i,j,k] for j in 2 : data.customer + 1 

 if (i != data.depot_end) && (k!=j && k!=i) && (j in data.uv_eligible_node) && data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ) 
    
 for i in data.depot_end : data.customer + 1 

 if (i!=k))))

 @constraint(model,

 [h in data.depot_begin : data.customer + 1, k in 2 : data.depot_end; (h!=k)],

 t_i[k] >= t_i[h] + data.truck_travel_time[h,k] + data.s_l * (

 sum(sum(y_i_j_k[k,l,m] for m in 2 : data.depot_end 

 if (k!=data.depot_end) && (m != l && m != k) && (l in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[k,l,m] <= data.ϵ))

 for l in 2 : data.customer + 1 

 if(l != k ))) + 

 data.s_r * (

 sum(sum(y_i_j_k[i,j,k] for j in 2 : data.customer + 1 

 if (i!=j && k != j) && (j in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ))

 for i in data.depot_begin : data.customer + 1 

 if(i != k ))) - 

 M * (1 - x_i_j[h,k]))

 @constraint(model,

 [j in data.uv_eligible_node, i in data.depot_begin : data.customer + 1;
     
 (i != j)],

 tprime_i[j] >= tprime_i[i] + data.uv_travel_time_2d_coordinates[i,j] - M * (1 - 

 sum(y_i_j_k[i,j,k] for k in 2 : data.depot_end

 if(k != j && k != i) && (data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ))))

 @constraint(model ,

 [j in data.uv_eligible_node, k in 2 : data.depot_end;
    
 (k != j)],

 tprime_i[k] >= tprime_i[j] + data.uv_travel_time_2d_coordinates[j,k] + data.s_r - M * (1 - 

 sum(y_i_j_k[i,j,k] for i in data.depot_begin : data.customer + 1

 if(i!=j && k != i) && (data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ))))

 @constraint(model, 

 [k in 2 : data.depot_end, j in 2 : data.customer+1, i in data.depot_begin : data.customer + 1; 

 (k!=j) && (i != j) && (k != i) && (j in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ)],

 tprime_i[k] - (tprime_i[j] - data.uv_travel_time_2d_coordinates[i,j]) <= 

 data.ϵ + M * (1 - y_i_j_k[i,j,k]))

 @constraint(model,

 [i in data.depot_begin : data.customer+1, k in 2 : data.depot_end, l in 2 : data.customer+1;

 (k!=i) && (l!=i) && (l!=k)],

 tprime_i[l] >= tprime_i[k] - M * ( 3 - 

 sum(y_i_j_k[i,j,k] for j in 2 : data.customer + 1 if (j != l) && (i != j) && (j != k) && (j in data.uv_eligible_node) && 

 (data.uv_travel_time_3d_coordinates[i,j,k] <= data.ϵ)) - 

 (sum(sum(y_i_j_k[l,m,n] for n in 2 : data.depot_end if (n != i) && (n != k) && 

 (n != m) && (n != l) && (m in data.uv_eligible_node) && (data.uv_travel_time_3d_coordinates[l,m,n] <= data.ϵ))

 for m in 2 : data.customer+1 if (m != i) && (m != k) && (m != l))) - 
    
 p_i_j[i,l]))

 @constraint(model, 

 [i in 2 : data.customer+1, j in 2 : data.customer+1; 

 i != j],

 u[i] - u[j] >= 1 - (data.customer+2)*p_i_j[i,j])

 @constraint(model, 

 [i in 2 : data.customer+1, j in 2 : data.customer+1; 

 i != j],

 u[i] - u[j] <= -1 + (data.customer+2)*(1 - p_i_j[i,j]))

 @constraint(model, 

 [i in 2 : data.customer+1, j in 2 : data.customer+1; 

 i != j],

 p_i_j[i,j] + p_i_j[j,i] == 1)


 @constraint(model,

 t_i[1] == 0 )

 @constraint(model,

 tprime_i[1] == 0)
 
 @constraint(model,

 [j in 2 : data.customer + 1],

 p_i_j[1,j] == 1)

 @objective(model,

 Min,

 t_i[data.depot_end])

  return (model,x_i_j,y_i_j_k)
end
