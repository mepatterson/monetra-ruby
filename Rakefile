#--
# Copyright (c) 2006 Integrum Technologies, LLC
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rake/testtask'
require 'rake/gempackagetask'

PKG_VERSION = '0.0.7'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir.glob('test/**/*_test.rb')
  t.verbose = true
end

task :default => :test

dist_dirs = ['lib', 'test']

spec = Gem::Specification.new do |s|
  s.name        = 'monetra-ruby'
  s.version     = PKG_VERSION
  s.summary     = "Ruby library for accessing Main Street Softwork's Monetra credit card processing system"
  s.description = s.summary
  
  # s.add_dependency('activesupport', '>= 1.3.1')
  s.add_dependency('builder',       '>= 1.2')
  
  s.require_path = 'lib'
  s.autorequire = 'monetra'
  
  s.files = ['Rakefile']
  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob("#{dir}/**/*").delete_if {|item| item.include?("\.svn") }
  end
end

Rake::GemPackageTask.new(spec) do |pkg|
end
