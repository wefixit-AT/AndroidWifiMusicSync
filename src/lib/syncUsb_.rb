require_relative 'tool'
require_relative 'config'

config = Config.new
config.playlist="/mnt/daten1/linux/home/benutzername/Downloads/x_bus_16gb.m3u"
config.dst="/media/benutzername/1BBC-C29B1/mp3"
config.debug=false
config.copyFiles=true
config.deleteFiles=true
config.type=config.typeUsb

tool = Tool.new
tool.config = config
tool.sync
