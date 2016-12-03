# frozen_string_literal: true
require 'rails_helper'

RSpec.feature 'Tag Creation' do
  before { log_in FactoryGirl.create(:admin) }
  it 'succeeds' do
    visit 'tags/new'
    name = 'Attribute'
    fill_in 'tag_name', with: name
    click_on 'Create'
    expect(page).to have_content(name)
  end
  it 'redirects to /new on failure' do
    visit 'tags/new'
    click_on 'Create'
    expect(page).to have_content('errors')
  end
end
