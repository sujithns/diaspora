#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class LikesController < ApplicationController
  include ApplicationHelper
  helper :likes
  before_filter :authenticate_user!
  
  respond_to :html, :mobile, :json
  
  def create
    target = current_user.find_visible_post_by_id params[:post_id]
    positive = (params[:positive] == 'true') ? true : false
    if target
      @like = current_user.build_like(positive, :on => target)

      if @like.save
        Rails.logger.info("event=create type=like user=#{current_user.diaspora_handle} status=success like=#{@like.id} positive=#{positive}")
        Postzord::Dispatch.new(current_user, @like).post

        respond_to do |format|
          format.js { render :status => 201 }
          format.html { render :nothing => true, :status => 201 }
          format.mobile { redirect_to status_message_path(@like.post_id) }
        end
      else
        render :nothing => true, :status => 422
      end
    else
      render :nothing => true, :status => 422
    end
  end

  def destroy
    if @like = Like.where(:post_id => params[:post_id], :author_id => current_user.person.id).first
      current_user.retract(@like)
    else
      respond_to do |format|
        format.mobile {redirect_to :back}
        format.js {render :nothing => true, :status => 403}
      end
    end
  end
end
