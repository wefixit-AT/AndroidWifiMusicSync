require_relative 'tool'
require_relative 'config'

config = Config.new
config.playlist="/home/user/Music/forMyCar.m3u"
config.ip="192.168.66.10"
config.user="root"
config.dst="/extSdCard/Music"
config.debug=true
config.copyFiles=false
config.deleteFiles=false
config.type=config.typePhone

tool = Tool.new
tool.config = config
tool.sync