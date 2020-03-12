module CnvAnnotator

using RemoteFiles
using SQLite
using DBInterface
using GZip
using DataFrames
using ProgressMeter

include("loaddata.jl")
include("query.jl")

end # module
