export populate_db

"Downloads all dbVar data from GRCh38"
function download_data(datadir, overwrite)
  callfile = "https://ftp.ncbi.nlm.nih.gov/pub/dbVar/data/Homo_sapiens/by_assembly/GRCh38/gvf/GRCh38.variant_call.all.gvf.gz"

  @RemoteFile(GRCh38_calls, callfile, dir=datadir)

  if !isfile(GRCh38_calls) || overwrite
    println("Downloading data. This can take a few minutes.")
    download(GRCh38_calls)
  end
  varcalls = path(GRCh38_calls)

  return varcalls
end

"Populates and returns a SQLite db"
function populate_db(datadir, overwrite; chr=1)
  allvarfile = download_data(datadir, overwrite)
  allvar = GZip.open(allvarfile)
  
  dbfile = joinpath(datadir, "snvdb.mysql")
  db = SQLite.DB(dbfile)

  chr1 = "NC_000001.11"  # from https://www.ncbi.nlm.nih.gov/grc/human/data

  stmt = "CREATE TABLE IF NOT EXISTS tab (
      start INT,
      end INT,
      ID Int,
      alias TINYTEXT,
      outerStart INT,
      innerStart INT,
      innerEnd INT,
      outerEnd INT,
      CNV TINYTEXT,
      originalID TINYTEXT,
      dataOrigin TINYTEXT,
      pathogenicity TINYTEXT,
      PRIMARY KEY (ID, alias)
    );"
  SQLite.DBInterface.execute(db, stmt)

  insertstmt = """
    INSERT INTO tab (
      start,
      end,
      ID,
      alias,
      outerStart,
      innerStart,
      innerEnd,
      outerEnd,
      CNV,
      originalID,
      dataOrigin,
      pathogenicity
    )
    VALUES(?,?,?,?,?,?,?,?,?,?,?,?)
  """
  q = SQLite.DBInterface.prepare(db, insertstmt)
  
  println("Creating database for the first time...")
  SQLite.transaction(db, "DEFERRED")
  progress = Progress(36009642, 1)  # from https://www.ncbi.nlm.nih.gov/dbvar/content/var_summary/
  for line in eachline(allvar)
    if startswith(line, chr1)
      fields = split(line, "\t")
      dataOrigin = fields[2]
      CNV = fields[3]
      start = fields[4] == "." ? missing : parse(Int, fields[4])
      endd = fields[5] == "." ? missing : parse(Int, fields[5])
      pairs = split(fields[9], ";")
      pairdict = pair2dict(pairs)
      ID = parse(Int, pairdict["ID"])
      alias = pairdict["Alias"]
      phenotype = pairdict["phenotype"]
      if haskey(pairdict, "End_range")
        innerEnd, outerEnd = parse_range(pairdict["End_range"])
      else
        innerEnd, outerEnd = missing, missing
      end
      if haskey(pairdict, "Start_range")
        innerStart, outerStart = parse_range(pairdict["Start_range"])
      else
        innerStart, outerStart = missing, missing
      end
      originalID = pairdict["Name"]

      SQLite.DBInterface.execute(q, [start, endd, ID, alias, outerStart, innerStart, innerEnd, outerEnd, CNV, originalID, dataOrigin, phenotype])
    end
    next!(progress)
  end
  SQLite.commit(db)
  println("Indexing...")
  SQLite.DBInterface.execute(db, "CREATE INDEX pos ON tab (start,end)")
  return db
end

"Creates a dictionary from a list of pairs separated by '=' "
function pair2dict(pairs::AbstractArray)
  pairdict = Dict{String, String}()
  for element in pairs
    sep = split(element, "=")
    pairdict[sep[1]] = sep[2]
  end
  return pairdict
end

"Parse inner/outer start/end to correct type"
function parse_range(rang::String)
  ll = split(rang, ",")
  inner = ll[1] == "." ? missing : parse(Int, ll[1])
  outer = ll[2] == "." ? missing : parse(Int, ll[2])
  return inner,outer
end