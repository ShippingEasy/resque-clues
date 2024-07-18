require 'rspec'
require 'pry'
require 'resque-clues'
require 'skipped_test_worker'
require 'test_worker'
require 'test_publisher'

def base_item(overrides={})
  {"class" => TestWorker.to_s, "args" => [1,2]}.merge!(overrides)
end

RSpec.configure do |config|
  config.before(:each) do
    reset_redis
  end
end

def reset_redis
  Resque.redis.select 15
  Resque.redis.flushdb
end

def verify_event(event_type, event_index: -1, event_class: 'TestWorker')
  publisher.event_type(event_index).should == event_type
  publisher.timestamp(event_index).should_not be_empty
  publisher.queue(event_index).should == :test_queue
  publisher.klass(event_index).should == event_class
  publisher.args(event_index).should == [1, 2]
  yield(publisher.metadata(event_index)) if block_given?
end

def unpatch_resque
  Resque.instance_exec do
    def push(queue, item)
      _base_push(queue, item)
    end

    def pop(queue)
      _base_pop(queue)
    end
  end

  Resque::Job.class_exec do
    def perform
      _base_perform
    end

    def fail(exception)
      _base_fail(exception)
    end
  end
end

def repatch_resque
  Resque.instance_exec do
    def push(queue, item)
      _clues_push(queue, item)
    end

    def pop(queue)
      _clues_pop(queue)
    end
  end

  Resque::Job.class_exec do
    def perform
      _clues_perform
    end

    def fail(exception)
      _clues_fail(exception)
    end
  end
end
