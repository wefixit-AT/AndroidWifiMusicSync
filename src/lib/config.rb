class Configuration
  attr_reader :dst, :playlist, :ip, :username, :port, :deleteFiles, :debug, :copyFiles, :type, :cleanUp, :fatFs
  @@folderMusic="music"
  @@folderPlaylist="playlist"
  @@typeUsb="usb"
  @@typeSsh="ssh"
  def initialize(configYaml)
    @debug =configYaml['debug']
    @copyFiles=configYaml['copyFiles']
    @deleteFiles=configYaml['deleteFiles']
    @type=configYaml['type']
    @playlist=configYaml['playlist']
    @ip=configYaml['ip']
    @port=configYaml['port']
    @username=configYaml['username']
    @dst=configYaml['dst']
    @cleanUp=configYaml['cleanUp']
    @fatFs=configYaml['fatFs']
  end

  def folderMusic
    @@folderMusic
  end

  def folderPlaylist
    @@folderPlaylist
  end

  def valid?
    valid=true
    # check if type is correct
    if @type != @@typeUsb and @type != @@typeSsh
      puts "!!! wrong type set please check the config, type: "+@type
      valid=false
    end

    # check if playlist exists
    @playlist.each do|file|
      if !FileTest.file?(file)
        puts "!!! playlist can't be opened: #{file}"
        valid=false
      end
    end

    # if type is SSH test the connection
    if @type == @@typeSsh
      `ssh -p #{@port} #{@username}@#{@ip} whoami 2>&1`
      returnValue = $?.success?
      if not returnValue
        puts "!!! SSH connection not possible, please check the config"
        valid = false
      end
    end

    # check if the destination is valid
    if @type == @@typeUsb
      `ls #{dst} 2>&1`
      returnValue = $?.success?
      if not returnValue
        puts "!!! Can not open destination: #{dst}"
        valid = false
      end
    end
    if @type == @@typeSsh
      `ssh -p #{@port} #{@username}@#{@ip} ls #{dst} 2>&1`
      returnValue = $?.success?
      if not returnValue
        puts "!!! Can not open destination: #{dst}"
        valid = false
      end
    end

    return valid
  end

  def typeSsh
    @@typeSsh
  end

  def typeUsb
    @@typeUsb
  end
end
