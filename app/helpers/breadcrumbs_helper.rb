module BreadcrumbsHelper

def breadcrumbs
  crumbs = [
    { label: "UK Parliament", url: "https://www.parliament.uk" }
  ]

  # Home page: Data Library with no link
  if controller_name == "home"
    crumbs << { label: "Data Library", url: nil }
    return crumbs
  end

  # Other pages: Data Library with link
  crumbs << { label: "Data Library", url: root_path }

  # Add section crumb
  section_label = controller_name.titleize
  section_path = send("#{controller_name}_path")
  
  # Add final crumb for show pages or filtered index pages
  if action_name == "show" && @item
    crumbs << { label: section_label, url: section_path }  # Link it
    identifier = @item.data_object['http://purl.org/dc/terms/identifier']
    crumbs << { label: identifier, url: nil }  # No link (current page)
  elsif action_name == "index" && params[:term_type]
    crumbs << { label: section_label, url: section_path }  # Link it
    term_label = get_term_label(params[:id])
    crumbs << { label: term_label, url: nil }  # No link (current page)
  else
    crumbs << { label: section_label, url: nil }  # No link (current page)
  end

  crumbs
end

end