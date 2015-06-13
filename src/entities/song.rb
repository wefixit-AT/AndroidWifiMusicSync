class Song
  attr_reader :path
  attr_reader :file
  attr_reader :size
  def initialize(path)
    @path=path
    splitted=path.split("/")
    @file=splitted[splitted.size-1]
  end

  def calcSize
    @size=File.size(@path)
  end
end