# This migration comes from refinery_pages (originally 20170703020017)
class RemoveTranslatedColumnsToRefineryPageParts < ActiveRecord::Migration[5.0]
  def change
    remove_column :refinery_page_parts, :body
  end
end
