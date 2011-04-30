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

class BacktickTextTest < Test::Unit::TestCase
  def setup
    @obj = Object.new
    @obj.extend(BacktickText)

    # Setting $stderr to STDERR does not work due to the way
    # STDERR was being redirected (or something).
    @stdout_inspect = $stdout.inspect
    @stderr_inspect = $stderr.inspect
  end

  def teardown
    assert_equal(@stdout_inspect, $stdout.inspect)
    assert_equal(@stderr_inspect, $stderr.inspect)
  end

  def test_backticktext_stdout
    user = File.basename(File.expand_path('~'))
    assert @obj.backtick_output('ls ~/..').index(user) > -1,
      "'ls ~/..' does not appear to include " +
      "the current user's folder (#{user})."

    output, success = @obj.backtick_output('ls ~/..')
    assert_equal(true, success, "ls ~/.. was not successful.")
  end

  def test_backticktext_stderr
    assert_equal [
        'ls: cannot access giggidygiggidy: No such file or directory',
        false
      ],
      @obj.backtick_output('ls giggidygiggidy')
  end
end
