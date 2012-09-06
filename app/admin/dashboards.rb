ActiveAdmin::Dashboards.build do

  # Define your dashboard sections here. Each block will be
  # rendered on the dashboard in the context of the view. So just
  # return the content which you would like to display.
  
  # == Simple Dashboard Section
  # Here is an example of a simple dashboard section
  #
  #   section "Recent Posts" do
  #     ul do
  #       Post.recent(5).collect do |post|
  #         li link_to(post.title, admin_post_path(post))
  #       end
  #     end
  #   end
  
  # == Render Partial Section
  # The block is rendered within the context of the view, so you can
  # easily render a partial rather than build content in ruby.
  #
  #   section "Recent Posts" do
  #     div do
  #       render 'recent_posts' # => this will render /app/views/admin/dashboard/_recent_posts.html.erb
  #     end
  #   end
  
  # == Section Ordering
  # The dashboard sections are ordered by a given priority from top left to
  # bottom right. The default priority is 10. By giving a section numerically lower
  # priority it will be sorted higher. For example:
  #
  #   section "Recent Posts", :priority => 10
  #   section "Recent User", :priority => 1
  #
  # Will render the "Recent Users" then the "Recent Posts" sections on the dashboard.
  
  # == Conditionally Display
  # Provide a method name or Proc object to conditionally render a section at run time.
  #
  # section "Membership Summary", :if => :memberships_enabled?
  # section "Membership Summary", :if => Proc.new { current_admin_user.account.memberships.any? }

  section "Recent Activity" do
    h3 "Uploads"
    ul do
      Upload.sort(:updated_at.desc).limit(5).each do |iu|
        li link_to(iu.name, admin_upload_path(iu))
      end
    end
    h3 "Image Lists"
    ul do
      ImageList.sort(:updated_at.desc).limit(5).each do |il|
        li link_to(il.name, admin_image_list_path(il))
      end
    end
  end


  section "System Stats" do
    table do
      tr do
        td "Uploads"
        td Upload.count
      end
      tr do
        td "Directories"
        td ImageDir.count
      end
      tr do
        td "Image Files"
        td ImageFile.count
      end
      tr do
        td "Image Lists"
        td Upload.count
      end
      tr do
        td APP_CONFIG['asset_name']
        td AssetCollection.count
      end
      tr do
        td "Pages"
        td Asset.count
      end
    end
  end

end
