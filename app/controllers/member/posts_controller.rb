class Member::PostsController < ApplicationController
  before_action :authenticate_member!
  before_action :correct_post, only: %i[edit update destroy]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.member_id = current_member.id
    tag_list = params[:post][:tag_name].split(',')
    if @post.save
      @post.save_tag(tag_list)
      redirect_to post_path(@post)
    else
      render :new
    end
  end

  def index
    @posts = Post.page(params[:page]).reverse_order
    # 検索
    unless params[:content].nil?
      @content = params[:content]
      @posts = Post.where("movie like '%" + params[:content] + "%' or details like '%" + params[:content] + "%'").page(params[:page]).reverse_order
    end
    @tag_list = Tag.joins(:posts).group(:id)
    @member = current_member.id
  end

  def show
    @post = Post.find(params[:id])
    @comment = Comment.new
    @comments = @post.comments
    @post_tags = @post.tags
  end

  def edit
    @post = Post.find(params[:id])
    @tag_list = @post.tags.pluck(:tag_name).join(',')
  end

  def update
    @post = Post.find(params[:id])
    tag_list = params[:post][:tag_name].split(',')
    if @post.update(post_params)
      @post.save_tag(tag_list)
      redirect_to post_path(@post)
    else
      render :edit
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to posts_path
  end

  # タグごとに投稿一覧表示
  def search
    @tag_list = Tag.joins(:posts).group(:id)
    @tag = Tag.find(params[:tag_id]) # クリックしたタグを取得
    @posts = @tag.posts.page(params[:page]).reverse_order         # クリックしたタグの投稿を全て表示
  end

  def correct_post
    @post = Post.find(params[:id])
    redirect_to posts_path unless @post.member.id == current_member.id
  end

  private

  def post_params
    params.require(:post).permit(:movie, :title, :details, :image)
  end
end
