class V1::DnsDatasController < ApplicationController
  before_filter :restrict_access, :is_admin

  def index
    domains = ''
    Domain.each do |d|
      domains += d.zone
      domains += ' '
    end
    render text: domains
  end

  def show
    domain = Domain.where(:zone => params[:zone]).first
    render text: domain.json_zone(params[:region]) unless domain.nil?
  end

  def check_list
    conf = []
    # Load cluster configurations
    Check.all.each do |check|
      conf.push(
          {
              :reference => "#{check.id.to_s}",
              :ip_address => check.ip,
              :check => check.check,
              :check_args => check.check_args,
              :enabled => check.enabled.to_s
          }
      )
    end

    render json: conf

  end

  def query_count
    begin
      region = Region.find(params['json']['region'])
    rescue
      region = nil
    end

    params['json']['queryCount'].each do |stat|
      unless stat.nil?
        domain = Domain.where(zone: stat.first.to_s).first
        unless domain.nil?
          s = domain.domain_statistics.new(count: stat.last.to_s,serverID: params['json']['serverID'])
          s.region = region
          s.save
        end
      end
    end
  end

  def update_from_check
    check = Check.find(params[:id])
    status = check.choose_status(params[:status])
    status_change = false
    if status == 'OK'
      if check.hard_status
        # if is OK do nothing, only reset counter
        check.soft_count = 0
        check.soft_status = true
        check.hard_status = true
      else
        # if hard is in error
        check.soft_count += 1
        check.soft_status = true
        # check if I have to enable this host
        if check.soft_count >= check.soft_to_hard_to_enable
          check.hard_status = true
          check.soft_count = 0
          status_change = true
        end
      end
    else
      if check.hard_status
        # if hard is ok
        check.soft_count += 1
        check.soft_status = false
        # check if I have to enable this host
        if check.soft_count >= check.soft_to_hard_to_disable
          check.hard_status = false
          check.soft_count = 0
          status_change = true
        end
      else
        # if hard is error do nothing, only reset counter
        check.soft_count = 0
        check.soft_status = false
        check.hard_status = false
      end
    end

    check.save

    if status_change and not check.reports_only
      check.records.each do |record|
        record.operational = check.hard_status
        record.save
      end
      if Settings.notify_changes_to_check == 'true'
        Region.where(:has_check => true).each do |region|
          region.update_check_server(check.id.to_s)
        end
      end
    end
  end
end

