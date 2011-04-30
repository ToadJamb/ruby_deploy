#!/usr/bin/ruby

# This file contains the main class for this application.

#--
################################################################################
#                      Copyright (C) 2011 Travis Herrick                       #
################################################################################
#                                                                              #
#                                 \v^V,^!v\^/                                  #
#                                 ~%       %~                                  #
#                                 {  _   _  }                                  #
#                                 (  *   -  )                                  #
#                                 |    /    |                                  #
#                                  \   _,  /                                   #
#                                   \__.__/                                    #
#                                                                              #
################################################################################
# This program is free software: you can redistribute it                       #
# and/or modify it under the terms of the GNU General Public License           #
# as published by the Free Software Foundation,                                #
# either version 3 of the License, or (at your option) any later version.      #
#                                                                              #
# Commercial licensing may be available for a fee under a different license.   #
################################################################################
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY;                                                    #
# without even the implied warranty of MERCHANTABILITY                         #
# or FITNESS FOR A PARTICULAR PURPOSE.                                         #
# See the GNU General Public License for more details.                         #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.        #
################################################################################
#++

requirements = Dir[File.join(File.dirname(__FILE__), 'lib', '**.rb')]
requirements.each do |file|
  require file
end

unless ScriptEnv.testing
  require 'open4'
  require 'trollop'
  require 'net/ssh'
  require 'highline/import'
  require 'date'
  require 'fileutils'
  require 'stringio'
end

# This class handles the deployment duties.
#
# Run deploy.rb -h (or see the HELP_TEXT constant) for more info.
# ==== Examples
#  myobj = Deploy.new(ARGV)
#  myobj.deploy()
class Deploy
  include BacktickText

  # Simple class that holds the version information.
  class Version
    # Major build number.
    MAJOR = 0

    # Minor build number.
    MINOR = 0

    # Build number.
    REVISION = 3

    # Convert it to a nice string 'automagically'.
    def self.to_s
      '%s %d.%d.%d' % [name[0..name.index('::') - 1], MAJOR, MINOR, REVISION]
    end
  end

  # Default settings.
  #
  # These settings can be overridden by the config file(s).
  SETTINGS = {
    :config_path => File.expand_path('~/.deploy'),
    :project => File.basename(File.expand_path(Dir.getwd)).downcase,
    :rails_db_yml => File.join('.', 'config', 'database.yml'),
  }

  # Default values that will be used if not specified in the config file.
  #
  # The hash keys are used to validate keys in the config file.
  DEFAULT_OPTIONS = {
    :user        => nil,
    :server      => nil,
    :path        => nil,
    :environment => nil,
    :extension   => nil,
    :tag_it      => false,
    :branch      => nil,
    :tag         => nil,
    :permissions => 500,
  }

  # The help text to be displayed when someone uses the -h or --help flags.
  HELP_TEXT =<<EOT
#{self.name}.rb [OPTIONS]

Deploys the code in the current directory to the specified location.

  #{self.name} will look for .exclude in the root folder
  to use as an exclude file to send to rsync.  Additional exclusions may be
  added based on the environment you are deploying to by looking for
  .environment.exclude in the root folder.

  Notes on differences between local and remote deployments:

    1. Local deployments will warn about code not being checked in,
       but will not prevent deployments from happening.  Remote deployments
       will not be allowed with outstanding changes.

    2. By default, local deployments are not tagged in source control.
       Remote deployments will be.  Either (or both) of these may be
       turned on/off by using tag-it in the appropriate config file.
       tag-it will require that all code is committed before deploying.

  NOTE: All options are case sensitive!

