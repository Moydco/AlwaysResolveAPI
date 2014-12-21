# --------------------------------------------------------------------------- #
# Copyright 2013-2015, AlwaysResolve Project (alwaysresolve.org), MOYD.CO LTD #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License"); you may     #
# not use this file except in compliance with the License. You may obtain     #
# a copy of the License at                                                    #
#                                                                             #
# http://www.apache.org/licenses/LICENSE-2.0                                  #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
# --------------------------------------------------------------------------- #


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