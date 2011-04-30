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

class ParseDbYamlTest < Test::Unit::TestCase
  def test_basic_db_yaml
    assert_equal get_yaml(:basic_development),
      @class.yaml(StringIO.new(get_yaml(:basic)), :development)

    assert_equal get_yaml(:basic_test),
      @class.yaml(StringIO.new(get_yaml(:basic)), :test)

    assert_equal get_yaml(:basic_production),
      @class.yaml(StringIO.new(get_yaml(:basic)), :production)
  end

  def test_complex_db_yaml
    assert_equal get_yaml(:basic_development),
      @class.yaml(StringIO.new(get_yaml(:complex)), :development)

    assert_equal get_yaml(:basic_test),
      @class.yaml(StringIO.new(get_yaml(:complex)), :test)

    assert_equal get_yaml(:basic_production),
      @class.yaml(StringIO.new(get_yaml(:complex)), :production)
  end

  private
  def get_yaml(db_yaml)
    DbYaml.parse_yaml(db_yaml)
  end
end
