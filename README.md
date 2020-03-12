# CnvAnnotator.jl

Query overlap of a desired genomic region with Copy Number Variations (CNVs) available in [dbVar](https://www.ncbi.nlm.nih.gov/dbvar).

## Installation

Within a Julia REPL:

```jl
]add https://github.com/kavir1698/CnvAnnotator.jl.git
```

## Usage

The interface to this package is through the `return_variants` function:

```
    return_variants(from::Int, to::Int; kwargs)

Returns all the variants on Chr1 between `from` and `to`.

# kwargs

* tolerance::Int=0 also search as many bases as `tolerance` away from your query.
* chr::Int=1 currently only support chr 1. 
* overwrite::Bool=false force re-create database.
* only_phenotyped::Bool=false only return variants which have a phenotype.
* datadir="./" where to save downloaded and database files.
```

On the first call of the function, it downloads all variant calls within GRChr38 assembly from dbVar website and creates a local database in SQLite. The local database contains the following information about variants: position, including inner/outer start/end; ID; alias; variation type (copy number status); variation's original ID; data origin; and pathogenicity of the variation. Building the database for the first time can take a few minutes (it takes 10 mins on my machine).

## Example

```julia
using CnvAnnotator

r = return_variants(2000, 10000, tolerance=1000, only_phenotyped=true, datadir="./")
```

This example returns all variations that partially or fully overlap with a region ranging from position 1000 (from - tolerance) to 11000 (to + tolerance) and filters only those who report a phenotype. It returns the output in a `DataFrame` for easy further analysis. It saves the data in the current directory.

The function also creates one additional feature for each variant: confidence. It determines the confidence we have in that a variation overlaps with the query. The exact position of some variants are not known, but we know the possible ranges of their start and end. 

A query can be partially or fully within the bounds of a variation. When a query is only partially within the outer bounds of a variation, we are the least confident that the variation affects the query. Only parts of the query reaches within outer bounds of the variation. If a query is fully within outer bounds, we have more confidence.

Alternatively, a query can be partially or fully within the bounds of a variation, in which case, we are more confident that the variation affects the query. Finally, if a query is partially or fully within the inner bounds of a variation, we are most confident that the variation affects the query (or at least part of the query).

Some variations do not have inner/outer start/end. In such cases, the start/end are their definitive positions. CnvAnnotator considers those definitive positions as inner bounds when reporting confidence.