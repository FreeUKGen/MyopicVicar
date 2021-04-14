class Comment < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'Comments'
  has_many :comment_links, class_name: '::CommentLink', primary_key: 'CommentID', foreign_key: 'CommentID'
end