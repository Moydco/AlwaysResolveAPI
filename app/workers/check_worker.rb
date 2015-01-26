class CheckWorker
  include Sidekiq::Worker

  def perform(host_id)
    host = Host.find(host_id)
    puts "Check #{host.ip_address}" if Settings.debug == 1
    if host.check.nil?
      check = 'check_ping'
    else
      check = host.check
    end
    if check == 'check_ping' and host.check_args.nil?
      check_args = " -w 50,30% -c 200,70% -t 5"
    else
      check_args = " #{host.check_args}"
    end
    if check == 'check_http'
      cmd = "#{Settings.nagios_directory}/#{check} -I  #{host.ip_address} #{check_args} -A '#{Settings.http_agent}'"
    else
      cmd = "#{Settings.nagios_directory}/#{check} -H  #{host.ip_address} #{check_args}"
    end
    puts "Doing #{cmd}"  if Settings.debug == 1
    value = `#{cmd}`
    puts "Returned #{value}"  if Settings.debug == 1

    if value.index 'OK'
      returned = 'OK'
    elsif value.index 'WARNING'
      returned = 'WARNING'
    elsif value.index 'CRITICAL'
      returned = 'CRITICAL'
    else
      returned = 'UNKNOWN'
    end
    unless host.last_status == returned
      puts "Notify new status #{returned}"  if Settings.debug == 1
      host.report_status_change_host(returned)
    end
    puts "Unlock #{host.ip_address}"  if Settings.debug == 1
    host.unlockService
  end
end