module SearchHelper

  def highlight(object, field)
    object.try(:hit).try(:highlight).try(field)
  end

  def highlighted(object, field)
    if h = object.try(:hit).try(:highlight).try(field).try(:first)
      h.html_safe
    else
      field.to_s.split('.').reduce(object) { |result,item| result.try(item) }
    end
  end

end
