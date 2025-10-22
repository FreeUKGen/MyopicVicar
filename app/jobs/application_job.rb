class ApplicationJob
  def self.perform_later(*args)
    new.perform(*args)
  end
  
  def self.perform_now(*args)
    new.perform(*args)
  end
  
  def self.set(options = {})
    JobWrapper.new(self, options)
  end
  
  # Wrapper class to support method chaining
  class JobWrapper
    def initialize(job_class, options = {})
      @job_class = job_class
      @options = options
    end
    
    def perform_later(*args)
      @job_class.new.perform(*args)
    end
  end
end
