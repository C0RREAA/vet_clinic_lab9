Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :owners
  resources :pets
  resources :vets
  resources :appointments do
    resources :treatments, except: [ :index, :show ]
  end
end
