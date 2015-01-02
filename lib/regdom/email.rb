module Regdom
  module Email
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
      data = {
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
            'type' => type,
            'fax.cc' => contact.registrant_fax.split('.').first,
            'fax' => contact.registrant_fax.split('.').last,
      }
      subject = 'Create contact'
      text = "Hello,\nyou have to create a contact for domain #{domain.domain}.#{domain.tld}.\n\n#{data.to_yaml}"
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.update_contact(registrant_contact,contact)
      data = {
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
          'type' => type,
          'fax.cc' => contact.registrant_fax.split('.').first,
          'fax' => contact.registrant_fax.split('.').last,
      }
      subject = 'Update contact'
      text = "Hello,\nyou have to modify contact with ID #{registrant_contact.id}.\n\n#{data.to_yaml}"
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.search_domain(domain,tld)
      url_to_call = "#{Settings.resellerclub_base_url}/api/domains/available.json?auth-userid=#{Settings.resellerclub_api_id}&api-key=#{Settings.resellerclub_api_key}&domain-name=#{domain}&tlds=#{tld}"
      puts "#{url_to_call}"
      response = HTTParty.get(url_to_call)
      !response.to_s.include?('available')
    end

    def self.register_domain(domain)
      data = {
          'domain-name' => "#{domain.domain}.#{domain.tld}",
          'years' => 1,
          'ns' => [ domain.ns1, domain.ns2, domain.ns3, domain.ns4, domain.ns5].reject!(&:empty?),
          'reg-contact-id' => domain.registrant_contact.id.to_s,
          'admin-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact.id.to_s),
          'tech-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.tech_contact.id.to_s),
          'billing-contact-id' => ((domain.tld == 'berlin' || domain.tld == 'ca' || domain.tld == 'eu' || domain.tld == 'nl' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact.id.to_s)
      }
      subject = 'Domain registration'
      text = "Hello,\nyou have to register domain #{domain.domain}.#{domain.tld}.\n\n#{data.to_yaml}"
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.update_domain(domain)
      data = {
          'domain-name' => "#{domain.domain}.#{domain.tld}",
          'ns' => [ domain.ns1, domain.ns2, domain.ns3, domain.ns4, domain.ns5].reject!(&:empty?),
      }
      subject = 'Domain update'
      text = "Hello,\nyou have to update DNS for domain #{domain.domain}.#{domain.tld}.\n\n#{data.to_yaml}"
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.destroy_domain(domain)
      subject = 'Domain to remove'
      text = "Hello,\nyou have to remove domain #{domain.domain}.#{domain.tld}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.expire_date(domain)
      true
    end

    def self.renew_domain(domain)
      subject = 'Domain to renew'
      text = "Hello,\nyou have to renew domain #{domain.domain}.#{domain.tld}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.transfer_domain(domain)
      data = {
          'domain-name' => "#{domain.domain}.#{domain.tld}",
          'years' => 1,
          'ns' => [ domain.ns1, domain.ns2, domain.ns3, domain.ns4, domain.ns5].reject!(&:empty?),
          'reg-contact-id' => domain.registrant_contact.id,
          'admin-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact.id),
          'tech-contact-id' => ((domain.tld == 'eu' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.tech_contact.id),
          'billing-contact-id' => ((domain.tld == 'berlin' || domain.tld == 'ca' || domain.tld == 'eu' || domain.tld == 'nl' || domain.tld == 'nz' || domain.tld == 'ru' || domain.tld == 'uk') ? -1 : domain.admin_contact.id),
          'auth_code' => domain.auth_code
      }
      subject = 'Domain transfer'
      text = "Hello,\nyou have to transfer domain #{domain.domain}.#{domain.tld}.\n\n#{data.to_yaml}"
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.lock_domain(domain)
      subject = 'Domain to lock'
      text = "Hello,\nyou have to lock domain #{domain.domain}.#{domain.tld}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.unlock_domain(domain)
      subject = 'Domain to unlock'
      text = "Hello,\nyou have to unlock domain #{domain.domain}.#{domain.tld}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.epp_key_domain(domain)
      subject = 'EPP Key request'
      text = "Hello,\nyou have to send EPP key for #{domain.domain}.#{domain.tld}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.create_child_dns(dns)
      subject = 'Child DNS record creation'
      text = "Hello,\nyou have to add this child DNS record: #{dns.cns} whit IP #{dns.ip}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end

    def self.update_child_dns(dns)
      puts "Update child DNS #{dns.to_yaml}"
      false
    end

    def self.destroy_child_dns(dns)
      subject = 'Child DNS record deletion'
      text = "Hello,\nyou have to remove this child DNS record: #{dns.cns} whit IP #{dns.ip}."
      DomainMailer.new_operation(subject,text).deliver
      return 'mail sent'
    end
  end

end