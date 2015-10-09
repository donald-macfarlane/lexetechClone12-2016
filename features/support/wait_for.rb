module WaitFor
  def wait_for(timeout: 2, &block)
    start_time = Time.now
    while Time.now - start_time < timeout
      begin
        return block.call()
      rescue Exception => e
        sleep 0.1
      end
    end

    block.call()
  end
end

World(WaitFor)
