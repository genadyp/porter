#!/bin/bash

# A bash shell script for making the initial changes toward
# (hopefully) porting a TestUnit test to rspec.

#h2. Coming from Test::Unit to RSpec (http://rspec.rubyforge.org/svn/trunk/doc/src/documentation/test_unit.page)

#RSpec's expectation API is a superset of Test::Unit's assertion API. Use this table to
#find the RSpec equivalent of Test::Unit's asserts.

#| Test::Unit                                           | RSpec                           | Comment                             |
#| assert(object)                                       | N/A                             | |
#| assert_block {...}                                   | lambda {...}.call.should be_true| |
#| assert_equal(expected, actual)                       | actual.should == expected       | Uses <code>==</code> |
#| ''                                                   | actual.should eql(expected)      | Uses <code>Object.eql?</code> |
#| assert_in_delta(expected_float, actual_float, delta) | actual_float.should be_close(expected_float, delta) | |
#| assert_instance_of(klass, object)                    | actual.should be_an_instance_of(klass) | |
#| assert_match(pattern, string)                        | string.should match(regexp)     | |
#| ''                                                   | string.should =~ regexp         | |
#| assert_nil(object)                                   | actual.should be_nil   | |
#| assert_no_match(regexp, string)                      | string.should_not match(regexp) | |
#| assert_not_equal(expected, actual)                   | actual.should_not eql(expected)       | Uses <code>!Object.eql?</code> |
#| assert_not_nil(object)                               | actual.should_not be_nil       | |
#| assert_not_same(expected, actual)                    | actual.should_not equal(nil)    | Uses <code>Object.equal?</code> |
#| assert_nothing_raised(*args) {...}                   | lambda {...}.should_not raise_error(Exception=nil, message=nil) |
#| assert_nothing_thrown {...}                          | lambda {...}.should_not throw_symbol(symbol=nil) |
#| assert_operator(object1, operator, object2)          | N/A | |
#| assert_raise(*args) {...}                            | lambda {...}.should raise_error(Exception=nil, message=nil) |
#| assert_raises(*args) {...}                           | lambda {...}.should raise_error(Exception=nil, message=nil) |
#| assert_respond_to(object, method)                    | actual.should respond_to(method) | |
#| assert_same(expected, actual)                        | actual.should equal(expected)         | Uses <code>!Object.equal?</code> |
#| assert_send(send_array)                              | N/A | |
#| assert_throws(expected_symbol, &proc)                | lambda {...}.should throw_symbol(symbol=nil) | |
#| flunk(message="Flunked")                             | violated(message=nil) | |
#| N/A                                                  | actual.should_be_something | Passes if object.something? is true |

#h2. Regarding Equality

#RSpec lets you express equality the same way Ruby does. This is different from
#Test::Unit and other xUnit frameworks, and this may cause some confusion for those
#of you who are making a switch.

#Consider this example:

#<coderay>words = "the words"
#assert_equals("the words", words) #passes
#assert_same("the words", words) #fails
#</coderay>

#xUnit frameworks traditionally use method names like <code>#assert_equals</code> to
#imply object equivalence (objects with the same values) and method names like <code>#assert_same</code> to
#imply object identity (actually the same object). For programmers who are used to this syntax,
#it makes perfect sense to see this in a unit testing framework for Ruby.

#The problem that we found is that Ruby handles equality differently from other languages. In
#java, for example, we override <code>Object#equals(other)</code> to describe object equivalence,
#whereas we use <code>==</code> to describe object identity. In Ruby, we do just the opposite.
#In fact, Ruby provides us with four ways to express equality:

#<coderay>a == b
#a === b
#a.equal?(b)
#a.eql?(b)
#</coderay>

#Each of these has its own semantics, which can (and often do) vary from class to class. In
#order to minimize the translation required to understand what an example might be expressing,
#we chose to express these directly in RSpec. If you understand Ruby equality, then you
#can understand what RSpec examples are describing:

