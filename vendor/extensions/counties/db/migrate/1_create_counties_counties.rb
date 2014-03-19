class CreateCountiesCounties < ActiveRecord::Migration

  def up
    create_table :refinery_counties do |t|
      t.string :county
      t.string :chapman_code
      t.text :content
      t.integer :position

      t.timestamps
    end

  end

  def down
    if defined?(::Refinery::UserPlugin)
      ::Refinery::UserPlugin.destroy_all({:name => "refinerycms-counties"})
    end

    if defined?(::Refinery::Page)
      ::Refinery::Page.delete_all({:link_url => "/counties/counties"})
    end

    drop_table :refinery_counties

  end

end
