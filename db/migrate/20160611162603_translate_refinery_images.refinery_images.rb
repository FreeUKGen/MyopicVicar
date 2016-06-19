# This migration comes from refinery_images (originally 20150430171341)
class TranslateRefineryImages < ActiveRecord::Migration
  def self.up
    begin
      ::Refinery::Image.create_translation_table!({
        image_alt: :string,
        image_title: :string
      }, {
        :migrate_data => true
      })
    rescue NameError
      warn "Refinery::Image was not defined!"
    end
  end

  def self.down
    begin
      Refinery::Image.drop_translation_table! migrate_data: true
    rescue NameError
      warn "Refinery::Image was not defined!"
    end
  end
end