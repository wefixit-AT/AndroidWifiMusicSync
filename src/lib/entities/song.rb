class Song
  attr_reader :folder, :file, :size, :fileFatFs, :folderFatFs
  @@fatFsBadCharacters=["/","\\","?","<",">","*","|","\"","(",")",":","É","ñ"]
  @@fatFsNameLength=12
  @@fatFsMaxFolderDepth=4

  def initialize(path, storeSize, fatFs)
    @path=path
    splitted=path.split("/")
    @file=splitted[splitted.size-1]
    @folder=splitted[0..splitted.size-2].join("/")

    if storeSize
      # The file size is only for files important which are not on the device
      @size=File.size(@path)
    else
      @size=0
    end

    if fatFs
      # If the destination is a fat filesystem the names has to be changed to because many characters are not allowed
      @fileFatFs=renameForFat(@file.clone,true)
      folder=Array.new
      folder.push("/")
      @folder.split("/").each do |f|
        if not f.empty?
          folder.push(renameForFat(f,false))
        end
      end
      @folderFatFs="/"+folder.join("/")
      folder=@folderFatFs.split("/")
      folder.reject! { |f| f.empty? }
      if folder.size > @@fatFsMaxFolderDepth
        folder=folder[(folder.size-@@fatFsMaxFolderDepth)..folder.size]
        folder="/"+folder.join("/")
        @folderFatFs=folder
      end
      @folderFatFs.gsub!("'", "_")
      @folderFatFs.gsub!("&", "_")
      @fileFatFs.gsub!("'", "_")
      @fileFatFs.gsub!("&", "_")
    end
  end

  private

  def renameForFat(nameOriginal,is_file)
    @@fatFsBadCharacters.each do |char|
      nameOriginal.gsub!(char,"")
      if is_file
        array=nameOriginal.split(".")
        name=array[0..array.length-2].join
      else
        name=nameOriginal.clone
      end
      if name.length > @@fatFsNameLength
        name=name[-@@fatFsNameLength..name.length]
        if is_file
          extension=array[array.length-1]
          nameOriginal=name+"."+extension
        else
          nameOriginal=name
        end
      end
    end
    return nameOriginal.strip
  end
end