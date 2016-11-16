#  Created by Akash Duseja 11/16/2016
#  Copyright (c) 2016 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/flurry' # import the actual plugin
require 'webmock/rspec'

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)
