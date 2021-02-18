#
#  SpatialData.jl
#  VertexModelJL
#
#  Created by Christopher Revell on 09/02/2021.
#
#
# Function to calculate spatial data including tangents, lengths, midpoints, tensions etc from incidence and vertex position matrices.

module SpatialData

# Julia packages
using LinearAlgebra

@inline @views function spatialData!(A,Ā,B,B̄,C,R,nCells,nEdges,nVerts,cellPositions,cellEdgeCount,cellAreas,cellOrientedAreas,cellPerimeters,cellTensions,cellPressures,edgeLengths,edgeMidpoints,edgeTangents,edgeDots,gamma,preferredPerimeter)

    cellPositions  .= C*R./cellEdgeCount
    edgeTangents   .= A*R
    edgeLengths    .= sqrt.(sum(edgeTangents.^2,dims=2))
    edgeMidpoints  .= 0.5.*Ā*R
    cellPerimeters .= B̄*edgeLengths
    cellTensions   .= gamma.*(preferredPerimeter .- cellPerimeters)
    cellPressures  .= cellAreas .- 1.0

    # Calculate oriented cell areas
    fill!(cellOrientedAreas,0.0)
    for i=1:nCells
        for j=1:nEdges
            cellOrientedAreas[i,:,:] .+= B[i,j].*edgeTangents[j,:]*edgeMidpoints[j,:]'
        end
    end
    cellAreas .= cellOrientedAreas[:,1,2]

    # Find dot products of cell edge tangents and vector connecting neighbouring cell centres
    for i=1:nEdges
        x=findall(x->x>0.5,B̄[:,i])
        if size(x)[1] > 1 #Skip boundary edges that connect to only one cell
            edgeDots[i] = (normalize(cellPositions[x[2],:].-cellPositions[x[1],:]))⋅normalize(edgeTangents[i,:])
        end
    end

    return nothing

end

export spatialData!

end
