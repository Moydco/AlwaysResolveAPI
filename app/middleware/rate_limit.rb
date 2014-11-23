class RateLimit
  def initialize(app)
    @app = app
  end

  def call(env)
    client_ip = env["action_dispatch.remote_ip"]
    key = "count:#{client_ip}"
    count = REDIS.get(key)
    unless count
      REDIS.set(key, 0)
      REDIS.expire(key, Settings.throttle_time_window)
      count = 0
    end

    if count.to_i >= Settings.throttle_max_requests
      [
          429,
          rate_limit_headers(count, key),
          [message]
      ]
    else
      REDIS.incr(key)
      status, headers, body = @app.call(env)
      [
          status,
          headers.merge(rate_limit_headers(count.to_i + 1, key)),
          body
      ]
    end
  end

  private
  def message
    {
        :message => "You have fired too many requests. Please wait for some time."
    }.to_json
  end

  def rate_limit_headers(count, key)
    ttl = REDIS.ttl(key)
    time = Time.now.to_i
    time_till_reset = (time + ttl.to_i).to_s
    {
        "X-Rate-Limit-Limit" =>  Settings.throttle_max_requests,
        "X-Rate-Limit-Remaining" => (Settings.throttle_max_requests - count.to_i).to_s,
        "X-Rate-Limit-Reset" => time_till_reset
    }
  end
end