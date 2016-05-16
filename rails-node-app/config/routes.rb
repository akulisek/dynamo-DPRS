Rails.application.routes.draw do
	 
  root 'node#index'

  get 'node/read_key' => 'node#read_key_value', as: :GET_read_key_value, :defaults => { :format => 'json' }
  post 'node/write_key' => 'node#write_key_value', as: :POST_read_key_value, :defaults => { :format => 'json' }
  get 'node/update_configuration' => 'node#update_configuration', as: :update_configuration, :defaults => { :format => 'json' }
  get 'node/get_data' => 'node#get_data', as: :get_data, :defaults => { :format => 'json' }
  get 'node/get_all_data' => 'node#get_all_data', as: :get_all_data, :defaults => { :format => 'json' }
  get 'node/get_data_for_range' => 'node#get_data_for_range', as: :get_data_for_range, :defaults => { :format => 'json' }
  get 'node/register_to_service_discovery' => 'node#register_to_service_discovery', as: :register_to_service_discovery, :defaults => { :format => 'json' }
  get 'node/health' => 'node#health', as: :GET_health, :defaults => { :format => 'json' }

 # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
