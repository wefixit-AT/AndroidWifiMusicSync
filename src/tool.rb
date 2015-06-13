require_relative 'entities/song'
require_relative 'cleanFilename'
require 'shellwords'
require 'uri'

class Tool
  attr_accessor :config
  def log(line)
    if @config.debug
      puts "DEBUG: "+line
    end
  end

  def sync
    if (config.type != @config.typeUsb) && (@config.type != @config.typePhone)
      puts "!!! wrong type set please check the config, type: "+@config.type
      return
    end

    # check if phone is reachable
    if @config.type == @config.typePhone
      if not `ping -c 3 #{@config.ip}`
        puts "!!! the phone seems offline "+@config.ip
        return
      end
    end

    # check if playlist exists
    if !FileTest.file?(@config.playlist)
      puts "!!! playlist can't be opened: #{@config.playlist}"
      return
    end

    # read playlist
    fileNamesPlaylist = Array.new
    File.readlines(@config.playlist).each do |line|
      line.chomp!
      log "found file in the playlist: #{line}"
      fileNamesPlaylist.push(line)
    end

    # remove double values
    fileNamesPlaylist = fileNamesPlaylist.uniq

    # iterate files from the playlist and save to the files list
    files = Array.new
    fileNamesPlaylist.each do |file|
      if file.match(/.*EXTM3U.*/) or file.match(/.*EXTINF.*/)
        next
      end
      file.sub!(/file:\/\//,'');
      file=URI.decode(file)
      file.gsub!(/%/,'\\x')
      log "add file "+file
      if FileTest.file?(file)
        song = Song.new(file)
        song.calcSize
        files.push(song)
      end
    end

    # display statistic: filecount and filesize and save the fileNames
    summarizedSize = 0
    fileNames=Array.new
    files.each do |file|
      summarizedSize+=file.size
      fileNames.push(CleanFilename.clean(file.file))
    end
    puts "found "+fileNames.size.to_s+" songs to copy"
    puts "size: "+(summarizedSize/1024/1024/1024).to_s+"gb"

    # get file list from device
    fileNamesDevice = Array.new
    if @config.type == @config.typePhone
      fileNamesDeviceCmd = `ssh #{@config.user}@#{@config.ip} ls -1 -A #{@config.dst}/ &> /dev/null`
      fileNamesDeviceCmd.split("\n").each do |file|
        fileNamesDevice.push(file)
      end
    end
    if @config.type == @config.typeUsb
      fileNamesDeviceCmd = `ls -1 -A #{@config.dst}/ &> /dev/null`
      fileNamesDeviceCmd.split("\n").each do |file|
        fileNamesDevice.push(file)
      end
    end
    puts "there are "+fileNamesDevice.size.to_s+" songs on the device"

    # generate a list of files which should be deleted
    if @config.deleteFiles
      fileNamesDevice.each do |file|
        if not fileNames.include?(file)
          log "delete file from the device: "+@config.dst+"/"+file
          if @config.type == @config.typePhone
            if @config.copyFiles
              `ssh #{@config.user}@#{@config.ip} rm -v '#{@config.dst}/#{file}'`
            end
          end
          if @config.type == @config.typeUsb
            `rm -v '#{@config.dst}/#{file}'`
          end
        end
      end
    end

    # generate a fileNames list to copy
    fileNamesToCopy=Array.new
    fileNames.each do |newFile|
      if not fileNamesDevice.include?(newFile)
        fileNamesToCopy.push(newFile)
      end
    end

    # generate a list of files to copy including the songs entity
    filesToCopy=Array.new
    files.each do |file|
      if fileNamesToCopy.include?(file.file)
        filesToCopy.push(file)
      end
    end

    puts "we have to copy "+filesToCopy.size.to_s+" songs"

    filesToCopy.each do |file|
      filePathClean = file.path
      pathClean = Shellwords.escape(@config.dst)
      if @config.type == @config.typePhone
        cmd = "scp \""+filePathClean+"\" \'"+@config.user+"@"+@config.ip+":/"+pathClean+"/"+file.file+"\'"
      end
      if @config.type == @config.typeUsb
        cmd = "cp \""+filePathClean+"\" \'/"+pathClean+"/"+file.file+"\'"
      end
      log "cmd: "+cmd
      if not @dryRun
        returnValue = system(cmd)
        log "returnValue: "+returnValue.to_s
        if not returnValue
          puts "!!! problem during copying"
          return
        end
      end
      puts "file copied: "+file.file
    end

  end
end
