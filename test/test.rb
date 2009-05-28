#!/usr/bin/env ruby
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

require File.dirname(__FILE__) + '/../lib/monetra'
require 'pp'

Monetra::Base.scheme = 'http'
Monetra::Base.port = 8555
Monetra::Base.host = 'testbox.monetra.com'
Monetra::Base.username = 'test_retail:public'
Monetra::Base.password = 'publ1ct3st'

trans = Monetra::Transaction::Sale.new({:account => '4012888888881881', :expdate => '1215', :amount => '14.04'})

resp_set = Monetra::Base.send([trans, trans])

resp_set.each do |resp|
  puts "SUCCESS!" if resp.success?
  pp resp
end
