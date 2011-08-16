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

require File.join(File.dirname(File.expand_path(__FILE__)), 'requires')

class DeployTest < Test::Unit::TestCase
  include DeployResult

  def initialize(*args)
    init_object(flag(:help)[0])
    expose_stack
    super
  end

  def setup
    super
    set_project project(:good)
  end

  ############################################################################
  # Trollop tests - Trollop should handle these internally.
  ############################################################################

  def test_help_text
    flag(:help).each do |argv|
      create(*argv)
      assert_equal([messages(:help_text), ''], real_finis)
      assert_dead
    end
  end

  def test_version_text
    flag(:version).each do |argv|
      create(*argv)
      assert_equal([messages(:version), ''], real_finis)
      assert_dead
    end
  end

  def test_unknown_flags
    # Check case.
    ['--hElP', '-H', '--vErSiOn', '-V', '--abc'].each do |argv|
      create(*argv)
      assert_equal(['', messages(:unknown_flag, argv)], real_finis)
      assert_dead
    end

    # Check a single -. 
    ['-help', '-version'].each do |argv|
      create(*argv)
      assert_equal(['', messages(:unknown_flag, '-' + argv[2])], real_finis)
      assert_dead
    end
  end

  def test_duplicate_flags
    create(*flag(:version))
    assert_equal(['', messages(:duplicate_flag, flag(:version)[1])], real_finis)
    assert_dead
  end

  def test_destination_flag_without_options
    flag(:dest).each do |argv|
      create(*argv)
      assert_equal(['', messages(:missing_option, argv)], real_finis)
      assert_dead
    end
  end

  def test_unknown_options
    argv = ['abcv', 'abcd efgh', flag(:dest)[0], 'abc']
    execute(*argv)
    assert_equal(['', messages(:unknown_option, argv[0])], real_finis)
  end

  ############################################################################
  # Trollop-assisted items - Trollop::die is invoked in these tests.
  ############################################################################

  def test_no_arguments
    create
    assert_equal(['', messages(:required_flag, flag(:dest)[0])], real_finis)
    assert_dead
  end

  ############################################################################
  # Configuration file errors
  ############################################################################

  def test_no_config
    argv = parameters(:dest => :no_config)
    execute(*argv)

    assert_equal(
      ['', messages(:no_config, File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_empty_config
    argv = parameters(:dest => :empty)
    execute(*argv)
    assert_equal(
      ['', messages(:no_settings, File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_config_with_only_comments
    argv = parameters(:dest => :comments)
    execute(*argv)
    assert_equal(
      ['', messages(:no_settings, File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_multiple_equal_signs_on_a_single_line_in_config
    argv = parameters(:dest => :multi_eq)
    execute(*argv)
    assert_equal(
      ['', messages(
        :na_line, 'key = value = something', File.join(path(:config), argv[1]))
      ],
      real_finis)
  end

  def test_space_in_key_in_config
    argv = parameters(:dest => :key_space)
    execute(*argv)
    assert_equal(['',
      messages(:na_line, 'the key = blah', File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_space_in_value_in_config
    argv = parameters(:dest => :value_space)
    execute(*argv)
    assert_equal(
      ['', messages(
        :na_line, 'key = value space', File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_unrecognized_key
    argv = parameters(:dest => :bad_key)
    execute(*argv)
    assert_equal(
      ['', messages(:bad_key, 'bad_key', File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_duplicate_key
    argv = parameters(:dest => :dup_key)
    execute(*argv)
    assert_equal(
      ['', messages(:dup_key, 'tag_it', File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_server_but_no_user
    argv = parameters(:dest => :no_user)
    execute(*argv)
    assert_equal(
      ['', messages(:no_user, File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_user_but_no_server
    argv = parameters(:dest => :no_server)
    execute(*argv)
    assert_equal(
      ['', messages(:no_server, File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_invalid_credentials_for_remote
    argv = parameters(:dest => :remote_bad_credentials)
    execute(*argv)
    assert_equal(
      ['', messages(
          :bad_remote, user(:deny), server(:deny), remote_path,
          File.join(path(:config), argv[1])
        )
      ],
      real_finis)
  end

  def test_invalid_path
    argv = parameters(:dest => :remote_bad_path)
    execute(*argv)
    assert_equal(
      ['', messages(:bad_remote,
          user(:allow), server(:allow), remote_path(argv[1]),
          File.join(path(:config), argv[1])
        )
      ],
      real_finis)

    argv = parameters(:dest => :local_bad_path)
    execute(*argv)
    assert_equal(
      ['', messages(:bad_path,
          File.join(local_path(argv[1]), project(:good)),
          File.join(path(:config), argv[1])
        )
      ],
      real_finis)
  end

  def test_bad_extension
    argv = parameters(:dest => :local_bad_extension)
    execute(*argv)
    assert_equal(
      ['', messages(:bad_path,
          File.join(local_path(argv[1]), project(:good) + extension(:bad)),
          File.join(path(:config), argv[1])
        )
      ],
      real_finis)

    # This actually won't fail until retrieving the user:group settings
    # from the server.
    argv = parameters(:dest => :remote_bad_extension)
    execute(*argv)
    assert_equal finis(*argv), real_finis
  end

  def test_no_path
    argv = parameters(:dest => :local_no_path)
    execute(*argv)
    assert_equal(
      ['', messages(:no_path, File.join(path(:config), argv[1]))],
      real_finis)

    argv = parameters(:dest => :remote_no_path)
    execute(*argv)
    assert_equal(
      ['', messages(:no_path, File.join(path(:config), argv[1]))],
      real_finis)
  end

  def test_empty_key
    [:empty_key, :zero_key].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal(
        ['', messages(:bad_key, '', File.join(path(:config), argv[1]))],
        real_finis)
    end
  end

  def test_empty_value
    [:empty_value, :zero_value, :zero_value_comment].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal(
        ['', messages(:na_line, 'path =', File.join(path(:config), argv[1]))],
        real_finis)
    end
  end

  ############################################################################
  # Test execution - Success
  ############################################################################

  def test_base_settings
    argv = parameters(:dest => :base)
    execute(*argv)
    assert_equal finis(*argv), real_finis

    assert_method function(:tag)

    assert_not_method function(:db_yml)
    assert_not_method function(:get_yml)
    assert_not_method function(:write_file)
    assert_not_method function(:make_path)

    dest(:base).each do |config|
      next unless config =~ /_?remote_?/

      options = config_options(config)

      assert_trace_args function(:tag), options

      if options[:branch]
        assert_trace_args function(:hg), "branch #{options[:branch]} --force"
        assert_trace_args function(:hg), "update #{HG_ID} --clean"
      end

      assert_trace_args function(:hg),
        "tag \"#{options[:tag]} #{tag_date}\" --force"
    end
  end

  def test_rails
    set_project project(:rails)
    argv = parameters(:dest => :local_rails_project)
    execute(*argv)
    assert_equal finis(*argv), real_finis

    options = config_options(argv[1])

    assert_method function(:db_yml)
    assert_trace_args(
      function(:make_path), path(:db_yml_tmp_folder, options[:environment]))
    assert_trace_args(function(:write_file),
      path(:db_yml_tmp_file, options[:environment]),
      DbYaml.parse_yaml("basic_#{options[:environment]}".to_sym))
    assert_trace_args(
      function(:cleanup_db_yml), path(:db_yml_tmp_file, options[:environment]))
  end

  ############################################################################
  # Test execution - Failure
  ############################################################################

  def test_rails_db_yml_rsync_fail
    set_project project(:rails)
    argv = parameters(:dest => :local_rails_rsync_db_fail)
    execute(*argv)
    assert_equal finis(*argv), real_finis

    options = config_options(argv[1])

    assert_method function(:db_yml)
    assert_trace_args(
      function(:make_path), path(:db_yml_tmp_folder, options[:environment]))
    assert_trace_args(function(:write_file),
      path(:db_yml_tmp_file, options[:environment]),
      DbYaml.parse_yaml("basic_#{options[:environment]}".to_sym))
    assert_trace_args(
      function(:cleanup_db_yml), path(:db_yml_tmp_file, options[:environment]))
  end

  def test_user_group_status_failure
    [:local_status_fail, :remote_status_fail].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal finis(*argv), real_finis
    end
  end

  def test_chmod_initial_fail
    [:local_chmod_initial_fail, :remote_chmod_initial_fail].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal finis(*argv), real_finis
    end
  end

  def test_rsync_fail
    [:local_rsync_fail, :remote_rsync_fail].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal finis(*argv), real_finis
    end
  end

  def test_chmod_final_fail
    [:local_chmod_final_fail,
    :remote_chmod_final_fail].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal finis(*argv), real_finis
    end
  end

  def test_chown_fail
    [:local_chown_fail,
    :remote_chown_fail].each do |config|
      argv = parameters(:dest => config)
      execute(*argv)
      assert_equal finis(*argv), real_finis
    end
  end

  ############################################################################
  # Test individual configuration settings
  ############################################################################

  def test_local_permission_setting
    argv = parameters(:dest => :permission_setting)
    execute(*argv)
    assert_equal finis(*argv), real_finis
  end

  def test_specified_tag
    argv = parameters(:dest => :tag_superserver_remote)
    execute(*argv)
    assert_equal finis(*argv), real_finis

    options = config_options(argv[1])

    assert_trace_args function(:hg),
      "tag \"#{options[:tag]} #{tag_date}\" --force"
  end

  def test_specified_branch_name
    argv = parameters(:dest => :branch_named_branch_remote)
    execute(*argv)
    assert_equal finis(*argv), real_finis
    assert_trace_args function(:hg), "branch #{branch(:named)} --force"
  end

  def test_tag_it
    argv = parameters(:dest => :local_tag_it_default)
    execute(*argv)
    assert_not_method function(:tag)
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :local_tag_it_true)
    execute(*argv)
    assert_trace_args function(:tag), config_options(argv[1])
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :local_tag_it_false)
    execute(*argv)
    assert_not_method function(:tag)
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :remote_tag_it_default)
    execute(*argv)
    assert_trace_args function(:tag), config_options(argv[1])
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :remote_tag_it_true)
    execute(*argv)
    assert_trace_args function(:tag), config_options(argv[1])
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :remote_tag_it_false)
    execute(*argv)
    assert_not_method function(:tag)
    assert_equal finis(*argv), real_finis

    # The rest of the tests will use the uncommitted project.
    set_project project(:uncommitted)

    argv = parameters(:dest => :local_tag_it_default)
    execute(*argv)
    assert_not_method function(:tag)
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :local_tag_it_true)
    execute(*argv)
    assert_equal(
      ['', messages(:check_out,
      File.join(local_path, project(:uncommitted)))],
      real_finis)

    argv = parameters(:dest => :local_tag_it_false)
    execute(*argv)
    assert_not_method function(:tag)
    assert_equal finis(*argv), real_finis

    argv = parameters(:dest => :remote_tag_it_default)
    execute(*argv)
    assert_equal(
      ['', messages(:check_out,
      File.join(remote_path(argv[1]), project(:uncommitted)))],
      real_finis)

    argv = parameters(:dest => :remote_tag_it_true)
    execute(*argv)
    assert_equal(
      ['', messages(:check_out,
      File.join(remote_path, project(:uncommitted)))],
      real_finis)

    argv = parameters(:dest => :remote_tag_it_false)
    execute(*argv)
    assert_not_method function(:tag)
    assert_equal finis(*argv), real_finis
  end

  ############################################################################
  # Miscellaneous other tests
  ############################################################################

  def test_default_config_path
    # If this breaks (or needs to be updated), the help text
    # needs to be updated both in this test and in the main class
    # that is being tested.
    assert_equal path(:config), @class::SETTINGS[:config_path]
  end

  def test_no_repo
    set_project project(:no_repo)
    argv = parameters(:dest => :local_no_repo)
    execute(*argv)
    assert_equal(['', messages(:no_repo)], real_finis)
  end

  def test_cancel_deploy
    argv = parameters(:dest => :local_deploy_cancel)
    execute(*argv)
    assert_equal finis(*argv), real_finis
  end

  ############################################################################
  private
  ############################################################################

  def create(*args)
    reset_io
    reset_trace
    reset_app_state
    wrap_output { @obj = @class.new(args) }
  end

  def execute(*args)
    create(*args)
    assert_alive
    wrap_output { @obj.deploy }
  end
end
