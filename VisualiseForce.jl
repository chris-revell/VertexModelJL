#
#  VisualiseForce.jl
#  VertexModelJL
#
#  Created by Christopher Revell on 21/03/2021.
#
#
#

module VisualiseForce

# Julia packages
using Plots
using Printf
using LinearAlgebra
using ColorSchemes

# Local modules

@inline @views function visualiseForce(A,Ā,B̄,R,C,F,outputCount,folderName,ϵ,nVerts)

   # Create plot canvas
   plot(xlims=(-0.2,0.2),ylims=(-0.3,0.3),aspect_ratio=:equal,color=:black,legend=:false,border=:none,markersize=4,markerstroke=:black,dpi=300,size=(1000,1000))

   for i=1:nVerts
      x=findall(x->x!=0,C[:,i])
      AA = R[i,:]./5.0
      BB = AA .+ ϵ*F[i,x[1],:]
      length(x) > 1 ? CC = BB .+ ϵ*F[i,x[2],:] : nothing
      length(x) > 2 ? DD = CC .+ ϵ*F[i,x[3],:] : nothing
      plot!([AA[1],BB[1]],[AA[2],BB[2]],color=:red,linewidth=2) #,subplot=2
      length(x) > 1 ? plot!([BB[1],CC[1]],[BB[2],CC[2]],color=:blue,linewidth=2) : nothing #,subplot=2
      length(x) > 2 ? plot!([CC[1],DD[1]],[CC[2],DD[2]],color=:green,linewidth=2) : nothing #,subplot=2
   end

   savefig("output/$folderName/forceplot$(@sprintf("%03d",outputCount)).png")

end

export visualiseForce

end
