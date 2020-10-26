# frozen_string_literal: true

require 'rubocop'

require 'rubocop/thread_safety'
require 'rubocop/thread_safety/version'
require 'rubocop/thread_safety/inject'

RuboCop::ThreadSafety::Inject.defaults!

require 'rubocop/cop/thread_safety/instance_variable_in_class_method'
require 'rubocop/cop/thread_safety/class_and_module_attributes'
require 'rubocop/cop/thread_safety/mutable_class_instance_variable'
require 'rubocop/cop/thread_safety/new_thread'
