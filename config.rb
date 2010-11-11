#!/usr/bin/ruby

require 'rubygems'
require 'sequel'
require 'paperclip'
require 'mechanize'
require 'log4r'
include Log4r


@logger = Logger.new 'DatingParser'
@logger.outputters = Outputter.stdout
@logger.outputters.first.formatter = PatternFormatter.new(:pattern => "[%d] %m")

LOGIN = 'login'
PASS = 'password'
SITE = 'http://www.loveplanet.ru'
START_AGE = 18
END_AGE = 25
REGION = [3159, 4925, 4962] #St.Petersburg
