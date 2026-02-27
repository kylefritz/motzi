class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # ActiveAdmin/Ransack 4 requires explicit allowlists.
  # This app uses Ransack only in admin screens, so we allow model columns and associations.
  def self.ransackable_attributes(_auth_object = nil)
    column_names
  end

  def self.ransackable_associations(_auth_object = nil)
    reflect_on_all_associations.map { |association| association.name.to_s }
  end
end