#<coderay>a.should == b      #passes if a == b
#a.should === b     #passes if a === b
#a.should equal(b)  #passes if a.equal?(b)
#a.should eql(b)    #passes if a.eql?(b)
#</coderay>

tu_file=$1
rspec_file=`echo $tu_file | sed 's/test/spec/g' | sed 's/unit/models/g'`
class_name=`grep -o 'class [[:alpha:]]*Test[[:alpha:]]*' $tu_file | sed 's/class //g' | sed 's/Test//g'`

echo $tu_file
echo $rspec_file
echo $class_name
mkdir -p `dirname $rspec_file`
cp $tu_file $rspec_file

sed -i -e  's/test_helper/spec_helper/g' $rspec_file
sed -i -e  "s/require 'test\/unit'/require 'rspec'/" $rspec_file
sed -i -e  's/module Test/module Spec/' $rspec_file
sed -i -e  "s/class.*Test.*/describe '${class_name}Test' do/g" $rspec_file
perl -i -pe ' if (/describe\s*\W(\w*)\W*\s* do/) { 
my $new = join(" ", $1 =~ /[A-Z][a-z0-9]*/g);
s/(describe\s*\W*)(\w*)(.*)/$1$new$3/; 
} ' $rspec_file;
sed -i -e  's/Test < ActiveSupport::TestCase/do/g' $rspec_file
sed -i -e  's/^\(\s*\)skip /\1pending /' $rspec_file

sed -i -e  's/def\s*setup\s*(*)*/before :all do/g' $rspec_file
sed -i -e  's/def\s*teardown\s*(*)*/after :all do/g' $rspec_file

sed -i -e  's/assert_equal(\([^,]*\),\s*\(.*\)\s*)/\2.should == \1/g' $rspec_file
sed -i -e  's/assert_not_equal\s*(\(.*\),\(.*\))/\2.should_not == \1/g' $rspec_file
sed -i -e  's/assert_nil\s\+\(.*\)/\1.should be_nil/g' $rspec_file
sed -i -e  's/assert_not_nil\s*(\(.*\))/\1.should_not be_nil/g' $rspec_file
sed -i -e  's/assert_raise\s*\(([^)]*)\)\s*\({.*}\)/expect \2.to raise_exception\1/g' $rspec_file
sed -i -e  's/assert_nothing_raised\s*\({.*}\)/expect \1.not_to raise_exception/g' $rspec_file
sed -i -e  's/assert_match(\(.*\),\(.*\))/\2.should match \1/g' $rspec_file
sed -i -e  's/assert\s*(*\(.*\),\s*\([^)]*\))*/(\1).should be_true \2/g' $rspec_file 
sed -i -e  's/assert\s*\((*.*)*\)/\1.should be_true/g' $rspec_file

sed -i -e  's/stubs\(\(.*\)\).returns\(\(.*\)\)/stub\1.and_return\3/g' $rspec_file
sed -i -e  's/stubs(\(.*\)=>\(.*\))/stub(\1).and_return(\2)/g' $rspec_file
sed -i -e  's/stubs/stub/g' $rspec_file

sed -i -e  "s/def \(test_.*\)/it '\1' do/" $rspec_file
perl -i -pe ' if (/it .* do/) { s/_/ /g; } ' $rspec_file

#sed -i -e  's/assert_not_\([a-z]\+\)\(.*\)/\2.should_not be_\1/g' $rspec_file
#sed -i -e  's/\.expects/.should_receive/g' $rspec_file
#sed -i -e  's/\.raises/.should raise_exception/g' $rspec_file
#sed -i -e  's/assert_\([a-z]\+\)\(.*\)/\2.should be_\1/g' $rspec_file
#sed -i -e  "s/should \'/it \'should /g" $rspec_file
#sed -i -e  's/should \"/it "should /g' $rspec_file
#sed -i -e  's/assert\s\+!\(.*\)/\1.should be_false/g' $rspec_file

#git rm $tu_file
#git add $rspec_file

#rm $rspec_file~
