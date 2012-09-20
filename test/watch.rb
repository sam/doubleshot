#!/usr/bin/env jruby

require "java"
require "rubygems"
require "bundler/setup"
require "jbundler"

require_relative "../lib/doubleshot/watcher"

Watcher::instance.run