Refinery::Core::Engine.routes.draw do

  # Frontend routes
  namespace :counties do
    resources :counties, :path => '', :only => [:index, :show]
  end

  # Admin routes
  namespace :counties, :path => '' do
    namespace :admin, :path => Refinery::Core.backend_route do
      resources :counties, :except => :show do
        collection do
          post :update_positions
        end
      end
    end
  end

end
