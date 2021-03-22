class InquiryController < ApplicationController
  def index
    @inquiry = Inquiry.new
    render :action => 'index'
  end

  def confirm
    # 入力値のチェック
    @inquiry = Inquiry.new(params[:inquiry].permit(:name, :email, :message))
    if @inquiry.valid?
      # OK。確認画面を表示
      render :action => 'confirm'
    else
      # NG。入力画面を再表示
      render :action => 'index'
    end
  end

  def thanks
    # メール送信
    @inquiry = Inquiry.new(params[:inquiry].permit(:name, :email, :message))
    # 管理者に送信
    InquiryMailer.received_email(@inquiry).deliver
    # お問い合わせ者に送信
    #InquiryMailer.send_email(@inquiry).deliver
    # 完了画面を表示
    render :action => 'thanks'
  end
end