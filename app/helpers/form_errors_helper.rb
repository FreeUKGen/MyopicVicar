module FormErrorsHelper
	def form_error(form)
		model = form.object
		errors = model.errors

		if errors.any?
			content_tag(:div, id: 'error_explanation') do
				content_tag(:h2, class: 'gamma') do
					"You have errors.count"
				end
				content_tag(:ul) do
					errors.full_messages.map { |msg| 
						content_tag(:li, class: "validation-list__error") do
							msg
						end
					}.sum
				end
			end
		end
	end
end