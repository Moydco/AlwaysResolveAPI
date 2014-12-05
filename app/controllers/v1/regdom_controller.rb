class V1::RegdomController < ApplicationController

  def index

    begin
      domain = params[:domain]
      tld = params[:tld]

      if !tld.nil? and !domain.nil?

        m = eval "Settings.domain_registers_#{tld}"
        m = Settings.domain_default_register if m.nil? or n.empty?

        logger.debug "lib/regdom/#{m}"
        logger.debug "include Regdom::#{m.humanize}"

        require "lib/regdom/#{m}"
        regdom = eval "Regdom::#{m.humanize}"

        if regdom.search_domain(domain,tld)
          render text: 'Not Available', status: 411
        else
          render text: 'Available', status: 200
        end
      else
        render text: 'Missinig required informations', status: 500
      end
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end
end
