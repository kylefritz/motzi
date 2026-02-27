# Ransack 4 requires explicit allowlists. PaperTrail::Version comes from a gem.
require "paper_trail/frameworks/active_record/models/paper_trail/version"

class PaperTrail::Version
  def self.ransackable_attributes(_auth_object = nil)
    column_names
  end

  def self.ransackable_associations(_auth_object = nil)
    reflect_on_all_associations.map { |association| association.name.to_s }
  end
end
