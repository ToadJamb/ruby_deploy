# This file contains a module which bridges the gap between test code
# and applciation code.

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

# This module is provided to be used as an include in any necessary class.
#
# This serves as a bridge between test code and application code.
module DeploySupport
  # The error format that Trollop uses.
  #
  # Our error messages should use the same format for consistency.
  TROLLOP_MSG = "Error: %s.\nTry --help for help."

  # The error format that Trollop uses for argument errors.
  #
  # Our argument error messages should use the same format for consistency.
  TROLLOP_ARG = TROLLOP_MSG % 'argument %s %s'

  # The id to use as the changeset ID.
  HG_ID = 'c91fb6c87d56'

  # These are things that will be used throughout testing in multiple locations.
  ITEMS = {
    :messages => {
      :help_text => %Q{\
Deploy.rb [OPTIONS]

Deploys the code in the current directory to the specified location.

  Deploy will look for .exclude in the root folder
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
  --dest, -d <s+>:   Specify destinations - multiple destinations may be
                     specified at once. Each destination corresponds to a
                     similarly named file in ~/.deploy.
    --version, -v:   Print version and exit
       --help, -h:   Show this message
}, # :help_text

      :version        => 'Deploy %d.%d.%d' % [
                         Deploy::Version::MAJOR,
                         Deploy::Version::MINOR,
                         Deploy::Version::REVISION],

      # Trollop messages.
      :required_flag  => TROLLOP_ARG % ['%s', 'is required'],
      :unknown_flag   => TROLLOP_MSG % "unknown argument '%s'",
      :duplicate_flag => TROLLOP_MSG % "option '%s' specified multiple times",
      :missing_option => TROLLOP_MSG % "option '%s' needs a parameter",
      :unknown_option => TROLLOP_MSG % "unknown option '%s'",

      # Error messages prior to deployment.
      :no_config      => TROLLOP_MSG % "Config file '%s' not found",
      :no_settings    => TROLLOP_MSG % "'%s' contains no valid settings",
      :na_line        => TROLLOP_MSG % "'%s' is an invalid setting in '%s'",
      :bad_key        => TROLLOP_MSG % "'%s' is an unknown key in '%s'",
      :dup_key        => TROLLOP_MSG % "'%s' is a duplicate key in '%s'",
      :no_server      => TROLLOP_MSG % ["A user without a server " +
                                        "has been specified in '%s'"],
      :no_user        => TROLLOP_MSG % ["A server without a user " +
                                        "has been specified in '%s'"],
      :bad_remote     => TROLLOP_MSG % ["'%s@%s:%s' specified in %s " +
                                        "is an invalid path " +
                                        "or the user does not have " +
                                        "appropriate privileges"],
      :bad_path       => TROLLOP_MSG % ["'%s' specified in %s " +
                                        "is an invalid path " +
                                        "or the user does not have " +
                                        "appropriate privileges"],
      :no_path        => TROLLOP_MSG % "No path was specified in '%s'",
      :check_out      => TROLLOP_MSG % ["There are pending changes. " +
                                        "The current settings do not allow " +
                                        "uncommitted changes to be " +
                                        "pushed to '%s'"],
      :no_repo        => TROLLOP_MSG % ["The current working directory does " +
                                        "not appear to be the project root"],

      # Error messages during deployment.
      :user_group     => "user:group could not be determined for %s.",
      :chmod_fail     => "chmod was unsuccessful on %s.",
      :rsync_fail     => "RSync command failed for %s.",
      :chown_fail     => "Resetting owner to %s was unsuccessful for %s.",

      # Status messages.
      :chmod          => "Changing permissions on %s to %d...",
      :copying        => "Copying files to %s...",
      :chown          => "Resetting owner to %s on %s...",
      :tagging        => "Tagging changeset %s...",
      :copy_db_yml    => "Copying database.yml...",

    }, # :messages

    :branch => {
      :named   => 'named_branch',
      :default => 'default',
    }, # :branch

    :dest => {
      :base      => [
                      'local_default_one',
                      'local_default_two',
                      'remote_default_one',
                      'remote_default_two'
      ], # :base
      :no_config => ['abcdef', 'ghijkl'],
    }, # :dest

    :environment => {
      :dev  => 'development',
      :test => 'test',
      :prod => 'production',
    }, # :env

    :extension => {
      :bad  => '.bad',
    }, # :extension

    :flag => {
      :help    => ['--help', '-h'],
      :version => ['--version', '-v'],
      :dest    => ['--dest', '-d']
    }, # :flag

    :hg_log => [
                "changeset:   34:#{HG_ID}",
                'branch:      v1_dev',
                'tag:         tip',
                'user:        Travis Herrick <tthetoad@gmail.com>',
                'date:        Sun Feb 13 21:50:27 2011 -0500',
                'summary:     Made some changes.',
    ], # :hg_log

    :function => {
      :tag    => 'hg_tag',
      :hg     => 'run_hg',
      :db_yml => 'db_yml_contents',
    }, # :function

    :owner_group => 'owner:group',

    :permission => {
      :r_xr_xr_x => 555,
      :r_x___rwx => 507,
    }, # :perm

    :path => {
      :config            => File.expand_path('~/.deploy'),
      :db_yml_tmp_folder => File.join('.', 'tmp', 'db', '%s'),
      :db_yml_tmp_file   => File.join('.', 'tmp', 'db', '%s', 'database.yml'),
    }, # :path

    :project => {
      :good        => 'good_project',
      :uncommitted => 'uncommitted',
      :no_repo     => 'no_repo',
      :rails       => 'rails_project',
    }, # :project

    :server => {
      :allow => 'allow_server',
      :deny  => 'deny_server',
    }, # :server

    :tag => {
      :ss => 'SuperSaver',
    }, # :tag

    :tag_date    => '2011-01-01 17-09-59',

    :user => {
      :allow => 'allow_user',
      :deny  => 'deny_user',
    }, # :user

  } # ITEMS

  # Returns the content of a database.yml file.
  #
  # Since the parser has been tested outside of the main application,
  # we may simply return any version of a full database.yml file.
  # ==== Output
  # [String] The contents of a full database.yml file.
  def db_yml
    DbYaml::COMPLEX
  end

  # Returns a path with a leading '/'.
  # ==== Input
  # [path : String : ''] The path to append a leading '/' to.
  # ==== Output
  # [String] <tt>path</tt> with a leading '/'
  #          or an empty string if <tt>path</tt> was empty.
  # ==== Examples
  #  get_file_path         #=> ''
  #  get_file_path 'blah'  #=> '/blah'
  #  get_file_path '/blah' #=> '/blah'
  def get_file_path(path = '')
    unless path.strip.empty?
      path.strip!
      path = '/' + path unless path.match(%r|^/|)
    end

    return path
  end

  # Returns the local path in a config file.
  # ==== Input
  # [path : String : ''] Typically the name of a file,
  #                      but it could be a path itself.
  # ==== Output
  # [String] A value that is the local path as specified in a config file.
  # ==== Examples
  #  local_path         #=> /good/local/path
  #  local_path 'blah'  #=> /good/local/blah/path
  #  local_path '/blah' #=> /good/local/blah/path
  def local_path(path = '')
    "/good/local#{get_file_path(path)}/path"
  end

  # Black magic.
  #
  # This is used for the following purposes:
  # * To return elements from the ITEMS hash.
  # * To return messages (from the ITEMS hash),
  #   possibly with string substitutions.
  # ==== Input
  # [method : Symbol] The method that was called.
  # [*args : Array] Any arguments that were passed in.
  # [&block : Block] A block, if specified.
  # ==== Output
  # [Any] It depends on the method.
  def method_missing(method, *args, &block)
    # Check if the method is a key in the ITEMS hash.
    if ITEMS.has_key? method
      # Initialize the variable that will hold the return value.
      value = nil

      if args.nil? or args.count == 0
        # If no arguments have been specified, return the element as is.
        value = ITEMS[method]
      elsif ITEMS[method][args[0]].is_a?(String) &&
          ITEMS[method][args[0]].index('%s')
        # The first parameter is the message.
        msg = args.shift

        if args.count == 0
          # If no arguments are left, return the message.
          value = ITEMS[method][msg]
        else
          # Use any remaining arguments to make substitutions.
          value = ITEMS[method][msg] % args
        end
      else # All other methods - which are expected to have one parameter.
        # Get the element to return.
        item = args[0].to_sym

        # Return the indicated element.
        value = ITEMS[method][item]

        # Dynamically add configuration files.
        if value.nil? and [:dest, :function].index(method)
          value = item.to_s
        end
      end

      # Strip all trailing line feeds from strings.
      value.gsub!(/\n*\z/, '') if value.is_a?(String)

      return value
    else
      super
    end
  end

  # Returns an argument hash by turning the given hash into flags and arguments.
  # ==== Input
  # [options : Hash : {}] The hash that will be
  #                       turned into command line parameters.
  # ==== Output
  # [Array] An array that simulates the ARGV array.
  def parameters(options = {})
    # Place the options hash in a local variable.
    argv = []

    # Loop through each option, adding a flag and argument for each.
    # This will reflect the desired parameters to send to the main class.
    options.each do |key, value|
      argv << flag(key)[0]
      argv << send(key, value)
    end

    # Return the arguments array.
    return argv.flatten
  end

  # Returns the remote path in a config file.
  # ==== Input
  # [path : String : ''] Typically the name of a file,
  #                      but it could be a path itself.
  # ==== Output
  # [String] A value that is the remote path as specified in a config file.
  # ==== Examples
  #  remote_path         #=> /good/remote/path
  #  remote_path 'blah'  #=> /good/remote/blah/path
  #  remote_path '/blah' #=> /good/remote/blah/path
  def remote_path(path = '')
    "/good/remote#{get_file_path(path)}/path"
  end

  # Indicates which methods the class will respond to.
  # ==== Input
  # [method : Symbol] The method to check for.
  # [include_private : Boolean] Whether private methods should be checked.
  # ==== Output
  # [Boolean] Whether the object will respond to the specified method.
  def respond_to?(method, include_private = false)
    if ITEMS.has_key? method
      super
    else
      return true
    end
  end

  # This method replicates running a command externally.
  # This may be either via backticks (shell) or via ssh.
  # ==== Input
  # [command : String] The command that will be 'run'.
  # [options : Hash] The options hash
  #                  (this may only available for ssh commands).
  # [project : String] The name of the project for which
  #                    the application is being 'run'.
  # ==== Output
  # [Boolean] Indicates success.
  # [String] Returns output.
  # ==== Examples
  #  run_external('hg_status', {}, 'uncommitted') #=> [true, 'M test/lib/deploy.rb']
  def run_external(command, options, project)
    case command
      # hg status
      when 'hg status'
        case project
          when 'uncommitted' then return true, "M test/lib/deploy.rb"
          when 'good_project', 'rails_project' then return true, ''
        end

      # hg id
      when 'hg id' then return true, "#{HG_ID} (v1_dev) tip"

      # hg log --rev c91fb6c87d56
      when "hg log --rev #{HG_ID}"
        out = hg_log
        return true, out.join("\n").chomp

      # hg branch
      when /^hg branch \w+ --force$/
        branch = command.gsub(/^hg branch | --force$/, '')
        return true, "marked working directory as branch #{branch}"

      # hg tag
      when /^hg tag \w+ \d{4}-\d\d-\d\d \d\d-\d\d-\d\d --force$/
        tag = command.gsub(
          /^hg tag | \d{4}-\d\d-\d\d \d\d-\d\d-\d\d --force$/, '')
        return true, ''

      # hg update
      when "hg update #{HG_ID} --clean"
        return true,
          '0 files updated, 0 files merged, 0 files removed, 0 files unresolved'

      # stat -c %U:%G
      when /^stat -c %U:%G /
        path = command.gsub(/.*%G /, '')

        case path
          when %r|/\w+?_status_fail/path/\w+?$|, %r|/remote_bad_extension|
            return false,
              "stat: cannot stat `#{path}': Permission denied"
        end

        return true, owner_group

      # sudo chmod 507
      when /^sudo chmod 507 /
        path = command.match(%r|/.*/path/\w+|).to_s
        case path
          when %r|/\w+?_chmod_initial_fail/|
            output = "chmod: \nchanging permissions of `#{path}'\n" +
              ": Operation not permitted"
            return false, output
        end

        return true, ''

      # sudo chmod 500
      when /^sudo chmod \d{3} /
        path = command.match(%r|/.*/path/\w+|).to_s
        case path
          when %r|/\w+?_chmod_final_fail/|
            output = "chmod: \nchanging permissions of `#{path}'\n" +
              ": Operation not permitted"
            return false, output
        end

        return true, ''

      # rsync
      when /^rsync /
        path = command.gsub(/^rsync .+? /, '')

        fail = [
          "rsync: \nmkdir \"/var/www/deploy\" failed\n: Permission denied (13)",
          "rsync error: error in file IO (code 11) at main.c(595) [Receiver=3.0.7]",
          "rsync: connection unexpectedly closed (9 bytes received so far) [sender]",
          "rsync error: error in rsync protocol data stream (code 12) at io.c(601) [sender=3.0.7]",
        ]

        case path
          when %r|rsync_db_fail|
            return false, fail.join("\n") unless command.match(/rsync \.\/ /)
          when %r|\w+?_rsync_fail/|
            return false, fail.join("\n")
        end
        return true, ''

      # ls
      when /^ls /
        path = command[3..-1]
        case path
          when %r|\.bad$|, %r|/remote_bad_\w*_?path/|
            return false,
              "ls: \ncannot access #{path}\n: No such file or directory"
        end
        return true, "bin\nboot\nmedia"

      # sudo chown
      when /^sudo chown /
        path = command.match(%r|/.*/path/\w+|).to_s
        case path
          when %r|/\w+?_chown_fail/|
            output = "chown: \nchanging ownership of `#{path}'\n" +
              ": Operation not permitted"
            return false, output
        end

        return true, ''

    end

    # Raise an error if the command was not handled.
    raise ArgumentError.new("'#{command}' is an invalid command " +
      "for #{project}.")
  end
end
