class DeleteCheckWorker
  include Sidekiq::Worker

  def perform(host_id, region_id)
    Region.find(region_id).delete_from_check_server(host_id)
  end
end