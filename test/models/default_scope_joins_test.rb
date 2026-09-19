require "test_helper"

# A default_scope's ORDER BY rides along on every query, including joins
# written long after the scope. An unqualified column there ("LOWER(name)")
# raises PG::AmbiguousColumn as soon as a joined table has the same column
# (error_events #2218: Item joined to active_storage_attachments).
#
# Joins every model that has a default scope to each of its associations.
class DefaultScopeJoinsTest < ActiveSupport::TestCase
  def self.scoped_models
    Rails.application.eager_load!
    ApplicationRecord.descendants.select { |model| model.default_scopes.any? && !model.abstract_class? }
  end

  def self.joinable(model)
    model.reflect_on_all_associations.reject(&:polymorphic?)
  end

  scoped_models.each do |model|
    joinable(model).each do |assoc|
      test "#{model.name}.joins(:#{assoc.name}) keeps its default order unambiguous" do
        assert_nothing_raised do
          model.joins(assoc.name).load
          model.left_joins(assoc.name).first
        end
      end
    end
  end

  test "covers the models with default scopes" do
    assert_includes self.class.scoped_models, Item
  end
end
