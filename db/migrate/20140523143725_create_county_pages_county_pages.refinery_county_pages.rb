# This migration comes from refinery_county_pages (originally 1)
class CreateCountyPagesCountyPages < ActiveRecord::Migration

  def up
    create_table :refinery_county_pages do |t|
      t.string :name
      t.string :chapman_code
      t.text :content
      t.integer :position
      t.integer :position

      t.timestamps
    end

  end

  def down
    if defined?(::Refinery::UserPlugin)
      ::Refinery::UserPlugin.destroy_all({:name => "refinerycms-county_pages"})
    end

    if defined?(::Refinery::Page)
      ::Refinery::Page.delete_all({:link_url => "/county_pages/county_pages"})
    end

    drop_table :refinery_county_pages

  end

end
