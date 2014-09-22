namespace :billing do
  task :bill => :environment do
    puts "Bill domains..."
    Domain.each do |domain|
      if domain.last_bill.nil? or domain.last_bill.month < Date.today.month
        puts "Bill #{domain.zone}";
        unless Settings.callback_new_domain == '' or Settings.callback_new_domain.nil?
          url_to_call = Settings.callback_new_domain + '/?format=json'
          url_to_call.sub!(':user', domain.user.user_reference.partition('-').first) if url_to_call.include? ':user'

          amount = Settings.domain_monthly_amount

          month_stats = domain.domain_monthly_stats.where(month: (Date.today - 1.month).month, year: (Date.today - 1.month).year).first
          amount += ((month_stats.count/1000000)+1) * Settings.queries_monthly_amount unless month_stats.nil?

          puts amount

          url = URI.parse(url_to_call)

          if Settings.callback_method == 'POST'
            req = Net::HTTP::Post.new(url.path)
          else
            req = Net::HTTP::Get.new(url.path)
          end

          if Settings.auth_method == 'oauth2'
            req.set_form_data({amount: amount, client_id: Settings.oauth2_id, client_secret: Settings.oauth2_secret})
          else
            req.set_form_data({amount: amount})
          end
          sock = Net::HTTP.new(url.host, url.port)
          if Settings.callback_new_domain.starts_with? 'https'
            sock.use_ssl = true
            sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end

          response=sock.start {|http| http.request(req) }

          if response.code.to_i == 200
            domain.update_attribute(:last_bill, Date.today)
          else
            puts "Error: #{response.code}"
          end
        end
      end
    end

    puts "Bill checks..."
    Check.each do |check|
      if check.last_bill.nil? or check.last_bill.month < Date.today.month
        puts "Bill #{check.name}";
        unless Settings.callback_new_domain == '' or Settings.callback_new_domain.nil?
          url_to_call = Settings.callback_new_domain + '/?format=json'
          url_to_call.sub!(':user', check.user.user_reference.partition('-').first) if url_to_call.include? ':user'

          amount = Settings.domain_monthly_amount

          url = URI.parse(url_to_call)

          if Settings.callback_method == 'POST'
            req = Net::HTTP::Post.new(url.path)
          else
            req = Net::HTTP::Get.new(url.path)
          end

          if Settings.auth_method == 'oauth2'
            req.set_form_data({amount: amount, client_id: Settings.oauth2_id, client_secret: Settings.oauth2_secret})
          else
            req.set_form_data({amount: amount})
          end
          sock = Net::HTTP.new(url.host, url.port)
          if Settings.callback_new_domain.starts_with? 'https'
            sock.use_ssl = true
            sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end

          response=sock.start {|http| http.request(req) }

          if response.code.to_i == 200
            check.update_attribute(:last_bill, Date.today)
          else
            puts "Error: #{response.code}"
          end
        end
      end
    end
  end
end