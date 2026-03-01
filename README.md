# FSTSP Solver in Julia

[![Julia](https://img.shields.io/badge/julia-v1.10+-9558B2?logo=julia)](https://julialang.org)
[![JuMP](https://img.shields.io/badge/JuMP-v1.15-4053D2)](https://jump.dev)

An exact **Branch-and-Cut** implementation for the **Flying Sidekick Traveling Salesman Problem (FSTSP)**. This solver optimizes synchronized delivery routes where a truck and a drone work in tandem to minimize total service time.

##  Overview
This project implements the mathematical model originally proposed by **Murray and Chu (2015)**. It includes critical corrections to the drone launch and recovery index sets and features a high-resolution dark-mode visualization route image.

## Optimal Route Visualization
![Optimal Route](Optimal%20Route%20Example.png)
*Figure: Optimized 5-node route showing truck paths (cyan) and drone sorties (lime/magenta).*

## Objectives

1. To get a clear understading of Vehicle Routing Problems. 
2. To get a clear understanding of UAV/Truck tandem Vehicle Routing Problem. 
3. To get a clear understanding of Mixed Integer Linear Programming.
4. To get a familiarity with Juila and juMP software tools.

## Features
- Exact Branch-and-Cut solver using JuMP
- HiGHS default solver; optional Gurobi for larger instances
- High-resolution dark-mode visualization of routes
- Example instances and scripts to reproduce figures

## Authors: 

Lead Developer: Sparrow-Anj 

Research Basis: Murray, C. C., & Chu, A. G. (2015). The flying sidekick traveling salesman problem.

---

##  Installation

### 1. Prerequisites
Ensure you have [Julia](https://julialang.org/downloads/) installed on your machine. For large-scale problems (30+ nodes), a Gurobi license is recommended, but the model runs on **HiGHS** by default.

### 2. Package Setup

## Quickstart (recommended)
```bash
git clone https://github.com/Sparrow-Anj/Flying-Side-Kick-Traveling-Salesman-Problem----Murray_Chu-.git
cd Flying-Side-Kick-Traveling-Salesman-Problem----Murray_Chu-
# instantiate project environment
julia --project=. -e 'using Pkg; Pkg.instantiate()'
# run default example
julia --project=. main.jl
