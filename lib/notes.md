
# To do

0. Download CVN data for chromosome 1.
0. Create a database with the required fields from the data.
0. Provide a script for filling the database.
0. A script for finding variants given a genomic regions.

## dbVar

VCF files do not have copy number and indels. So I should use GVF files.

* [dbVar README](https://ftp.ncbi.nlm.nih.gov/pub/dbVar/data/README.txt)
* [Anonymous FTP access](https://ftp.ncbi.nlm.nih.gov/pub/dbVar/)
* [VCF files (GRCh38)](https://ftp.ncbi.nlm.nih.gov/pub/dbVar/data/Homo_sapiens/by_assembly/GRCh38/vcf/)
* [GVF files](https://ftp.ncbi.nlm.nih.gov/pub/dbVar/data/Homo_sapiens/by_assembly/GRCh38/gvf/)
* [GVF specifications](https://github.com/The-Sequence-Ontology/Specifications/blob/master/gvf.md)
* [GVF format paper]( http://www.yandell-lab.org/publications/pdf/gvf_format.pdf)
* [Description of structural variation](https://www.ncbi.nlm.nih.gov/dbvar/content/overview/)
* Columns:
  1. Seqid: The ID of the landmark used to establish the coordinate system for the current feature
  2. source: The source is a free text qualifier intended to describe the algorithm or operating procedure that generated this feature. Typically this is the name of a piece of software, such as "MAQ" or a database name, such as "dbSNP".
  3. type: The type of the feature. This is constrained to be either: (a) the SO term sequence_alteration SO:0001059, (b) a child term of sequence_alteration, (c) the SO term no_sequence_alteration SO:0002073, (d) the SO term gap SO:0000730, or (e) the SO accession number for any of the previous terms.
  Example of [SO sequence alterations](http://www.sequenceontology.org/browser/current_svn/term/SO:0001059).
  4. start
  5. end
  6. score: The semantics of the score are not defined, however it is strongly recommended that a [Phred scaled quality score](https://en.wikipedia.org/wiki/Phred_quality_score) be used whenever possible.
  7. strand: The '+' (plus sign) for positive strand (relative to the landmark), and the '-' (minus sign) for minus strand, and '.' (period) for features that are not stranded. In addition, '?' (question mark) can be used for features whose strandedness is relevant, but unknown.
  8. phase: The phase column is not used in GVF, but is maintained with the placeholder '.' (period) for compatibility with GFF3 and tools that conform to the GFF3 specification.
  9. The ninth column in GFF3/GVF contains one or more tag/value pairs that describe attributes of the feature.
     1.  ID
     2.  Name
     3.  Alias
     4.  parent
     5.  ..
     6.  ..
     7.  Start_range
     8.  End_range
     9.  remapScore
     10. sample_name
     11. sampleset_name
     12. phenotype
     13. Variant_seq
     14. Reference_seq
* Difference between variant region and variant call ([here](https://www.ncbi.nlm.nih.gov/dbvar/content/overview/)).
* Chromosomes are referred to as [accession numbers](https://www.ncbi.nlm.nih.gov/grc/human/data).

## Algorithm

First check whether a query region overlaps a variant region. If true, search the variant calls for detailed information. 

## Database design

* [A tutorial](https://stackoverflow.com/questions/377375/a-beginners-guide-to-sql-database-design)
* [Book](https://www.amazon.co.uk/Relational-Database-Explained-Kaufmann-Management/dp/1558608206/ref=sr_1_3?ie=UTF8&s=books&qid=1229597641&sr=8-3)
* Indexing
* Normalizing
* Foreign key
* Add progress meter to populate db