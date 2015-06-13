class CleanFilename
  def self.clean(filename)
    # remove unwanted characters which lead to problems on different filesystems
    # it works because only the id3tags are important
    filename.gsub!(/ /,"")
    filename.gsub!(/\(/,"")
    filename.gsub!(/\)/,"")
    filename.gsub!(/\[/,"")
    filename.gsub!(/\]/,"")
    filename.gsub!(/\$/,"")
    filename.gsub!(/\&/,"")
    filename.gsub!(/\'/,"")
    filename.gsub!(/\,/,"")
    filename.gsub!(/-/,"")
    filename.gsub!(/ú/,"")
    filename.gsub!(/í/,"")
    filename.gsub!(/ö/,"")
    filename.gsub!(/ä/,"")
    filename.gsub!(/ü/,"")
    filename.gsub!(/_/,"")
    filename.gsub!(/!/,"")
    filename.gsub!(/\?/,"")
    filename.gsub!(/ß/,"")
    filename.gsub!(/ó/,"")
    filename.gsub!(/Ñ/,"")
    filename.gsub!(/:/,"")
    return filename
  end
end