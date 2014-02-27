class UpdateCheckWorker
  include Sidekiq::Worker

  def perform(host_id, region_id)
    host = ARecord.find(host_id)
    Region.find(region_id).update_check_server(host.id.to_s, host.ip,host.parent_a_record.cluster.check,host.parent_a_record.cluster.check_args,host.parent_a_record.cluster.enabled)
  end
end