class V1::DnsController < ApplicationController
  before_filter :restrict_access

  before_filter :authorize_resource

  def index
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:domain_registration_id])

      render json: domain_to_register.child_dns.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def create
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:domain_registration_id])
      domain_to_register.child_dns.create(dns_params)

      render json: domain_to_register.child_dns.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def update
    begin
      dns_to_update = User.find(params[:user_id]).domain_registrations.find(params[:domain_registration_id]).child_dns.find(params[:id])
      dns_to_update.update(dns_params)

      render json: dns_to_update.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def destroy
    begin
      dns_to_delete = User.find(params[:user_id]).domain_registrations.find(params[:domain_registration_id]).child_dns.find(params[:id])
      dns_to_delete.destroy(dns_params)

      render json: dns_to_delete.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  private

  def dns_params
    params.require(:child_dns).permit( :cns, :ip)
  end
end
