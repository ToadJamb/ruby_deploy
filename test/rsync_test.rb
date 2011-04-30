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

class RSyncTest < Test::Unit::TestCase
  def setup
    @path = nil
    @key = nil
    @env = nil
  end

  def test_default
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_env_include
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_env_include
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_exclude_env_include
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_exclude_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_env_include_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_exclude_env_include
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_exclude_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_env_include_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_exclude_env_include_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_include_exclude_env_include_env_exclude
    set_vars(__method__)
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  def test_env_symbol
    set_vars(__method__)
    @env = :env
    result = @class.get_rsync(@path, @env)
    assert_equal get_rsync(@key), result
  end

  private
  def set_vars(method)
    @key = method[5..-1].to_sym
    @path = '/' + @key.to_s.gsub(/_/, '/')
    @env = 'env' if method =~ /_env_/
  end

  def get_rsync(key)
    result = []
    result << RSYNC[:base]
    result << RSYNC[key] if RSYNC[key]
    result << './'
    result << @path

    result.join(' ')
  end

  RSYNC = {
    :base => [
      'rsync',
      '--recursive',
      '--delete',
      '--delete-excluded',
    ],
    :exclude => [
      '--exclude-from=exclude.exclude',
    ],
    :include => [
      '--include-from=include.include',
    ],
    :include_exclude => [
      '--include-from=include_exclude.include',
      '--exclude-from=include_exclude.exclude',
    ],
    :env_exclude => [
      '--exclude-from=env_exclude.env.exclude',
    ],
    :env_include => [
      '--include-from=env_include.env.include',
    ],
    :include_env_include => [
      '--include-from=include_env_include.include',
      '--include-from=include_env_include.env.include',
    ],
    :include_env_exclude => [
      '--include-from=include_env_exclude.include',
      '--exclude-from=include_env_exclude.env.exclude',
    ],
    :exclude_env_include => [
      '--include-from=exclude_env_include.env.include',
      '--exclude-from=exclude_env_include.exclude',
    ],
    :exclude_env_exclude => [
      '--exclude-from=exclude_env_exclude.exclude',
      '--exclude-from=exclude_env_exclude.env.exclude',
    ],
    :env_include_env_exclude => [
      '--include-from=env_include_env_exclude.env.include',
      '--exclude-from=env_include_env_exclude.env.exclude',
    ],
    :include_exclude_env_include => [
      '--include-from=include_exclude_env_include.include',
      '--include-from=include_exclude_env_include.env.include',
      '--exclude-from=include_exclude_env_include.exclude',
    ],
    :include_exclude_env_exclude => [
      '--include-from=include_exclude_env_exclude.include',
      '--exclude-from=include_exclude_env_exclude.exclude',
      '--exclude-from=include_exclude_env_exclude.env.exclude',
    ],
    :include_env_include_env_exclude => [
      '--include-from=include_env_include_env_exclude.include',
      '--include-from=include_env_include_env_exclude.env.include',
      '--exclude-from=include_env_include_env_exclude.env.exclude',
    ],
    :exclude_env_include_env_exclude => [
      '--include-from=exclude_env_include_env_exclude.env.include',
      '--exclude-from=exclude_env_include_env_exclude.exclude',
      '--exclude-from=exclude_env_include_env_exclude.env.exclude',
    ],
    :include_exclude_env_include_env_exclude => [
      '--include-from=include_exclude_env_include_env_exclude.include',
      '--include-from=include_exclude_env_include_env_exclude.env.include',
      '--exclude-from=include_exclude_env_include_env_exclude.exclude',
      '--exclude-from=include_exclude_env_include_env_exclude.env.exclude',
    ],
    :env_symbol => [
      '--include-from=env_symbol.include',
      '--include-from=env_symbol.env.include',
    ],
  }
end
