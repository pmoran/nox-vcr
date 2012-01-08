$:.unshift File.expand_path(File.dirname(__FILE__))
require 'sinatra'
require 'app'

run App
