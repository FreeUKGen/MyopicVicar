# This migration comes from seo_meta_engine (originally 20120518234749)
class RemoveMetaKeywordsFromSeoMeta < ActiveRecord::Migration
  def up
    remove_column :seo_meta, :meta_keywords
  end

  def down
    add_column :seo_meta, :meta_keywords, :string
  end
end
