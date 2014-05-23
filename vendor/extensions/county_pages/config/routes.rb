Refinery::Core::Engine.routes.draw do

  # Frontend routes
  namespace :county_pages do
    resources :county_pages, :path => '', :only => [:index, :show]
  end

  # Admin routes
  namespace :county_pages, :path => '' do
    namespace :admin, :path => Refinery::Core.backend_route do
      resources :county_pages, :except => :show do
        collection do
          post :update_positions
        end
      end
    end
  end

end
