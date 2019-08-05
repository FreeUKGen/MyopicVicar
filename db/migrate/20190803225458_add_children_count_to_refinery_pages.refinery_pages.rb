# This migration comes from refinery_pages (originally 20180316032602)
class AddChildrenCountToRefineryPages < ActiveRecord::Migration[5.1]
  def change
    add_column :refinery_pages, :children_count, :integer, null: false, default: 0
  end
end
