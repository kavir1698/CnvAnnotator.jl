export return_variants

"Call db file if it exists, otherwise, create it. This could be modified to call the correct database given chromosome number."
function call_db(datadir, overwrite;chr=1)
  dbfile = joinpath(datadir, "snvdb.mysql")
  if isfile(dbfile)
    db = SQLite.DB(dbfile)
  else
    db = populate_db(datadir, overwrite, chr=chr)
  end
  return db
end

"""
    return_variants(from::Int, to::Int; kwargs)

Returns all the variants on Chr1 between `from` and `to`.

# kwargs

* tolerance::Int=0 also search as many bases as `tolerance` away from your query.
* chr::Int=1 currently only support chr 1. 
* overwrite::Bool=false force re-create database.
* only_phenotyped::Bool=false only return variants which have a phenotype
* datadir="./" where to save downloaded and database files.
"""
function return_variants(from::Int, to::Int; tolerance::Int=0, chr=1, overwrite=false, only_phenotyped=false, datadir="./")
  @assert to > from "to should be larger than from"

  db = call_db(datadir, overwrite, chr=chr)

  if only_phenotyped
    stmt = "SELECT * FROM tab WHERE (end >= $from - $tolerance AND start <= $to + $tolerance AND pathogenicity != 'not_reported') OR (outerEnd >= $from - $tolerance AND innerStart <= $to + $tolerance AND pathogenicity != 'not_reported')"
  else
    stmt = "SELECT * FROM tab WHERE (end >= $from - $tolerance AND start <= $to + $tolerance) OR (outerEnd >= $from - $tolerance AND innerStart <= $to + $tolerance)"
  end
  r = SQLite.DBInterface.execute(db, stmt) |> DataFrame

  if size(r, 1) > 0
    create_confidence_column!(r, from, to, tolerance)
    columns = [:ID, :CNV, :pathogenicity, :confidence, :start, :end, :outerStart, :innerStart, :innerEnd, :outerEnd, :originalID, :dataOrigin]
    return r[!, columns]
  else
    return r
  end
end

"Creates a column that describes confidence in results"
function create_confidence_column!(r::AbstractDataFrame, from, to, tolerance)
  nsamples = size(r, 1)
  # confidence = Array{String}(undef, nsamples)
  confidence = repeat(["Variant within query."], nsamples)

  # Find innermost range for variants whose some of inner/outer start/end is missing.
  leftinner, rightinner = return_inner_range(r, nsamples=nsamples)

  # Fill confidence array.
  if tolerance > 0
    closest_within_outer = full_or_partial_overlap.(from - tolerance, to + tolerance, view(r, :, :outerStart), view(r, :, :outerEnd))
    confidence[findall(x-> x==false, closest_within_outer)] .= "Tolerance partially within outer bounds of variation"

    closest_within_range = full_or_partial_overlap.(from - tolerance, to + tolerance, view(r, :, :start), view(r, :, :end))
    confidence[findall(x-> x==false, closest_within_range)] .= "Tolerance partially within bounds of variation"

    closest_within_innerRange = full_or_partial_overlap.(from - tolerance, to + tolerance, view(r, :, :innerStart), view(r, :, :innerEnd))
    confidence[findall(x-> x==false, closest_within_innerRange)] .= "Tolerance partially within inner bounds of variation"

    # Change those within range that do not have  inner/outer start/end to the most confident case.
    closest_within_innerRange2 = full_or_partial_overlap.(from - tolerance, to + tolerance, leftinner, rightinner)
    confidence[findall(x-> x==false, closest_within_innerRange2)] .= "Tolerance partially within inner bounds of variation"
  end

  hit_within_outer = full_or_partial_overlap.(from, to, view(r, :, :outerStart), view(r, :, :outerEnd))
  confidence[findall(x-> x==true, hit_within_outer)] .= "Query fully within outer bounds of variation"
  confidence[findall(x-> x==false, hit_within_outer)] .= "Query partially within outer bounds of variation"

  hit_within_range = full_or_partial_overlap.(from, to, view(r, :, :start), view(r, :, :end))
  hwrt = findall(x-> x==true, hit_within_range)
  hwrf = findall(x-> x==false, hit_within_range)
  confidence[hwrt] .= "Query fully within bounds of variation"
  confidence[hwrf] .= "Query partially within bounds of variation"

  hit_within_inner = full_or_partial_overlap.(from, to, view(r, :, :innerStart), view(r,: ,:innerEnd))
  confidence[findall(x-> x==true, hit_within_inner)] .= "Query fully within inner bounds of variation"
  confidence[findall(x-> x==false, hit_within_inner)] .= "Query partially within inner bounds of variation"

  # Change those within range that do not have inner/outer start/end to the most confident case.
  hit_within_innerRange2 = full_or_partial_overlap.(from, to, leftinner, rightinner)
  confidence[findall(x-> x==true, hit_within_innerRange2)] .= "Query fully within inner bounds of variation"
  confidence[findall(x-> x==false, hit_within_innerRange2)] .= "Query partially within inner bounds of variation"

  r[!, :confidence] = confidence

  return r
end

"""
Returns true/false for whether `query` overlaps with `seq` fully or partially. Returns nothing if they do not overlap.
"""
function full_or_partial_overlap(query1, query2, seq1, seq2)
  if ismissing(seq1) || ismissing(seq2)
    return nothing
  elseif query1 >= seq1 && query2 <= seq2
    return true
  elseif (query1 >= seq1 && query2 > seq2 && query1 <= seq2) || (query1 < seq1 && query2 <= seq2 && query2 >= seq1)
    false
  else
    return nothing
  end
end

function return_inner_range(r::AbstractDataFrame; nsamples)
  left = Array{Int}(undef, nsamples)
  right = Array{Int}(undef, nsamples)
  for row in 1:nsamples
    left[row] = maximum(skipmissing(view(r, row, [:outerStart, :start, :innerStart])))
    right[row] = minimum(skipmissing(view(r, row, [:innerEnd, :end, :outerEnd])))
  end
  return left, right
end