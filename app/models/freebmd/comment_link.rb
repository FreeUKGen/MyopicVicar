class CommentLink < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'CommentLink'
  belongs_to :comment, foreign_key: 'CommentID', primary_key: 'CommentID', class_name: '::Comment'
end