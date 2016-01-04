require 'shellwords'

# Execute system commands
class Executor
  @retry_max = 2
  @failure_timeout = 1 # seconds
  def self.cmd(config, checkReturnValue, cmd)
    `#{cmd} 2> /dev/null`
    self.inspectReturnValue(checkReturnValue, $?.success?, cmd)
  end

  def self.ssh_cmd(config, checkReturnValue, cmd)
    cmd = "ssh -p #{config.port} #{config.username}@#{config.ip} #{cmd} 2> /dev/null"
    `#{cmd}`
    self.inspectReturnValue(checkReturnValue, $?.success?, cmd)
  end

  # Executes the command and returns the output
  def self.cmd_with_return(config, cmd)
    return `#{cmd} 2> /dev/null`
  end

  # Executes the command over ssh and ,0returns the output
  def self.ssh_cmd_with_return(config, cmd)
    return `ssh -p #{config.port} #{config.username}@#{config.ip} #{cmd} 2> /dev/null`
  end

  # Returns true if the file was copied
  def self.ssh_cp(config, src, dst)
    src = Shellwords.shellescape(src)
    dst = Shellwords.shellescape(dst)
    cmd = "scp -P #{config.port} #{src} #{config.username}@#{config.ip}:'#{dst}' 2> /dev/null"
    `#{cmd}`
    self.inspectReturnValue(true, $?.success?, cmd)
  end

  def self.cp(config,src,dst)
    src = Shellwords.shellescape(src)
    dst = Shellwords.shellescape(dst)
    cmd = "cp #{src} #{dst} 2> /dev/null"
    `#{cmd}`
    self.inspectReturnValue(true, $?.success?, cmd)
  end

  def self.inspectReturnValue(checkReturnValue, returnValue, cmd)
    # TODO Create static private method (?)
    if checkReturnValue
      if not returnValue
        puts "!!! Can not execute command: #{cmd}"
        exit 1
      end
    end
  end
end