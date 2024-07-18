class SkippedTestWorker
  @queue = :test_queue

  def self.perform(first, second)
    # This would normally be set in an around_perform block when it fails to
    # acquire a lock. Fake it here instead of adding a new plugin dependency
    Thread.current["perform_skipped"] = true
  end
end
