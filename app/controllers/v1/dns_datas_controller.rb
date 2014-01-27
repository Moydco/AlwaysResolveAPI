class V1::DnsDatasController < ApplicationController
  before_filter :restrict_access

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
end
