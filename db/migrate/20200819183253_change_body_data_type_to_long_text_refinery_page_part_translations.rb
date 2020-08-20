class ChangeBodyDataTypeToLongTextRefineryPagePartTranslations < ActiveRecord::Migration[5.1]
  def change
    change_column :refinery_page_part_translations, :body,:longtext
  end
end
