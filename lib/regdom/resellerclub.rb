module Regdom
  module Resellerclub
    include HTTParty

    def self.pre_register_contact?
      true
    end

    def self.create_contact(contact,domain)
      if domain.tld == 'ca'
        type = 'CaContact'
      elsif domain.tld == 'cn'
        type = 'CnContact'
      elsif domain.tld == 'co'
        type = 'CoContact'
      elsif domain.tld == 'de'
        type = 'DeContact'
      elsif domain.tld == 'es'
        type = 'EsContact'
      elsif domain.tld == 'eu'
        type = 'EuContact'
      elsif domain.tld == 'nl'
        type = 'NlContact'
      elsif domain.tld == 'ru'
        type = 'RuContact'
      elsif domain.tld == 'uk'
        type = 'UkContact'
      else
        type = 'Contact'
      end
      url_to_call = "#{Settings.resellerclub_base_url}/api/contacts/add.json"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'name' => "#{contact.registrant_first_name} #{contact.registrant_last_name}",
              'company' => contact.registrant_organization_name,
              'email' => contact.registrant_email_address,
              'address-line-1' => contact.registrant_address1,
              'address-line-2' => contact.registrant_address2,
              'city' => contact.registrant_city,
              'country' => contact.registrant_country,
              'zipcode' => contact.registrant_postal_code,
              'phone-cc' => contact.registrant_phone.split('.').first,
              'phone' => contact.registrant_phone.split('.').last,
              'customer-id' => Settings.resellerclub_customer_id,
              'type' => type,
              'fax.cc' => contact.registrant_fax.split('.').first,
              'fax' => contact.registrant_fax.split('.').last,
          }
      }
      puts "url_to_call: #{url_to_call}"
      puts "options: #{options}"

      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response.to_s

    end

    def self.update_contact(registrant_contact,contact)
      url_to_call = "#{Settings.resellerclub_base_url}/api/contacts/modify.json"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'contact-id' => registrant_contact,
              'name' => "#{contact.registrant_first_name} #{contact.registrant_last_name}",
              'company' => contact.registrant_organization_name,
              'email' => contact.registrant_email_address,
              'address-line-1' => contact.registrant_address1,
              'address-line-2' => contact.registrant_address2,
              'city' => contact.registrant_city,
              'country' => contact.registrant_country,
              'zipcode' => contact.registrant_postal_code,
              'phone-cc' => contact.registrant_phone.split('.').first,
              'phone' => contact.registrant_phone.split('.').last,
              'fax.cc' => contact.registrant_fax.split('.').first,
              'fax' => contact.registrant_fax.split('.').last,
          }
      }
      puts "url_to_call: #{url_to_call}"
      puts "options: #{options}"

      response = HTTParty.post(url_to_call, options)
      response.to_s
    end

    def self.search_domain(domain,tld)
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/available.json?auth-userid=#{Settings.resellerclub_api_id}&api-key=#{Settings.resellerclub_api_key}&domain-name=#{domain}&tlds=#{tld}"
      puts "#{url_to_call}"
      response = HTTParty.get(url_to_call)
      !response.to_s.include?('available')
    end

    def self.register_domain(domain)
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/register.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'domain-name' => "#{domain.domain}.#{domain.tld}",
              'years' => 1,
              'ns' => [ domain.ns1, domain.ns2, domain.ns3, domain.ns4, domain.ns5].reject!(&:empty?),
              'customer-id' => Settings.resellerclub_customer_id,
              'reg-contact-id' => domain.registrant_contact_code,
              'admin-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact_code),
              'tech-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.tech_contact_code),
              'billing-contact-id' => ((domain.tld == 'berlin' || domain.tld == 'ca' || domain.tld == 'eu' || domain.tld == 'nl' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact_code),
              'invoice-option' => 'NoInvoice'
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.update_domain(domain)
      puts "Update #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/modify-ns.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id,
              'ns' => [ domain.ns1, domain.ns2, domain.ns3, domain.ns4, domain.ns5].reject!(&:empty?)
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.destroy_domain(domain)
      puts "Destroy #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/delete.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.expire_date(domain)
      puts "Get Order details #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/details.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id,
              'options' => 'OrderDetails'
          }
      }
      puts "#{options}"
      response = HTTParty.get(url_to_call, options)
      puts response.to_s
      response["endtime"]
    end

    def self.renew_domain(domain)
      puts "Renew #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/renew.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id,
              'years' => 1,
              'invoice-option' => 'NoInvoice',
              'exp-date' => domain.expire_date
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.transfer_domain(domain)
      puts "Transfer #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/transfer.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'domain-name' => "#{domain.domain}.#{domain.tld}",
              'years' => 1,
              'ns' => [ domain.ns1, domain.ns2, domain.ns3, domain.ns4, domain.ns5].reject!(&:empty?),
              'customer-id' => Settings.resellerclub_customer_id,
              'reg-contact-id' => domain.registrant_contact_code,
              'admin-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact_code),
              'tech-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.tech_contact_code),
              'billing-contact-id' => ((domain.tld == 'berlin' || domain.tld == 'ca' || domain.tld == 'eu' || domain.tld == 'nl' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact_code),
              'invoice-option' => 'NoInvoice',
              'auth_code' => domain.auth_code
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.lock_domain(domain)
      puts "Lock #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/enable-theft-protection.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.unlock_domain(domain)
      puts "Unlock #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/disable-theft-protection.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id
          }
      }
      puts "#{options}"
      response = HTTParty.post(url_to_call, options)
      puts response.to_s
      response
    end

    def self.epp_key_domain(domain)
      puts "Epp_key #{domain.to_yaml}"
      puts "Get Order details #{domain.to_yaml}"
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/details.json"
      puts "#{url_to_call}"
      options = {
          query: {
              'auth-userid' => Settings.resellerclub_api_id,
              'api-key' => Settings.resellerclub_api_key,
              'order-id' => domain.order_id,
              'options' => 'OrderDetails'
          }
      }
      puts "#{options}"
      response = HTTParty.get(url_to_call, options)
      puts response.to_s
      response["domsecret"]
    end
  end

end