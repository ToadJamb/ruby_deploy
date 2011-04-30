# This file contains code to generate config files for tests.

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

# This class is responsible for building config files for tests.
class BuildConfig
  include DeploySupport

  # Contains the contents of the specified config file as a string.
  attr_reader :contents

  # The resulting options hash.
  attr_reader :options

  # Default config file options.
  #
  # Only keys in this list are allowed to be used within this class.
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

    :full_path   => nil,
    :status      => nil,

    :bad_key     => nil,
  }

  # Constructor.
  # ==== Input
  # [config : String] The name of the config file.
  # [project : String] The name of the project that the config file is for.
  def initialize(config, project)
    @file = File.basename(config)
    @project = project || projects(:good)
    @options = {}
    @contents = nil
    build_config
    set_options
  end

  ############################################################################
  private
  ############################################################################

  # Builds the config file as a string from the specified options.
  # ==== Input
  # [options : Hash] The hash that will be used
  #                  to create the config file string.
  # ==== Output
  # [Array] An array containing strings of key/value pairs formed from the hash.
  #
  #         There should be one entry in the array for each key/value pair.
  def build(options = {})
    @options = options

    contents = []

    options.each do |key, value|
      contents << key.to_s.gsub(/_/, '-') + ' = ' + value.to_s
    end

    contents
  end

  # Builds the config file as a string.
  # ==== Output
  # [String] The contents of the config file as a single string.
  def build_config
    contents = []
    options = {}

    case @file
      when 'comments'
        contents << '#' * 80
        contents << '# Required settings:     '
        contents << '#' * 80
        contents << '#' + (' ' * 78) + '#'
        contents << '#Other stuff'
        contents << "#user = #{user(:allow)}"
        contents << "#server = #{server(:allow)}"
      when 'dup_key'
        contents << 'tag-it = val1'
        contents << 'server = val2'
        contents << 'tag_it = val3'
      when 'multi_eq'
        contents << 'key = value = something'
      when 'empty_key'
        contents << '  = val1'
      when 'zero_key'
        contents << '= val1'
      when 'empty_value'
        contents << 'path = '
      when 'zero_value'
        contents << 'path ='
      when 'zero_value_comment'
        contents << 'path =#something'
      when 'key_space'
        contents << 'the key = blah'
      when 'value_space'
        contents << 'key = value space'
      when 'bad_key'
        contents = build(:bad_key => 'blah')
      when 'no_user'
        contents = build(:server => server(:allow), :path => remote_path)
      when 'no_server'
        contents = build(:user => user(:allow), :path => remote_path)
      when 'remote_bad_credentials'
        contents = build(:user => user(:deny), :server => server(:deny),
          :path => remote_path)
      when 'local_no_path'
        contents = build(:tag_it => false)
      when 'remote_no_path'
        contents = build(:user => user(:allow), :server => server(:allow))
      when 'remote_bad_extension'
        contents = build_ssh({:extension => extension(:bad)}, @file)
      when 'local_bad_extension'
        contents = build_local({:extension => extension(:bad)}, @file)
      when 'local_tag_it_true'
        contents = build_local(:tag_it => true)
      when 'local_tag_it_false'
        contents = build_local(:tag_it => false)
      when 'remote_tag_it_true'
        contents = build_ssh(:tag_it => true)
      when 'remote_tag_it_false'
        contents = build_ssh(:tag_it => false)
      when 'branch_named_branch_remote'
        contents = build_ssh(:branch => branch(:named))
      when 'tag_superserver_remote'
        contents = build_ssh(:tag => tag(:ss))
      when 'permission_setting'
        contents = build_local(:permissions => permission(:r_xr_xr_x))
      when 'empty'
      when /_?remote_?/
        if @project =~ /_?rails_?/
          options = {:environment => environment(:prod)}
        end
        contents = build_ssh(options, @file)
      when /_?local_?/
        if @project =~ /_?rails_?/
          options = {:environment => environment(:dev)}
        end
        contents = build_local(options, @file)
    end

    @contents = StringIO.new(contents.join("\n"))
  end

  # Build a config file using a local base path.
  # ==== Input
  # [options : Hash : {}] Hash that will be passed on to build the config file.
  # [path : String : ''] A string that will be included in the path.
  def build_local(options = {}, path = '')
    options[:path] = local_path path

    build options
  end

  # Build a config file using basic remote settings.
  # === Input
  # [options : Hash] Hash that will be passed on to build the config file.
  # [path : String : ''] A string that will be included in the path.
  def build_ssh(options = {}, path = '')
    options[:user]   = user :allow
    options[:server] = server :allow
    options[:path]   = remote_path path

    build options
  end

  # Checks to ensure that all option keys
  # are contained in the DEFAULT_OPTIONS hash.
  def check_keys
    @options.keys.each do |key|
      if DEFAULT_OPTIONS.keys.index(key).nil?
        raise "#{key} is not a valid configuration option."
      end
    end
  end

  # Sets the options hash.
  # This includes the computed hash values.
  def set_options
    # Construct the path.
    @options[:path] =
      File.join(@options[:path].to_s, @project.to_s + @options[:extension].to_s)

    # Set the full_path and tag_it options appropriately
    # based on whether the deployment is local or remote.
    unless @options[:user].nil? or @options[:user].empty? or
        @options[:server].nil? or @options[:server].empty?
      @options[:full_path] =
        "#{@options[:user]}@#{@options[:server]}:#{@options[:path]}"
      @options[:tag_it] = true if @options[:tag_it].nil?
    else
      @options[:full_path] = @options[:path]
      @options[:tag_it] = @options[:tag_it].to_s.to_b
    end

    # Set the tag option.
    @options[:tag] = @file if @options[:tag].empty? and @options[:tag_it]

    # Set the permissions option.
    if @options[:permissions].nil?
      @options[:permissions] = DEFAULT_OPTIONS[:permissions]
    end

    # Set the status for this config file.
    case @file
      when /_fail$/, /remote_bad_extension/
        @options[:status] = :fail
      when /_cancel$/
        @options[:status] = :cancel
      else
        @options[:status] = :success
    end

    # Check to ensure that all of the keys match allowed values.
    check_keys
  end
end
