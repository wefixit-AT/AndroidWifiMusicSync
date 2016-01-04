#!/usr/bin/ruby
require 'yaml'

require_relative 'lib/tool'
require_relative 'lib/config'

def usage
  puts "Usage: ruby sync.rb <config-file>"
end

if ARGV.size != 1
  usage
  exit 1
end

configFile = ARGV[0]

if not FileTest.file?(configFile)
  puts "!!! Can not open config file on destination: "+configFile
  exit 1
end

configYaml = YAML.load_file(configFile)

config = Configuration.new(configYaml)
if not config.valid?
  exit 1
end

tool = Tool.new(config)
tool.sync
