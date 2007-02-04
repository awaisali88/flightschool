class BillingCharge < ActiveRecord::Base

  belongs_to :pilot,
      :class_name => 'User',
      :foreign_key => 'user_id'

  belongs_to :creator,
      :class_name => 'User',
      :foreign_key => 'created_by'

  belongs_to :instructor,
      :class_name => 'User',
      :foreign_key => 'instructor_id'

  belongs_to :aircraft,
      :class_name => 'Aircraft',
      :foreign_key => 'aircraft_id'
    
  validates_presence_of :user_id
  validates_presence_of :charge_amount
  validates_presence_of :type
  
  
  def initialize(params={},user=nil)
    params.merge!(:created_by=>(user==nil ? nil : user.id))
    super(params)
    if params[:type]!=nil
      @attributes["type"] = params[:type]
    end
  end
    
end
