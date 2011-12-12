desc 'Generate sample ssh output.'
file 'ssh_sample.txt', :user_name, :server do |file, args|
  user = args[:user_name]
  server = args[:server]

  options = {:user => user, :server => server}

  File.open('ssh_sample.txt', 'w') do |file|
    file.puts get_result
    file.puts get_result 'ls',   :user => nil,         :server => server
    file.puts get_result 'ls',   :user => user,        :server => nil
    file.puts get_result 'ls',   :user => '',          :server => server
    file.puts get_result 'ls',   :user => user,        :server => ''
    file.puts get_result 'ls',   :user => 'deny_user', :server => server
    file.puts get_result 'ls',   :user => user,        :server => 'deny_server'
    file.puts get_result 'ls /', options
    file.puts get_result 'ls /home/giggidy', options
  end

  puts `cat ssh_sample.txt`.chomp
end

#~ task :ssh_temp, :user_name, :server do |task, args|
  #~ Rake::Task['ssh_sample.txt'].invoke(args[:user_name], args[:server])
  #~ Rake::Task[:clobber].invoke
#~ end

CLOBBER.include('ssh_sample.txt')

# Returns the result of the ssh command.
def get_result(command = 'ls', options = {})
  result, output = Ssh.run_ssh(options, command)
  format_output(options, result, output)
end

# Formats the output of the ssh command with the options specified.
def format_output(options, result, output)
  format = "%s\nreturn %s, %s"

  results = []
  results << options
  results << result

  if output.nil?
    results << 'nil'
  else
    results << "'#{output.gsub("\n", '\n')}'"
  end

  return format % results
end

# Ssh class to run ssh commands for output purposes.
class Ssh
  # This method executes the ssh command using the specified options.
  #
  # This method should match ssh_run from the main class.
  def self.run_ssh(options, command)
    out = StringIO.new
    result = true

    begin
      Net::SSH.start(options[:server], options[:user]) do |ssh|
        ssh.exec!(command) do |channel, stream, output|
          result = false if stream == :stderr
          out.puts output
        end
      end
    rescue Exception => exc
      result = false
    end

    return result, out.string.gsub(/\n*\z/, '')
  end
end
