# encoding: utf-8
class Book < ActiveRecord::Base
  extend Enumerize
  extend SortUtils

  enumerize :category, in: [:art, :computer, :politics_religion, :fiction,
                            :history_biography, :business_money, :psycology,
                            :parenting_child, :travel, :language, :other]

  enumerize :status, in: [:active, :inactive, :recommend], default: :active
  enumerize :language, in: [:chinese, :english], default: :chinese
  
  has_many :borrows
  has_many :users, through: :borrows
  has_many :orders
  has_many :users, through: :orders
  
  validates :isbn, uniqueness: { case_sensitive: false }
  validates :total, numericality: { only_integer: true }
  validates :category, :name, presence: true
  validate :total_greater_than_borrowing, on: :update #when update total, cannot be less than current borrowing
  validate :store_not_greater_than_total, on: :update

  before_update :change_store_count
  before_create :set_store_count


  def self.search(search)
    if search.present?
      if /^\d{1,4}$/.match(search) != nil ## search for book id
        where('id = ? or name like ?',"#{search}","%#{search}%")
      elsif (map_category_name = convert_category_translation(search)) != nil
        where('category = ? or name like ? or tag like ?', map_category_name,"%#{search}%","%#{search}%")
      else
        where('name like ? or author like ? or isbn like ? or category like ? or press like ? or tag like ? or provider like ?',
         "%#{search}%","%#{search}%","%#{search}%","%#{search}%","%#{search}%","%#{search}%","%#{search}%")
      end
    else
      all
    end
  end

  def self.sort(sort_type)
    if sort_type.present? && sort_types.include?(sort_type.to_sym)
      sort_condition = parse_sort_type(sort_type)
      order(sort_condition)
    else
      all.order(created_at: :desc)
    end
  end

  def self.sort_types
    [:language_desc, :total_desc, :price_desc, :id_asc, :category_asc]
  end

  def order_queue_count
    Order.count(conditions: "status = '#{:in_queue}' and book_id = #{self.id}")
  end

  def self.convert_category_translation(search)
    Book.category.options.each do |pair|
      if (pair[0] =~ /#{search}/) != nil
        return pair[1]
      end
    end
    nil
  end

  def self.new_book_list
    Book.order("created_at DESC")[0..5]
  end

  def self.hot_list
    sql = %Q| select boo.* from books boo 
                    join borrows bor on book_id = boo.id 
                    group by boo.id 
                    order by count(boo.id)/boo.total desc
            |
    Book.find_by_sql(sql)[0..5]
  end

   def self.recent_hot_list
    sql = %Q| select boo.* from books boo 
               join borrows bor on bor.book_id = boo.id 
                 and bor.created_at >= ? 
                 and bor.created_at <= ?
               left join orders ord on ord.book_id = boo.id 
                 and ord.created_at >= ? 
                 and ord.created_at <= ?
               group by boo.id 
               order by count(boo.id) desc
            |
    now = Time.now
    three_months_ago = Time.now - 3.months
    Book.find_by_sql([sql, three_months_ago, now, three_months_ago, now])[0..5]
  end

  def borrow_conditions
    borrows = self.borrowing_list 
    results = Array.new
    borrows.each do |borrow|
      hash = {}
      hash[:user_name] = borrow.user.name
      hash[:borrow_date] = borrow.created_at.to_formatted_s(:Y_m_D)
      hash[:expected_date] = borrow.should_return_date != nil ? borrow.should_return_date.to_formatted_s(:Y_m_D) : '未出库'
      results << hash
    end
    results
  end

  def borrowing_list 
    self.borrows.without_status(:returned).order(created_at: :asc)
  end

  def order_conditions
    orders = self.ordering_list
    results = Array.new
    orders.each do |order|
      hash = {}
      hash[:user_name] = order.user.name
      hash[:order_date] = order.created_at.to_formatted_s(:Y_m_D)
      results << hash
    end
    results
  end

  def ordering_list 
    self.orders.where("status = :status", {status: :in_queue}).order(created_at: :asc)
  end

  def change_store_count
    if total != total_was
      delta = total - total_was
      self.store = delta + store_was
    end
  end

  def set_store_count
    self.store = self.total
    self.point = 0
  end

  def total_greater_than_borrowing
    if total < total_was
      borrows = borrowing_list
      if total < borrows.count
        errors.add(:base, '总数不能小于当前出借数量')
      end
    end
  end

  def store_not_greater_than_total
    if total == total_was
      if store > total 
        errors.add(:base, '非法操作，库存将会大于总数')
      end
    end
  end

end
