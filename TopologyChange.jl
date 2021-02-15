#
#  TopologyChange.jl
#  VertexModelJL
#
#  Created by Christopher Revell on 01/02/2021.
#
#
#

module TopologyChange

# Julia packages
using LinearAlgebra

# Local modules


@inline @views function topologyChange!(A, Ā, Aᵀ, Āᵀ, B, B̄, Bᵀ, B̄ᵀ, C, cellEdgeCount, boundaryVertices, cellOnes)

    Ā .= abs.(A)    # All -1 components converted to +1 (Adjacency matrix - vertices to edges)
    B̄ .= abs.(B)    # All -1 components converted to +1 (Adjacency matrix - cells to edges)
    C .= 0.5*B̄*Ā  # C adjacency matrix. Rows => cells; Columns => vertices

    transpose!(Aᵀ,A)
    Āᵀ .= abs.(Aᵀ)
    transpose!(Bᵀ,B)
    B̄ᵀ .= abs.(Bᵀ)

    cellEdgeCount    .= sum(B̄,dims=2)             # Number of edges around each cell found by summing columns of B̄
    boundaryVertices .= 0.5*(Āᵀ*(Bᵀ*cellOnes).^2) # Find the vertices at the boundary

    return nothing

end

export topologyChange!

end