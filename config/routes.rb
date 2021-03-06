Rails.application.routes.draw do

  get 'inquiry/index'      # 入力画面
  post 'inquiry/confirm'   # 確認画面
  post 'inquiry/thanks'    # 送信完了画面

  devise_for :admins, controllers: {
    sessions:      'admins/sessions',
    passwords:     'admins/passwords',
    registrations: 'admins/registrations'
  }
  devise_for :members, controllers: {
    sessions:      'members/sessions',
    passwords:     'members/passwords',
    registrations: 'members/registrations',
    omniauth_callbacks: 'members/omniauth_callbacks'
  }

  devise_scope :member do
    post 'members/guest_sign_in', to: 'members/sessions#new_guest'
  end

  scope module: :member do
    root to: 'homes#top'
    get 'home/about' => 'homes#about'
    resources :posts do
      resources :comments, only: [:create, :destroy]
      resource :favorites, only: [:create, :destroy]
    end

    resources :members, only: [:show, :edit, :index, :update] do
      resources :notifications, only: [:index]
      resource :relationships, only: [:create, :destroy]
      member do
        get 'follows'  #follower一覧
        get 'followers'  # followed一覧
        get 'favorites'
        get 'timeline' # フォローしている人の投稿一覧（タイムライン）
      end

    end

    resources :tags do
      get 'posts', to: 'posts#search'
    end

  end

  namespace :admin do
    resources :posts, only: [:index, :show, :destroy] do
      resources :comments, only: [:destroy]
    end
    resources :members, only: [:show, :edit, :index, :update]
  end

end
