class V1::HostsController < ApplicationController
  def index
    @hosts = Host.all
    render json: @hosts
  end

  def update
    begin
      @host = Host.where(reference: "record_#{params[:reference]}").first
      if @host.nil?
        @host = Host.create!(host_params)
      else
        @host.update_attributes!(host_params)
      end

      render json: @host
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  def destroy
    begin
      @host = Host.where(reference: "record_#{params[:reference]}").first
      @host.destroy
      render json: @host
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  def show
    begin
      @host = Host.find(params[:reference])
      render json: @host
    rescue => e
      render json: {error: "#{e.message}"}, status: 404
    end
  end

  private

  def host_params
    params.permit(:reference, :ip_address, :check, :check_args, :enabled, :operational, :last_status)
  end
end
