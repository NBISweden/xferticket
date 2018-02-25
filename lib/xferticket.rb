# frozen_string_literal: true
require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "sinatra/config_file"
require "sinatra/flash"
require "rufus/scheduler"
require "minitar"
require "securerandom"
require "logger"
require 'pp'

require "xferticket/directoryuser.rb"
require "xferticket/ticket.rb"
require "xferticket/application.rb"

