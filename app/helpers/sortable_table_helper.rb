module SortableTableHelper
  def current_sort
  (params[:sort] || session[:sort] || 'uploaded_date DESC').to_s
  end

  def sortable_column(label, field)
    current_field, current_dir = current_sort.split
    direction = if current_field == field && current_dir&.upcase == 'ASC'
                  'DESC'
                else
                  'ASC'
                end
                
    link_to(
      "#{label}#{sort_arrow(field)}".html_safe,
      params.permit(:page).merge(sort: "#{field} #{direction}"),
      class: "sticky-header-link"
    )
  end

  def sort_arrow(field)
    current_field, current_dir = current_sort.split
    return '' unless current_field == field
    current_dir&.upcase == 'ASC' ? ' ▲' : ' ▼'
  end
end