#--
# Copyright (c) 2006 Integrum Technologies, LLC.
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

begin
   require 'rubygems'
   gem 'builder', '~> 1.2'
rescue LoadError
   require 'builder'
end

begin
  gem 'activesupport', '~> 1.5'
rescue LoadError
  require File.dirname(__FILE__) + '/monetra/active_support'
end

require 'csv'
require 'net/http'
require 'net/https'

#-----------------------------------------------------
module Monetra
  class TransactionFailed < Exception 
  end

  class ParserError < Exception 
  end
  
  #-----------------------------------------------------
  class Base
    cattr_accessor :host, :port, :scheme, :username, :password, :debug
    attr_accessor :options

    #-----------------------------------------------------
    def self.parse_uri(uri)
      url = URI.parse(uri)
      @options ||= {}
      url.scheme ||= @options[:scheme] || scheme
      url.host ||= @options[:host] || host
      url.port ||= @options[:port] || port

      return url
    end

    #-----------------------------------------------------
    def self.post(body, uri='/')
      url = self.parse_uri(uri)

      req = Net::HTTP::Post.new(url.path, {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'})
      httpobj = Net::HTTP.new(url.host, url.port)
      httpobj.use_ssl = true if url.scheme == 'https'

      httpobj.start do |http|
         http.request(req, body)
      end
    end

    #-----------------------------------------------------
    def self.send(trans_set)
      if trans_set.class.to_s != 'Array'
        trans_set = [trans_set]
      end
      xml = ''
      x = 0
      b = Builder::XmlMarkup.new(:target => xml, :indent => 2)
      b.instruct!
      b.MonetraTrans {|xx|
        trans_set.each do |trans|
          x += 1
          xx.Trans(:identifier => x) do |t|
            t.username(trans.options[:username] || trans.username)
            t.password(trans.options[:password] || trans.password)
            trans.to_h.each do |k,v|
              t.tag!(k,v)
            end
          end
        end
      }
      puts xml if @@debug
      response, body = Monetra::Base.post(xml)
      puts response if @@debug
      puts body if @@debug
      begin
        resp = Hash.create_from_xml(body)
      rescue
        raise Monetra::ParserError(body)
      end

      raise Monetra::TransactionFailed(body) if resp['MonetraResp']['DataTransferStatus']['code'].upcase != 'SUCCESS'
      
      resp_set = []
      if resp['MonetraResp']['Resp'].is_a?(Hash)
        rs = [resp['MonetraResp']['Resp']]
      else
        rs = resp['MonetraResp']['Resp']
      end
      rs.each do |data|
        resp_set << Monetra::Response.new(data)
      end
      return resp_set
    end

    #-----------------------------------------------------
    def to_h
      @options
    end ## initialize
    
  end ## Base

  #-----------------------------------------------------
  module Admin
    
  end ## Admin

  #-----------------------------------------------------
  module Transaction
    #-----------------------------------------------------
    class Base < Monetra::Base
      #-----------------------------------------------------
      def initialize(*args)
        @options = args.last.is_a?(Hash) ? args.pop : {}
        @options.merge!({:action => self.class.to_s.split('::')[-1].upcase})
      end ## initialize

    end ## Base

    #-----------------------------------------------------
    class Preauth < Base
      @required_options = [:account, :amount, :expdate]
    end ## Preauth

    #-----------------------------------------------------
    class Sale < Base
      @required_options = [:account, :amount, :expdate]
    end ## Sale
    
    #-----------------------------------------------------
    class PreauthComplete < Base
      @required_options = [:ttid, :amount]
    end ## PreauthComplete

    #-----------------------------------------------------
    class Return < Base
      @required_options = [:ttid, :amount, :account, :expdate]
    end ## Return
    
    #-----------------------------------------------------
    class Admin < Base
      @required_options = [:admin]
    end ## Admin

    #-----------------------------------------------------
    class Settle < Base
      @required_options = [:batch]
    end ## Settle
    
    #-----------------------------------------------------
    class Void < Base
      @required_options = [:ttid]
    end ## Void
    
    
  end ## Transaction

  #-----------------------------------------------------
  class Response
    #-----------------------------------------------------
    def initialize(*args)
      @options = args.last.is_a?(Hash) ? args.pop : {}
    end ## initialize
    
    #-----------------------------------------------------
    def method_missing(methId)
      @options[methId.to_s]
    end ## method_missing
    
    #-----------------------------------------------------
    def success?
      phard_code.upcase == 'SUCCESS' || code == 'AUTH' || msoft_code == 'INT_SUCCESS'
    end ## success?
    
    #-----------------------------------------------------
    def timestamp
      Time.at(data['timestamp'].to_i)
    end ## timestamp
    
  end ## Response

  #-----------------------------------------------------
  module UserAudit
    #-----------------------------------------------------
    def self.ParseDataBlock(data)
      rows = []
      reader = CSV::Reader.create(data)
      header = reader.shift
      reader.each do |row|
        h = {}
        header.each_with_index do |k,i|
          h[k] = row[i]
        end
        rows << h
      end
      return rows
    end ## ParseDataBlock

    #-----------------------------------------------------
    def self.SendAdminReturnDataBlock(admin_value, options = {})
      options.merge!({:admin => admin_value})
      trans = Monetra::Transaction::Admin.new(options)
      resp_set = Monetra::Base.send([trans])
      resp = resp_set[0]
      pp resp if Monetra::Base.debug == true
      self.ParseDataBlock(resp.DataBlock)
    end ## SendAdminReturnDataBlock

    #-----------------------------------------------------
    def self.UnsettledTransactions(batch = nil)
      self.SendAdminReturnDataBlock('GUT', {:batch => batch})
    end ## GetUnseettledTransactions

    #-----------------------------------------------------
    def self.UnsettledBatches
      self.SendAdminReturnDataBlock('UB')
    end ## GetUnseettledBatches

    #-----------------------------------------------------
    def self.BatchTotals(batch = nil)
      self.SendAdminReturnDataBlock('BT', {:batch => batch})
    end ## BatchTotals

    #-----------------------------------------------------
    def self.SettledTransactions(batch = nil)
      self.SendAdminReturnDataBlock('GL', {:batch => batch})
    end ## TransactionLogs

    #-----------------------------------------------------
    def self.FailedTransactions
      self.SendAdminReturnDataBlock('GFT')
    end ## FailedTransactions

  end ## UserAudit
  
end ## MCVE
