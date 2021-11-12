using Unitful
using UnitfulAtomic
using PeriodicTable
using StaticArrays
import Base.position

export AbstractSystem
export BoundaryCondition, DirichletZero, Periodic
export bounding_box,
    species,
    position,
    velocity,
    boundary_conditions,
    is_periodic
export n_dimensions

velocity(p)::Union{Unitful.Velocity,Missing} = missing
position(p)::Unitful.Length = error("Implement me")
species(p) = error("Implement me")

#
# Identifier for boundary conditions per dimension
#
abstract type BoundaryCondition end
struct DirichletZero <: BoundaryCondition end  # Dirichlet zero boundary (i.e. molecular context)
struct Periodic <: BoundaryCondition end  # Periodic BCs


#
# The system type
#     Again readonly.
#

abstract type AbstractSystem{D,S} end
(bounding_box(::AbstractSystem{D})::SVector{D,SVector{D,<:Unitful.Length}}) where {D} =
    error("Implement me")
(boundary_conditions(::AbstractSystem{D})::SVector{D,BoundaryCondition}) where {D} =
    error("Implement me")

is_periodic(sys::AbstractSystem) =
    [isa(bc, Periodic) for bc in boundary_conditions(sys)]

# Note: Can't use ndims, because that is ndims(sys) == 1 (because of indexing interface)
n_dimensions(::AbstractSystem{D}) where {D} = D

# indexing and iteration interface
Base.getindex(::AbstractSystem, ::Int) = error("Implement me")
Base.length(::AbstractSystem) = error("Implement me")
Base.size(s::AbstractSystem) = (length(s),)
Base.setindex!(::AbstractSystem, ::Int) = error("AbstractSystem objects are not mutable.")
Base.firstindex(::AbstractSystem) = 1
Base.lastindex(s::AbstractSystem) = length(s)
# default to 1D indexing
Base.iterate(S::AbstractSystem, state=firstindex(S)) = (firstindex(S) <= state <= length(S)) ? (@inbounds S[state], state+1) : nothing

# TODO Support similar, push, ...

# Some implementations might prefer to store data in the System as a flat list and
# expose Atoms as a view. Therefore these functions are needed. Of course this code
# should be autogenerated later on ...
position(sys::AbstractSystem) = position.(sys)    # in Cartesian coordinates!
velocity(sys::AbstractSystem) = velocity.(sys)    # in Cartesian coordinates!
species(sys::AbstractSystem) = species.(sys)

# Just to make testing a little easier for now
function Base.show(io::IO, mime::MIME"text/plain", sys::AbstractSystem)
    println(io, "$(string(nameof(typeof(sys)))):")
    println(io, "    BCs:        ", boundary_conditions(sys))
    println(io, "    Box:        ", bounding_box(sys))
    println(io, "    Particles:  ")
    for particle in sys
        print("        ")
        Base.show(io, mime, particle)
        println(io)
    end
end
