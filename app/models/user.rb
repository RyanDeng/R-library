# encoding: utf-8
class User < ActiveRecord::Base
  extend Enumerize

  enumerize :role, in: [:reader, :admin, :super_admin], default: :reader, predicates: true, scope: true
  enumerize :status, in: [:active, :inactive], scope: true, default: :active, predicates: true

  has_many :borrows
  has_many :books, through: :borrows
  has_many :orders
  has_many :books, through: :orders
  
  #before_create :create_token
  #before_validation :default_password
  before_save { self.email = email.downcase }

  scope :on_board, -> { with_status(:active)  }
  
  validates :email, :name, :status, presence: true
  validates :email, uniqueness: { case_sensitive: false }

  def overdue_books
    self.borrows.where("should_return_date < ?", Time.now)
  end
  
 #  def User.new_remember_token
	# SecureRandom.urlsafe_base64
 #  end

 #  def User.encrypt(token)
	# Digest::SHA1.hexdigest(token.to_s)
 #  end

  def self.create(name)
    user = User.new
    user.name = name
    user.email = name + "@qiniu.com"
    if SUPERADMINS.include? name
      user.role = :super_admin
    end
    user.save
  end

  def self.search(search, page)
    if search.present?
      if (map_role_name = convert_role_translation(search)).nil?
        where('name like ? or team like ? or email like ? or office = ? ',
           "%#{search}%","%#{search}%","%#{search}%","#{search}").paginate(page: page, per_page: BOOK_PER_PAGE)
      else
        where('role = ?', map_role_name).paginate(page: page, per_page: BOOK_PER_PAGE)
      end
    else
      paginate(page: page, per_page: BOOK_PER_PAGE)
    end
  end

  def self.convert_role_translation(search)
    User.role.options.each do |pair|
      if pair[0] == search
        return pair[1]
      end
    end
    nil
  end

  def display_name
    self.name
  end

  def display_location
    self.office.to_s
  end

  def has_admin_authe
    self.admin? || self.super_admin?
  end

  def restrict_total_borrow_order
    borrow_count = self.borrows.with_status(:borrowing, :undelivery).count
    order_count = self.orders.with_status(:in_queue).count
    (borrow_count + order_count) >= 5 ? '同时借阅预订书籍的数量,最多为5本' : ''
  end

  private
  	# def create_token
  	# 	self.remember_token = User.encrypt(User.new_remember_token)
  	# end

    # def default_password
    #   if self.new_record?    
    #     if self.super_admin?
    #       self.password = User::SUPER_ADMIN_PASSWD
    #       self.password_confirmation = User::SUPER_ADMIN_PASSWD
    #     elsif self.admin?
    #       self.password = User::ADMIN_PASSWD
    #       self.password_confirmation = User::ADMIN_PASSWD
    #     else
    #       self.password = User::DEFAULT_PASSWD
    #       self.password_confirmation = User::DEFAULT_PASSWD
    #     end
    #   end
    # end
  end
