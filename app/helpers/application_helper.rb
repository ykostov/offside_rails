module ApplicationHelper
  def tags
    tags ||= Tag.where(active: true).order(:id)
  end

  def selected_tag
    Tag.find(params[:tag]).name if params[:tag]
  end

  def tag_status(status)
    return 'Active' if status
    'Not active'
  end
end
