Rails.application.routes.draw do
  get 'ads.txt', to: redirect('/ads.txt')
  resources :tags, except: :show
  get 'tags/:tag', to: 'articles#index'
  get '/search', to: 'searches#search'
  resources :images, only: [:index, :create, :destroy, :show]
  post '/tinymce_assets' => 'images#create'
  resources :articles, only: [:index, :show] do
    # get 'search', on: :collection
  end
  resources :searches, only: [:index] do
    get 'search', on: :collection
  end
  devise_for :admins
  devise_scope :admin do
    match 'admin' => 'devise/sessions#new', via: :get
  end
  namespace :author do
    resources :articles
  end
  post 'twitter/tweet', to: 'twitter#tweet_post'
  root to: 'articles#index'
end
