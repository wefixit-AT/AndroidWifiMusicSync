require_relative 'tool'
require_relative 'config'

config = Config.new
config.playlist="/home/user/Music/forMyCar.m3u"
config.dst="/media/user/1CC2-329A/mp3"
config.debug=true
config.copyFiles=false
config.deleteFiles=false
config.type=config.typeUsb

tool = Tool.new
tool.config = config
tool.sync