options:
EOT

  # Messages that are sent to the terminal.
  MESSAGES = {
    :destination   => "Specify destinations - multiple destinations may be " +
                      "specified at once. Each destination corresponds to a " +
                      "similarly named file in ~/.deploy.",
    :deploy_local  => "Are you sure you want to deploy %s to %s?",
    :deploy_remote => "Are you sure you want to deploy %s to %s@%s:%s?",
    :unknown_opt   => "Error: unknown option '%s'.",
    :help          => "\nTry --help for help.",
    :no_config     => "Error: Config file '%s' not found.",
    :no_path       => "Error: No path was specified in '%s'.",
    :empty_config  => "'%s' is empty.",
    :no_settings   => "Error: '%s' contains no valid settings.",
    :na_lines      => "'%s' contains lines that cannot be converted " +
                      "to key/value pairs.",
    :na_line       => "Error: '%s' is an invalid setting in '%s'.",
    :bad_key       => "Error: '%s' is an unknown key in '%s'.",
    :dup_key       => "Error: '%s' is a duplicate key in '%s'.",
    :no_server     => "Error: A user without a server " +
                      "has been specified in '%s'.",
    :no_user       => "Error: A server without a user " +
                      "has been specified in '%s'.",
    :bad_ssh       => "Error: '%s@%s:%s' specified in %s is an invalid path " +
                      "or the user does not have appropriate privileges.",
    :bad_path      => "Error: '%s' specified in %s is an invalid path " +
                      "or the user does not have appropriate privileges.",
    :check_out     => "Error: There are pending changes. " +
                      "The current settings do not allow uncommitted changes " +
                      "to be pushed to '%s'.",
    :no_repo       => "Error: The current working directory " +
                      "does not appear to be the project root.",
    :user_group    => "user:group could not be determined for %s.",
    :chmod_fail    => "chmod was unsuccessful on %s.",
    :chmod         => "Changing permissions on %s to %d...",
    :copying       => "Copying files to %s...",
    :rsync         => "RSync command failed for %s.",
    :chown         => "Resetting owner to %s on %s...",
    :chown_fail    => "Resetting owner to %s was unsuccessful for %s.",
    :tagging       => "Tagging changeset %s...",
    :copy_db_yml   => "Copying database.yml...",
    :dest_missing  => "is required",
  }

  # The constructor - Set up instance variables and parse parameters.
  # ==== Input
  # [params : Array] The command line parameters that were passed in.
  # [out : IO : $stdout] The stream that output will be sent to.
  # [err : IO : $stderr] The stream that errors will be sent to.
  def initialize(params, out = $stdout, err = $stderr)
    @hg_id = nil
    @hg_status = nil
    @params = params
    @ssh_output = nil

    parse_params

    @config_options = []
  end

  # This method does the work of deploying the code.
  def deploy
    return unless valid_hg?
    return unless valid_params?

    @hg_status, = run_hg('status')

    # Loop through the config files to create options hash
    # and validate values.
    @options[:dest].each do |config|
      config_path = File.join(SETTINGS[:config_path], config)

      return unless valid_config?(config_path)

      set_default_options(@config_options.length - 1, config)

      return unless valid_options?(@config_options.last, config_path)
    end

    # Get the id of the current changeset.
    @hg_id, = run_hg('id')
    @hg_id = @hg_id[0..11]
    hg_log, = run_hg("log --rev #{@hg_id}")

    puts hg_log
    puts @hg_status unless @hg_status.empty?
    puts

    question = nil

    # Loop through the options hashes to deploy for each one.
    @config_options.each do |options|
      question = deploy_question(options[:path],
        options[:user], options[:server])

      # Prompt the user to make sure they want to deploy to this location.
      if !yes?(question)
        options[:status] = :cancel
        next
      end

      # Deploy it.
      if deploy_one(options)
        options[:status] = :success
        hg_tag(options) if options[:tag_it]
      else
        options[:status] = :fail
      end
    end

    # Output the final status of each deployment.
    puts "\nFinal status:"
    @config_options.each do |options|
      pattern = '%s'

      case options[:status]
        when :success
          pattern = '=> %s'
        when :cancel
          pattern = '=/ %s'
        when :fail
          pattern = '=| %s'
      end

      puts pattern % options[:full_path]
    end
  end

  ############################################################################
  private
  ############################################################################

  # Removes the temp files (and folders) that were used
  # to deploy a database.yml file.
  #
  # This function assumes that both the folder holding the file
  # and its parent should be removed.
  # ==== Input
  # [path : String] Path to the temporary file that will be removed.
  # ==== Notes
  # This method is overridden during testing.
  def cleanup_db_yml(path)
    File.delete(path)
    Dir.rmdir(File.dirname(path))
    Dir.rmdir(File.expand_path(File.join(File.dirname(path), '..')))
  end

  # Return the contents of the database.yml file.
  # ==== Output
  # [String] The unabridged contents of the database.yml file.
  # ==== Notes
  # This method is overridden during testing.
  def db_yml_contents
    return File.open(SETTINGS[:rails_db_yml], 'r')
  end

  # Deploys the application using the settings from a single config file.
  #
  # There are no return statements after the rsync is attempted
  # since the rest of the commands should be attempted regardless of rsync's
  # (or any other preceding call's) success.
  # ==== Input
  # [options : Hash] The options from the config file that is being used.
  def deploy_one(options)
    # Commands that will be used.
    commands = {
      :chmod => "sudo chmod %d #{options[:path]} --recursive",
      :stat  => "stat -c %U:%G #{options[:path]}",
      :chown => "sudo chown %s #{options[:path]} --recursive"
    }

    # Set the name of the method to call for all functions.
    method_name = nil
    if deploy_type(options) == :local
      method_name = 'exec_command'
    elsif deploy_type(options) == :remote
      method_name = 'exec_ssh'
    end

    # Get the user:group settings for the folder that we are deploying to.
    user_group, success = self.send(
      method_name, options, commands[:stat], :user_group)
    return unless success

    # chmod to 507 on the destination path.
    chmod = 507
    puts MESSAGES[:chmod] % [options[:full_path], chmod]
    result, success = self.send(
      method_name, options, commands[:chmod] % chmod, :chmod_fail)
    return unless success

    # Get the rsync command.
    rsync = get_rsync(options)

    # Run the rsync command.
    puts MESSAGES[:copying] % options[:full_path]
    result, success = exec_command(options, rsync, :rsync)

    # If rsync was successful and this is a rails app
    # with an environment specified, process the database.yml.
    if success and
        options[:environment] and
        valid_file?(SETTINGS[:rails_db_yml])
      # Get the path to the temp database.yml and create the paths.
      path = File.join('.', 'tmp', 'db', options[:environment], 'database.yml')
      make_path(File.dirname(path))

      # Get the contents of only the settings for the specified environment.
      new_yml = ParseDbYaml.yaml(db_yml_contents, options[:environment])

      puts MESSAGES[:copy_db_yml]

      # Write the file to the temp location.
      write_file(path, new_yml)

      # Build an rsync command to copy the database.yml file.
      rsync = [
        'rsync',
        path,
        File.join(options[:full_path], SETTINGS[:rails_db_yml][2..-1]),
      ].join(' ')

      # Copy the database.yml file.
      result, success = exec_command(options, rsync, :rsync, 'database.yml')

      # Remove the database.yml file and temp folders.
      cleanup_db_yml(path)
    end

    # Set permissions according to specifications.
    chmod = options[:permissions]
    puts MESSAGES[:chmod] % [options[:full_path], chmod]
    result, success_flag = self.send(
      method_name, options, commands[:chmod] % chmod, :chmod_fail)
    success = success_flag unless success_flag

    # Set the owner and group back to the original.
    puts MESSAGES[:chown] % [user_group, options[:full_path]]
    result, success_flag = self.send(
      method_name, options, commands[:chown] % user_group, :chown_fail,
      user_group, options[:full_path])
    success = success_flag unless success_flag

    return success
  end

  # Returns the question that will be asked of the user
  # prior to deployment to a given location.
  # ==== Input
  # [path : String] The path that the project will be deployed to.
  # [user : String] The user that will be used for deployment.
  # [server : String] The server that the project will be deployed to.
  # ==== Output
  # [String] A question asking if the user is sure
  #          about deployment to the specified location.
  def deploy_question(path, user, server)
    if user.empty?
      MESSAGES[:deploy_local] % [SETTINGS[:project], path]
    else
      MESSAGES[:deploy_remote] % [SETTINGS[:project], user, server, path]
    end
  end

  # Indicates whether the deployment is local or remote.
  # ==== Input
  # [options : Hash] The options from the config file that is being used.
  # ==== Output
  # [Symbol] :local or :remote
  def deploy_type(options)
    if options[:user].empty?
      return :local
    else
      return :remote
    end
  end

  # Executes a command using the shell
  # and shows a warning message if the command fails.
  # ==== Input
  # [options : Hash] The current options hash.
  # [command : String] The command to execute.
  # [error_message : Symbol] The message to display from the MESSAGES hash
  #                          if the command is not successful.
  # [*args : Array] These parameters will be passed on in case of a warning.
  #                 They will be used for substitutions.
  # ==== Output
  # [String] The output from the shell command.
  # [Boolean] Whether the command was successful.
  def exec_command(options, command, error_message, *args)
    output, success = backtick_output(command)
    exec_warn(options, error_message, *args) unless success
    return output, success
  end

  # Executes an ssh command
  # and shows a warning message if the command fails.
  # ==== Input
  # [options : Hash] The current options hash.
  # [command : String] The command to execute.
  # [error_message : Symbol] The message to display from the MESSAGES hash
  #                          if the command is not successful.
  # [*args : Array] These parameters will be passed on in case of a warning.
  #                 They will be used for substitutions.
  # ==== Output
  # [String] The output from the ssh command.
  # [Boolean] Whether the command was successful.
  def exec_ssh(options, command, error_message, *args)
    success, output = run_ssh(options, command)
    exec_warn(options, error_message, *args) unless success
    return output, success
  end

  # Displays a message on stderr if any call to a shell or ssh command fails.
  # ==== Input
  # [options : Hash] The current options hash.
  # [message : Symbol] The message to display from the MESSAGES hash.
  # [*args : Array] These parameters will be used for substitutions.
  def exec_warn(options, message, *args)
    args = options[:full_path] if args.empty?
    warn MESSAGES[message] % args
  end

  # Formats the specified date/time as a string.
  # ==== Input
  # [date_time : DateTime] The date/time to convert
  #                        to a properly formatted string.
  # ==== Output
  # [String] The formatted date and time.
  # ==== Examples
  #  format_date(2001, 1, 1, 23, 59, 29) #=> '2001-01-01 23-59-29'
  def format_date(date_time)
		'%d-%s-%s %s-%s-%s' % [
			date_time.year,
			date_time.month.to_s.rjust(2, '0'),
			date_time.day.to_s.rjust(2, '0'),
			date_time.hour.to_s.rjust(2, '0'),
			date_time.minute.to_s.rjust(2, '0'),
			date_time.second.to_s.rjust(2, '0')
		]
  end

  # Returns a formatted date and time.
  # ==== Output
  # [String] The formatted date and time.
  # ==== Notes
  # This method is overridden during testing.
  # ==== Examples
  #  get_date #=> '2001-01-01 23-59-29'
  def get_date
    format_date(DateTime.now)
  end

  # Returns the full path of the current working directory.
  # ==== Output
  # [String] The full path of the current working directory.
  # ==== Notes
  # This method is overridden during testing.
  def get_root
    File.expand_path(File.join(Dir.getwd))
  end

  # Returns the specified message using any arguments for substitutions.
  # ==== Input
  # [message : Symbol] Indicates which templated message to use.
  # [*args : Array] The values to use as replacements in the specified template.
  # ==== Output
  # [String] The message with any necessary substitutions.
  def get_message(message, *args)
    msg = MESSAGES[message] % args
    msg += MESSAGES[:help]
  end

  # Returns the RSync command that will be used.
  # ==== Input
  # [options : Hash] The current options hash.
  # ==== Output
  # [String] The RSync command and all necessary parameters as a string.
  # ==== Notes
  # This method is overridden during testing.
  def get_rsync(options)
    RSync.get_rsync(options[:full_path], options[:environment])
  end

  # Tags the changeset that was deployed.
  # ==== Input
  # [options : Hash] The options from the config file that is being used.
  def hg_tag(options)
    puts MESSAGES[:tagging] % @hg_id
    run_hg "branch #{options[:branch]} --force" if options[:branch]
    run_hg "tag #{options[:tag]} #{get_date} --force"
    run_hg "update #{@hg_id} --clean" if options[:branch]
  end

  # Creates a directory and all of its parent directories.
  # ==== Input
  # [path : String] The path to create.
  # ==== Notes
  # This method is overridden during testing.
  def make_path(path)
    FileUtils.mkdir_p(path)
  end

  # Parses the command line parameters using Trollop.
  def parse_params
    # Set the options and get the valid options that were set.
    @options = Trollop::options @params do
      banner HELP_TEXT
      version Version

      opt :dest, MESSAGES[:destination], :type => :strings
    end

    trollop_die :dest, MESSAGES[:dest_missing] unless
      @options && @options[:dest]
  end

  # Executes an hg command using the shell.
  # ==== Input
  # [command : String] The command to execute (minus 'hg').
  def run_hg(command)
    backtick_output("hg #{command}")
  end

  # Executes an ssh command.
  # ==== Input
  # [options : Hash] The current options hash.
  # [command : String] The ssh command that will be executed.
  # ==== Output
  # [Boolean] Whether the command was executed successfully.
  # [String] The output from the command.
  # ==== Notes
  # This method is overridden during testing.
  def run_ssh(options, command)
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

  # Sets the default values in the hash for the current config file.
  # ==== Input
  # [index : Fixnum] The index of the options hash in the array.
  # [config_file : String] The config file name as specified
  #                        on the command line.
  def set_default_options(index, config_file)
    # Get the config options to set defaults for.
    config = @config_options[index]

    # Set the path variable appropriately, including the extension.
    config[:path] = File.expand_path(config[:path])
    config[:path] = File.join(config[:path], SETTINGS[:project])
    config[:path] += config[:extension].to_s

    # Set the full_path.
    config[:full_path] = config[:path]

    # Prepend user@server: to the full_path if the deployment is remote.
    unless config[:user].empty? or config[:server].empty?
      config[:full_path] =
        "#{config[:user]}@#{config[:server]}:#{config[:path]}"
      config[:tag_it] = true if config[:tag_it].nil?
    end

    # Set defaults for tag, tag-it, and branch, if not set.
    config[:tag] = config_file if config[:tag].empty?
    config[:tag_it] = config[:tag_it].to_b

    # Set the default permissions.
    if config[:permissions].empty?
      config[:permissions] = DEFAULT_OPTIONS[:permissions]
    end
  end

  # Creates a hash based on the settings in a config file
  # and appends that hash to the array of hashes to be processed.
  # ==== Input
  # [stream : StringIO] The contents of the config file.
  # [config : String] The config file that is being processed.
  #
  #                   This parameter is primarily used in warnings.
  # ==== Output
  # [Boolean] Whether the config file is respectable.
  def set_options(stream, config)
    # Initialize the options hash.
    options = {}

    # Loop through the file.
    while line = stream.gets
      # Remove leading spaces, trailing spaces, and anything after a '#'.
      # This should render commented lines as empty lines.
      line.gsub!(/^\s+|#.*|\s+$/, '')

      if line.count('=') == 1
        # Split the line into a key/value pair.
        key, value = line.split('=')

        # Remove leading and trailing spaces from the key.
        key.gsub!(/^\s+|\s+$/, '')

        # Remove leading and trailing spaces from the value.
        value.gsub!(/^\s+|\s+$/, '') unless value.nil?

        # Change -s to _s in the key and downcase it.
        key = key.gsub(/-/, '_').downcase

        if key.match(' ') # ----------------------- # Empty key.
          warn get_message(:na_line, line, config)
          return
        elsif value.nil? or value.match(' ') # ---- # Empty value.
          warn get_message(:na_line, line, config)
          return
        elsif !DEFAULT_OPTIONS.has_key?(key.to_sym) # Invalid key.
          warn get_message(:bad_key, key, config)
          return
        elsif options.has_key?(key.to_sym) # ------ # Duplicate key.
          warn get_message(:dup_key, key, config)
          return
        end

        # Add the key/value pair to the hash if it survived.
        options[key.to_sym] = value

      elsif line.empty?
        # Commented lines should fall in this category.
      else
        # All other cases mean the config file has a problem.
        warn get_message(:na_line, line, config)
        return
      end
    end

    if options.empty? # ----- # Empty options hash.
      warn get_message(:no_settings, config)
      return
    elsif options[:path].nil? # No deployment path specified.
      warn get_message(:no_path, config)
      return
    end

    # Add the hash to the array of hashes.
    @config_options << options

    return true
  end

  # Call Trollop's built in die function passing the parameter and the message.
  # ==== Input
  # [param : Symbol] The parameter that caused the problem.
  # [message : String] The reason execution is being halted.
  def trollop_die(param, message)
    Trollop::die param, message
  end

  # Indicates whether the config file settings are valid.
  # ==== Input
  # [config : String] The path to the config file.
  # ==== Output
  # [Boolean] Whether the config file settings are valid.
  # ==== Notes
  # This method is overridden during testing.
  def valid_config?(config)
    File.open(config, 'r') { |file| set_options(file, config) }
  end

  # Indicates whether the specified path exists as a directory.
  # ==== Input
  # [path : String] The path to check for.
  # ==== Output
  # [Boolean] Whether the path exists as a directory.
  # ==== Notes
  # This method is overridden during testing.
  def valid_dir?(path)
    File.directory?(path)
  end

  # Indicates whether the file exists.
  # ==== Input
  # [file : String] Path to a file (or is it?...).
  # ==== Output
  # [Boolean] Indicates whether the file exists.
  # ==== Notes
  # This method is overridden during testing.
  def valid_file?(file)
    File.file?(file)
  end

  # Validates that the working directory is the repository root.
  # ==== Output
  # [Boolean] Indicates whether the current directory is the root of a repo.
  def valid_hg?
    unless valid_dir?(File.join(get_root, '.hg'))
      warn get_message(:no_repo)
      return
    end

    return true
  end

  # Indicates whether the specified options are valid.
  # ==== Input
  # [config_options : Hash] The options hash that will be evaluated.
  # [file : String] The file that the options were generated from.
  #
  #                 This parameter is primarily used in warnings.
  # ==== Output
  # [Boolean] Whether the options were valid.
  def valid_options?(config_options, file)
    if !config_options[:user].empty? and config_options[:server].empty?
      # Check for a user without a server.
      warn get_message(:no_server, file)
      return
    elsif config_options[:user].empty? and !config_options[:server].empty?
      # Check for a server without a user.
      warn get_message(:no_user, file)
      return
    elsif config_options[:user] and config_options[:server]
      # Check that we can actually access the server.
      check_path = File.expand_path(File.join(config_options[:path], '..'))
      success, out = run_ssh(config_options, "ls #{check_path}")

      unless success
        warn get_message(:bad_ssh, 
          config_options[:user], config_options[:server], check_path, file)
        return
      end
    end

    # Check for outstanding changes to source.
    if config_options[:tag_it] and !@hg_status.empty?
      warn get_message(:check_out, config_options[:path])
      return
    end

    if config_options[:user].empty?
      # Validate a local deployment's path.
      unless valid_dir?(config_options[:full_path])
        warn get_message(:bad_path, config_options[:path], file)
        return
      end
    end

    return true
  end

  # This method ensures that the specified command line parameters are valid.
  #
  # This includes checking that the specified config files exist.
  # ==== Output
  # [Boolean] Whether the command line parameters are valid.
  def valid_params?()
    if @params.count > 0
      warn get_message(:unknown_opt, @params[0])
      return
    end

    @options[:dest].each do |config|
      config = File.join(SETTINGS[:config_path], config)
      unless valid_file?(config)
        warn get_message(:no_config, config) 
        return
      end
    end

    return true
  end

  # Writes a file with the specified contents.
  # ==== Input
  # [file_path : String] The path to the file that will be created/overwritten.
  # [contents : String] The string to use as the contents of the file.
  # ==== Notes
  # This method is overridden during testing.
  def write_file(file_path, contents)
    File.open(file_path, 'w') do |file|
      file.write contents
    end
  end

  # Asks a yes/no question.
  # ==== Input
  # [question : String] The question that will be asked.
  # ==== Output
  # [Boolean] The user's response as a boolean value.
  # ==== Notes
  # This method is overridden during testing.
  def yes?(question)
    agree(question)
  end
end

unless ScriptEnv.testing
  dep = Deploy.new(ARGV)
  dep.deploy()
end
