class ArticlesController < ApplicationController
  def index
    if params[:tag]
      @tag = ActsAsTaggableOn::Tag.find(params[:tag])
      @articles = Article.tagged_with(@tag.name).desc_order.paginate(page: params[:page], per_page: 15)
    else
      @articles = Article.importance.desc_order.paginate(page: params[:page], per_page: 15)
    end
  end

  def show
    @article = Article.find(params[:id])
    @current_tag = @article.tags.first
    if @current_tag
      @feat_current = Article.tagged_with(@current_tag.name).desc_order.first(7).reject {|a| a == @article}
      @tags ||= Tag.where(active: true).order(:id)
      @current_index = @tags.find_index {|t| t.id == @current_tag.id}
      @prev_current = Article.tagged_with(@tags[@current_index - 1].name).desc_order.first(6)
      @next_current = Article.tagged_with(@tags[calc(@current_index) + 1].name).desc_order.first(6)
    end
    # BumpViewsJob.perform_later(@article.id)
  end

  def search
    if params[:search]
      if params[:use_highlights]
        @articles = Article.highlight_tsearch(params[:search])
      else
        @articles = Article.plain_tsearch(params[:search])
      end
    end

    respond_to do |format|
      format.html { render :index }
      format.js { @articles }
    end
  end

  private

  def calc(index)
    return index if index < @tags.length - 1
    -1
  end
end
