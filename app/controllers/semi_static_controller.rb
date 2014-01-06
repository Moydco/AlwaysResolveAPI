class SemiStaticController < ApplicationController

  # ==== GET: /
  # Root page of API: show only a welcome message with 200 code
  def index
    render text: "Welcome to moyd.co API Server"
  end
end
