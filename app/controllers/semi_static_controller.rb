class SemiStaticController < ApplicationController

  # ==== GET: /
  # Root page of API: show only a welcome message with 200 code
  def index
    respond_to do |format|
      format.html {render text: "Welcome to moyd.co API Server"}
      format.xml {render text: "Welcome to moyd.co API Server"}
      format.json {render text: "Welcome to moyd.co API Server"}
    end
  end
end
