using Test
using CnvAnnotator

@test CnvAnnotator.full_or_partial_overlap(4, 10, 2, 11) == true
@test CnvAnnotator.full_or_partial_overlap(4, 10, 5, 11) == false
@test CnvAnnotator.full_or_partial_overlap(4, 10, 2, 8) == false
@test CnvAnnotator.full_or_partial_overlap(4, 10, 12, 21) == nothing
@test CnvAnnotator.full_or_partial_overlap(12, 21, 4, 10) == nothing