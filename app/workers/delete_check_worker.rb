class DeleteCheckWorker
  include Sidekiq::Worker

  def perform(check_id, host_id, region_id)
    Region.find(region_id).delete_from_check_server(check_id, host_id)
  end
end