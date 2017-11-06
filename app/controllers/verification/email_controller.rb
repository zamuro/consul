class Verification::EmailController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_verified!
  before_action :set_verified_user, only: :create
  skip_authorization_check

  def show
    if Verification::Email.find(current_user, params[:email_verification_token])
      current_user.update(verified_at: Time.current)
      redirect_to account_path, notice: t('verification.email.show.flash.success')
    else
      redirect_to verified_user_path, alert: t('verification.email.show.alert.failure')
    end
  end

  def date_of_birth
    @user = current_user
  end

  def save_date_of_birth
    user = User.where(id: params[:id]).first
    if correct_date?
      user.date_of_birth = Date.new(date_of_birth_params[:year].to_i, date_of_birth_params[:month].to_i, date_of_birth_params[:day].to_i)
      user.save
      redirect_to email_path(email_verification_token: params[:email_verification_token])
    else
      redirect_to date_of_birth_email_path(email_verification_token: params[:email_verification_token], id: params[:id]), flash: { error: t('verification.email.date.error') }
    end
  end

  def create
    @email = Verification::Email.new(@verified_user)
    if @email.save
      current_user.reload
      Mailer.email_verification(current_user,
                                @email.recipient,
                                @email.encrypted_token,
                                @verified_user.document_type,
                                @verified_user.document_number).deliver_later
      redirect_to account_path, notice: t('verification.email.create.flash.success', email: @verified_user.email)
    else
      redirect_to verified_user_path, alert: t('verification.email.create.alert.failure')
    end
  end

  private

    def set_verified_user
      @verified_user = VerifiedUser.by_user(current_user).where(id: verified_user_params[:id]).first
    end

    def verified_user_params
      params.require(:verified_user).permit(:id)
    end

    def date_of_birth_params
      params.require(:date).permit(:day, :month, :year)
    end

    def correct_date?
      date_of_birth_params[:year].to_i.positive? && date_of_birth_params[:month].to_i.positive? && date_of_birth_params[:day].to_i.positive?
    end
end
