# helpers for add Sequence view
module SequenceHelper
  # title for add_sequence page, e.g.:
	#   Add Sequence to Observation 123456
	#   Polyporus badius (Pers.) Schwein. (Consensus)
	#   Polyporus melanopus group (Observer Preference)
  def add_sequence_title(obs)
    capture do
      concat(:sequence_add_title.t)
      concat(" #{obs.id || "?"} ")
      concat(obs.name.format_name.t)
    end
  end

  # on-line primary-source repositories (Archives) for nucleotide sequences
  # in menu order
  #   name::    short name, used in drop-down menu
  #   home::    home page
  #   prefix::  prefix for Accession (When Accession is appended to this,
  #             it will land on the page for that Accession in the Archive.)
  def archives
    [
      { name:   "GenBank",
        home:   "https://www.ncbi.nlm.nih.gov/genbank/",
        prefix: "https://www.ncbi.nlm.nih.gov/nuccore/"},
      { name:   "ENA",
        home:   "http://www.ebi.ac.uk/ena",
        prefix: "http://www.ebi.ac.uk/ena/data/view/" },
      { name:   "UNITE",
        home:   "https://unite.ut.ee/",
        prefix: "https://unite.ut.ee/search.php?qresult=yes&accno="}
    ]
  end

  # returns the archive hash for the named archive
  def archive(name)
    archives.find {|r| r[:name] == name}
  end

  # url of a search for accession in the named external archive
  def search_for_accession_url(name, accession)
    archive(name)[:prefix] + accession
  end

  # dropdown list for add_sequence
  def archive_dropdown
    archives.each_with_object([]) do |archive, array|
      array << [archive[:name], archive[:name]]
    end
  end
end
