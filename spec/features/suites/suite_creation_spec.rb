# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Suite Creation' do
  before { log_in FactoryGirl.create(:admin) }
  it 'succeeds' do
    attrs = { building: FactoryGirl.create(:building), suite_number: 'L01' }
    visit new_building_suite_path(attrs[:building])
    fill_in_suite_info(**attrs)
    click_on 'Create'
    expect(page).to have_content(attrs[:suite_number])
  end
  it 'redirects to /new on failure' do
    visit new_building_suite_path(FactoryGirl.create(:building))
    click_on 'Create'
    expect(page).to have_content('errors')
  end

  def fill_in_suite_info(building:, **attrs)
    attrs.each { |a, v| fill_in a.to_s, with: v }
    select(building.name, from: 'suite_building_id')
  end
end
