require 'rails_helper'

RSpec.describe User do
  it 'has a valid factory' do
    FactoryGirl.create(:user).expect be_valid
  end
  it 'is invalid without an user reference' do
    FactoryGirl.build(:user, user_reference: nil).should_not be_valid
  end
  it 'does not allow duplicate user reference' do
    FactoryGirl.create(:user, user_reference: '1234567890')
    FactoryGirl.build(:user, user_reference: '1234567890').should_not be_valid
  end
end