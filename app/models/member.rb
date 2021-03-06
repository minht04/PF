class Member < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable

  validates :name, length: { maximum: 20 }, uniqueness: true, presence: true
  validates :introduction, length: { maximum: 50 }

  has_many :sns_credentials, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  # ユーザーのいいねを取得
  has_many :favorites, dependent: :destroy
  # ユーザーのマイページにユーザーがいいねしたもの表示させるため
  has_many :favorite_posts, through: :favorites, source: :post
  attachment :profile_image

  # 通知機能
  has_many :active_notifications, class_name: 'Notification', foreign_key: 'visitor_id', dependent: :destroy    # 自分からの通知
  has_many :passive_notifications, class_name: 'Notification', foreign_key: 'visited_id', dependent: :destroy   # 相手からの通知

  # フォローしている人取得
  has_many :follower, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy
  # フォローされている人取得
  has_many :followed, class_name: 'Relationship', foreign_key: 'followed_id', dependent: :destroy
  # 自分がフォローしている人
  has_many :following_member, through: :follower, source: :followed
  # 自分がフォローされている人
  has_many :follower_member, through: :followed, source: :follower

  # フォローする
  def follow(member_id)
    follower.create(followed_id: member_id)
  end

  # フォローを外す
  def unfollow(member_id)
    follower.find_by(followed_id: member_id).destroy
  end

  # すでにフォローしているかの確認
  def following?(member)
    following_member.include?(member)
  end

  # 通知機能
  def create_notification_follow!(current_member)
    temp = Notification.where(['visitor_id = ? and visited_id = ? and action = ? ', current_member.id, id, 'follow'])
    if temp.blank?
      notification = current_member.active_notifications.new(
        visited_id: id,
        action: 'follow'
      )
      notification.save if notification.valid?
    end
  end

  def self.guest
    find_or_create_by!(name: 'ゲスト', email: 'guest@example.com') do |member|
      member.password = SecureRandom.urlsafe_base64
    end
  end

  # SNS認証
  # uid:プロバイダーに固有の識別子
  # provider:プロバイダー(google)
  def self.without_sns_data(auth)
    member = Member.where(email: auth.info.email).first

    if member.present?
      sns = SnsCredential.create(
        uid: auth.uid,
        provider: auth.provider,
        member_id: member.id
      )
    else
      member = Member.new(
        name: auth.info.name,
        email: auth.info.email
      )
      sns = SnsCredential.new(
        uid: auth.uid,
        provider: auth.provider
      )
    end
    { member: member, sns: sns }
  end

  def self.with_sns_data(auth, snscredential)
    member = Member.where(id: snscredential.member_id).first
    if member.blank?
      member = Member.new(
        name: auth.info.name,
        email: auth.info.email
      )
    end
    { member: member }
  end

  # SNSから取得したproviderとuidを使って既存ユーザーを検索
  def self.find_oauth(auth)
    uid = auth.uid
    provider = auth.provider
    snscredential = SnsCredential.where(uid: uid, provider: provider).first # SNS認証したことがあればアソシエーションで取得
    if snscredential.present?
      member = with_sns_data(auth, snscredential)[:member]
      sns = snscredential
    else
      member = without_sns_data(auth)[:member]
      sns = without_sns_data(auth)[:sns]
    end
    { member: member, sns: sns }   # コントローラーがこれを受け取る
  end
end
