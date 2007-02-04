class Group < ActiveRecord::Base
	has_and_belongs_to_many :user
	has_many :user_group_links

def self.users_in_group group
    return User.find_by_sql(<<-"SQL"
        select users.* from users,groups_users,groups
        where users.id = groups_users.user_id and 
        groups_users.group_id = groups.id and 
        groups.group_name= '#{group}' and 
        groups_users.approved = true and
        users.account_suspended = false
        order by users.last_name;
        SQL
        )
end

def self.users_in_group_cond group,condition
    return User.find_by_sql(<<-"SQL"
        select users.* from users,groups_users,groups
        where users.id = groups_users.user_id and 
        groups_users.group_id = groups.id and 
        groups.group_name= '#{group}' and 
        groups_users.approved = true and
        users.account_suspended = false and
        #{condition}
        order by users.last_name;
        SQL
        )
end


end
