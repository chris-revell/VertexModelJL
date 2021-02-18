#
#  Simulate.jl
#  VertexModelJL
#
#  Created by Christopher Revell on 31/01/2021.
#
#

module Simulate

# Julia packages
using LinearAlgebra
using DelimitedFiles

# Local modules
using TopologyChange
using CreateRunDirectory
using SpatialData
using CalculateForce
using SingleHexagon
using Visualise

@inline @views function simulate(initialSystem)

    # Parameters
    gamma        = 0.172                 # Parameters in energy relaxation. Hard wired from data.    (0.05#0.172 ??)
    lamda        = -0.259                # Parameters in energy relaxation. Hard wired from data.    (-0.1#-0.259 ??)
    tStar        = 20.0                  # Relaxation rate. Approx from Sarah's data.
    realTimetMax = 200.0                 # Real time maximum system run time /seconds
    dt           = 1.0                   # Non dimensionalised time step
    ϵ            = [0.0 1.0
                   -1.0 0.0]       # Antisymmetric rotation matrix

    # Derived parameters
    # NB Preferred area = 1.0 by default
    tMax               = realTimetMax/tStar    # Non dimensionalised maximum system run time
    outputInterval     = tMax/100.0            # Time interval for storing system data (non dimensionalised)
    nonDimCellCycle    = meanCellCycle/tStar   # Non dimensionalised cell cycle time? (Parameter used in cell division time)
    preferredPerimeter = -lamda/(2*gamma)      # Cell preferred perimeter

    # Import system matrices from file
    A = readdlm("input/$(initialSystem)_A.txt",' ',Float64,'\n') # Incidence matrix. Rows => edges; columns => vertices.
    B = readdlm("input/$(initialSystem)_B.txt",' ',Float64,'\n') # Incidence matrix. Rows => cells; columns => edges. Values +/-1 for orientation
    R = readdlm("input/$(initialSystem)_R.txt",' ',Float64,'\n') # Coordinates of vertices

    R[:,1].*=3.0
    # Infer system information from matrices
    nCells            = size(B)[1]                    # Number of cells
    nEdges            = size(A)[1]                    # Number of edges
    nVerts            = size(A)[2]                    # Number of vertices
    # Preallocate system arrays
    Aᵀ                = zeros(nVerts,nEdges)  # Transpose of incidence matrix A
    Ā                 = zeros(nEdges,nVerts)  # Undirected adjacency matrix from absolute values of incidence matrix A
    Āᵀ                = zeros(nVerts,nEdges)  # Undirected adjacency matrix from absolute values of transpose of incidence matrix Aᵀ
    Bᵀ                = zeros(nEdges,nCells)  # Transpose of incidence matrix B
    B̄                 = zeros(nCells,nEdges)  # Undirected adjacency matrix from absolute values of incidence matrix B
    B̄ᵀ                = zeros(nEdges,nCells)  # Undirected adjacency matrix from absolute values of transpose of incidence matrix Bᵀ
    C                 = zeros(nCells,nVerts)  # C adjacency matrix. Rows => cells; Columns => vertices. = 0.5*B̄*Ā
    tempR             = zeros(nVerts,2)       # Array to store temporary positions in Runge-Kutta integration
    ΔR                = zeros(nVerts,2)       # Array to store change in R during Runge-Kutta integration
    cellEdgeCount     = zeros(Int64,nCells,1) # 1D matrix containing number of edges around each cell, found by summing columns of B̄
    boundaryVertices  = zeros(Int64,nVerts,1) # 1D matrix containing labels of vertices at system boundary
    cellPositions     = zeros(nCells,2)       # 2D matrix of cell centre positions
    cellPerimeters    = zeros(nCells,1)       # 1D matrix of scalar cell perimeter lengths
    cellOrientedAreas = zeros(nCells,2,2)     # 3D array of oriented cell areas. Each row is a 2x2 antisymmetric matrix of the form [0 A / -A 0] where A is the scalar cell area
    cellAreas         = zeros(nCells,1)       # 1D matrix of scalar cell areas
    cellTensions      = zeros(nCells,1)       # 1D matrix of scalar cell tensions
    cellPressures     = zeros(nCells,1)       # 1D matrix of scalar cell pressures
    edgeLengths       = zeros(nEdges,1)       # 1D matrix of scalar edge lengths
    edgeTangents      = zeros(nEdges,2)       # 2D matrix of tangent vectors for each edge (magnitude = edge length)
    edgeMidpoints     = zeros(nEdges,2)       # 2D matrix of position coordinates for each edge midpoint
    cellOnes          = ones(nCells)          # Useful array for reusing in calculations
    F                 = zeros(nVerts,nCells,2)#

    edgeDots = zeros(nEdges)

    # Create output directory in which to store results and parameters
    folderName = createRunDirectory(nCells,nEdges,nVerts,gamma,lamda,tStar,realTimetMax,tMax,dt,outputInterval,preferredPerimeter,A,B,R)

    # Initialise time and output count
    t = 0.00000000001
    outputCount = 0
    topologyChange!(A,Ā,Aᵀ,Āᵀ,B,B̄,Bᵀ,B̄ᵀ,C,cellEdgeCount,boundaryVertices,cellOnes)

    while t<tMax

        # Runge-Kutta integration
        spatialData!(A,Ā,B,B̄,C,R,nCells,nEdges,nVerts,cellPositions,cellEdgeCount,cellAreas,cellOrientedAreas,cellPerimeters,cellTensions,cellPressures,edgeLengths,edgeMidpoints,edgeTangents,edgeDots,gamma,preferredPerimeter)
        calculateForce!(F,A,Ā,B,B̄,cellPressures,cellTensions,edgeTangents,edgeLengths,nVerts,nCells,nEdges,ϵ)
        ΔR .= sum(F,dims=2)[:,1,:].*dt/6.0

        tempR .= R .+ sum(F,dims=2)[:,1,:].*dt/2.0
        spatialData!(A,Ā,B,B̄,C,tempR,nCells,nEdges,nVerts,cellPositions,cellEdgeCount,cellAreas,cellOrientedAreas,cellPerimeters,cellTensions,cellPressures,edgeLengths,edgeMidpoints,edgeTangents,edgeDots,gamma,preferredPerimeter)
        calculateForce!(F,A,Ā,B,B̄,cellPressures,cellTensions,edgeTangents,edgeLengths,nVerts,nCells,nEdges,ϵ)
        ΔR .+= sum(F,dims=2)[:,1,:].*dt/3.0

        tempR .= R .+ sum(F,dims=2)[:,1,:].*dt/2.0
        spatialData!(A,Ā,B,B̄,C,tempR,nCells,nEdges,nVerts,cellPositions,cellEdgeCount,cellAreas,cellOrientedAreas,cellPerimeters,cellTensions,cellPressures,edgeLengths,edgeMidpoints,edgeTangents,edgeDots,gamma,preferredPerimeter)
        calculateForce!(F,A,Ā,B,B̄,cellPressures,cellTensions,edgeTangents,edgeLengths,nVerts,nCells,nEdges,ϵ)
        ΔR .+= sum(F,dims=2)[:,1,:].*dt/3.0

        tempR .= R .+ sum(F,dims=2)[:,1,:].*dt
        spatialData!(A,Ā,B,B̄,C,tempR,nCells,nEdges,nVerts,cellPositions,cellEdgeCount,cellAreas,cellOrientedAreas,cellPerimeters,cellTensions,cellPressures,edgeLengths,edgeMidpoints,edgeTangents,edgeDots,gamma,preferredPerimeter)
        calculateForce!(F,A,Ā,B,B̄,cellPressures,cellTensions,edgeTangents,edgeLengths,nVerts,nCells,nEdges,ϵ)
        ΔR .+= sum(F,dims=2)[:,1,:].*dt/6.0

        R .+= ΔR
        t +=dt

        if t%outputInterval<dt
            visualise(Ā,B̄,R,C,F,cellPositions,edgeMidpoints,nEdges,nVerts,nCells,outputCount,folderName,ϵ,edgeDots)
            outputCount+=1
            println("$outputCount/100")
        end

    end

    run(`convert -delay 5 -loop 0 output/$folderName/plot"*".png output/$folderName/animated.gif`)

end

export simulate

end
