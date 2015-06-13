class Config
  attr_accessor :dst, :playlist, :ip, :user, :deleteFiles, :debug, :copyFiles, :type
  @@typeUsb="usb"
  @@typePhone="phone"
  def typeUsb
    @@typeUsb
  end

  def typePhone
    @@typePhone
  end
end