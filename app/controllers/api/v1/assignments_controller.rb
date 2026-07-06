class Api::V1::AssignmentsController < Api::V1::BaseController
  def index
    assignments = Assignment.where(userid_detail_id: @current_user.id)
    render json: assignments.map { |assignment| assignment_json(assignment) }
  end

  private

  def assignment_json(assignment)
    source = assignment.source
    register = source&.register
    church = register&.church
    place = church&.place
    images = ImageServerImage.where(assignment_id: assignment.id).order_by(image_file_name: 1)

    {
      id: assignment.id.to_s,
      assign_date: assignment.assign_date,
      instructions: assignment.instructions,
      folder_name: source&.folder_name,
      register_type: register&.register_type,
      church_name: church&.church_name,
      place_name: place&.place_name,
      county: place&.county,
      chapman_code: place&.chapman_code,
      country: place&.country,
      images: images.map { |image| { image_file_name: image.image_file_name, status: image.status } }
    }
  end
end
