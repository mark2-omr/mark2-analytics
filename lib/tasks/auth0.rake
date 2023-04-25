namespace :auth0 do
  task update_unknown_uid_users: :environment do
    User.where(uid: nil).each do |user|
      user.create_auth0_user
      user.save

      p user
      sleep 1
    end
  end
end
