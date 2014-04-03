class UpdateCheckWorker
  include Sidekiq::Worker

  def perform(check_id, region_id)
    Region.find(region_id).update_check_server(check_id)
  end
end