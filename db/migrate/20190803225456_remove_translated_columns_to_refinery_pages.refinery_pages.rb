# This migration comes from refinery_pages (originally 20170703015418)
class RemoveTranslatedColumnsToRefineryPages < ActiveRecord::Migration[5.0]
  def change
    remove_column :refinery_pages, :custom_slug
    remove_column :refinery_pages, :slug
  end
end
