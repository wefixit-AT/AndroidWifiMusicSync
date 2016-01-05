require_relative 'entities/song'
require_relative 'executor'
require 'shellwords'
require 'uri'

class Tool
  @@TMP="/tmp"
  def initialize(config)
    @config=config
  end

  def log(line)
    if @config.debug
      puts "DEBUG: "+line
    end
  end

  def sync
    # read playlists and merge into one fileset
    fileNamesPlaylist = Array.new
    @config.playlist.each do |playlist|
      log "Prepare playlist: #{playlist}"
      File.readlines(playlist).each do |line|
        line.chomp!
        log "found file in the playlist: #{line}"
        fileNamesPlaylist.push(line)
      end
    end

    # remove double values
    fileNamesPlaylist = fileNamesPlaylist.uniq

    # iterate files from the playlist and save to the files list
    filesFromThePlaylist = Array.new
    fileNamesPlaylist.each do |file|
      if file.match(/.*EXTM3U.*/) or file.match(/.*EXTINF.*/)
        next
      end
      file.sub!(/file:\/\//,'');
      file=URI.decode(file)
      file.gsub!(/%/,'\\x')
      log "add file "+file
      if FileTest.file?(file)
        song = Song.new(file, true, @config.fatFs)
        filesFromThePlaylist.push(song)
      end
    end

    # display statistic: filecount and filesize and save the fileNames
    summarizedSize = 0
    filesFromThePlaylist.each do |file|
      summarizedSize+=file.size
    end
    puts "Found "+filesFromThePlaylist.size.to_s+" songs on the playlist, size: "+(summarizedSize/1024/1024/1024).to_s+"gb"

    # cleanUp if set
    if @config.cleanUp
      puts "Cleanup files from the device, this could take a long time."
      if @config.type == @config.typeSsh
        Executor.ssh_cmd(@config,true,"rm -rf #{@config.dst}/#{@config.folderMusic}")
      end
      if @config.type == @config.typeUsb
        Executor.cmd(@config,true, "rm -rf #{@config.dst}/#{@config.folderMusic}")
      end
    end

    # get file list from device
    filesOnTheDevice = Array.new
    if @config.type == @config.typeSsh
      fileNamesDeviceCmd = Executor.ssh_cmd_with_return(@config,"find #{@config.dst}/#{@config.folderMusic} -type f")
      fileNamesDeviceCmd.split("\n").each do |file|
        filesOnTheDevice.push(Song.new(file, false, @config.fatFs))
      end
    end
    if @config.type == @config.typeUsb
      folder=""
      fileNamesDeviceCmd = Executor.cmd_with_return(@config,"find #{@config.dst}/#{@config.folderMusic} -type f")
      fileNamesDeviceCmd.split("\n").each do |file|
        filesOnTheDevice.push(Song.new(file, false, @config.fatFs))
      end
    end
    puts "There are "+filesOnTheDevice.size.to_s+" songs on the device"

    # Delete files from the device
    counterDeletedFiles = 0
    filesOnTheDevice.each do |file|
      deleteFile=true
      filesFromThePlaylist.each do |fileFromThePlaylist|
        if @config.fatFs
          filename = fileFromThePlaylist.fileFatFs
        else
          filename = fileFromThePlaylist.file
        end
        if filename == file.file
          if @config.fatFs
            folderToGuess=@config.dst+"/"+@config.folderMusic+file.folderFatFs
          else
            folderToGuess=@config.dst+"/"+@config.folderMusic+file.folder
          end
          if file.folder == folderToGuess
            deleteFile = false
          end
        end
      end

      if deleteFile
        fullFile = file.folder+"/"+file.file
        fullFile = Shellwords.shellescape(fullFile)
        log "Delete file from the device: "+fullFile
        if @config.type == @config.typeSsh
          if @config.deleteFiles
            Executor.ssh_cmd(@config, true, "rm -fv \"#{fullFile}\"")
          end
        end
        if @config.type == @config.typeUsb
          if @config.deleteFiles
            Executor.cmd(@config, true, "rm -fv #{fullFile}")
          end
        end
        counterDeletedFiles+=1
      end
    end

    if @config.deleteFiles
      puts "We have deleted #{counterDeletedFiles} files from the device"
    else
      puts "We have to delete #{counterDeletedFiles} files from the device"
    end

    # generate a fileNames list to copy
    filesToCopy=Array.new
    filesFromThePlaylist.each do |fileFromThePlaylist|
      newFile = true
      filesOnTheDevice.each do |fileOnTheDevice|
        if @config.fatFs
          filenameDevice = fileOnTheDevice.fileFatFs
          filenamePlaylist = fileFromThePlaylist.fileFatFs
        else
          filenameDevice = fileOnTheDevice.file
          filenamePlaylist = fileFromThePlaylist.file
        end
        if filenameDevice == filenamePlaylist
          if @config.fatFs
            folderToGuess=@config.dst+"/"+@config.folderMusic+fileOnTheDevice.folderFatFs
          else
            folderToGuess=@config.dst+"/"+@config.folderMusic+fileOnTheDevice.folder
          end
          if fileOnTheDevice.folder == folderToGuess
            newFile = false
          end
        end
      end
      if (newFile)
        filesToCopy.push(fileFromThePlaylist)
      end
    end

    puts filesToCopy.size.to_s+" songs will be transfered to the device"

    # copy the files
    folder=@config.dst+"/"+@config.folderMusic
    cmd="mkdir -p #{folder}"
    if @config.type == @config.typeUsb
      Executor.cmd(@config, false , cmd)
    end
    if @config.type == @config.typeSsh
      Executor.ssh_cmd(@config, false, cmd)
    end

    filesToCopy.each do |file|
      if @config.fatFs
        dstDir=@config.dst+"/"+@config.folderMusic+"/"+file.folderFatFs+"/"
        srcFile=file.folder+"/"+file.file
      else
        dstDir=@config.dst+"/"+@config.folderMusic+"/"+file.folder+"/"
        srcFile=file.folder+"/"+file.file
      end
      if @config.copyFiles
        if @config.type == @config.typeSsh
          Executor.ssh_cmd(@config, false, "mkdir -p \"#{Shellwords.shellescape(dstDir)}\"")
          if @config.fatFs
            dstDir += "/"+file.fileFatFs
          end
          Executor.ssh_cp(@config,srcFile,dstDir)
        end
        if @config.type == @config.typeUsb
          Executor.cmd(@config, false, "mkdir -p #{Shellwords.shellescape(dstDir)}")
          if @config.fatFs
            dstDir += "/"+file.fileFatFs
          end
          Executor.cp(@config, srcFile, dstDir)
        end
      end
      log "File copied: "+file.folder+"/"+file.file
      print "."
      $stdout.flush
    end
    print "\n"

    # delete old playlists
    playlistFolder="#{@config.dst}/#{@config.folderPlaylist}"
    cmd = "rm -rf #{Shellwords.escape(playlistFolder+"/*")}"
    if @config.type == @config.typeUsb
      Executor.cmd(@config,false,cmd)
    end
    if @config.type == @config.typeSsh
      Executor.ssh_cmd(@config,false,cmd)
    end

    # prepare playlist and store it on the device
    @config.playlist.each do |playlist|
      log "Prepare playlist: #{playlist}"
      # Create playlist folder
      cmd = "mkdir #{playlistFolder}"
      if @config.type == @config.typeUsb
        Executor.cmd(@config,false,cmd)
      end
      if @config.type == @config.typeSsh
        Executor.ssh_cmd(@config,false,cmd)
      end

      tmpPlaylistfile=@@TMP+"/"+playlist.split("/").last
      log "Created playlist file: #{tmpPlaylistfile}"
      playlistFile=File.open(tmpPlaylistfile,"w")
      fileNamesPlaylist.clear
      File.readlines(playlist).each do |line|
        line.chomp!
        log "found file in the playlist: #{line}"
        fileNamesPlaylist.push(line)
      end
      # remove double values
      fileNamesPlaylist = fileNamesPlaylist.uniq

      # iterate files from the playlist and save to the files list
      filesFromThePlaylist = Array.new
      fileNamesPlaylist.each do |file|
        if file.match(/.*EXTM3U.*/) or file.match(/.*EXTINF.*/)
          next
        end
        file.sub!(/file:\/\//,'');
        file=URI.decode(file)
        file.gsub!(/%/,'\\x')
        log "Add file "+file
        if FileTest.file?(file)
          song = Song.new(file, true, @config.fatFs)
          filesFromThePlaylist.push(song)
        end
      end

      filesFromThePlaylist.each do |file|
        if @config.overrideRoot
          dstFile = @config.overrideRoot
        else
          dstFile = @config.dst
        end
        dstFile += "/"+@config.folderMusic+"/"
        if @config.fatFs
          dstFile += file.folderFatFs+"/"+file.fileFatFs+""
        else
          dstFile += file.folder+"/"+file.file+""
        end
        log "Playlist append file: #{dstFile}"
        playlistFile.write(dstFile+"\n")
      end

      playlistFile.close unless playlistFile.nil?

      # Copy the playlist to the device
      if @config.type == @config.typeUsb
        Executor.cp(@config,tmpPlaylistfile,playlistFolder)
      end
      if @config.type == @config.typeSsh
        Executor.ssh_cp(@config,tmpPlaylistfile,playlistFolder+"/")
      end

      log "Saved playlist to: #{playlistFolder}"

    end

    # synchronize filesystem
    if @config.type == @config.typeUsb
      puts "Filesystem synchronization started"
      `sync`
    end

    puts "Synchronization done"
  end
end
