# frozen_string_literal: true

# helper methods for Herbaria views
module HerbariaHelper
  def herbarium_top_users(herbarium)
    User.joins(:herbarium_records).
      where(User[:id].eq(HerbariumRecord[:user_id])).
      where(HerbariumRecord[:id].eq(herbarium.id)).
      select(User[:name], User[:login], User[:id].count).
      group(User[:id]).order(User[:id].count(:desc)).take(5)
  end
end
