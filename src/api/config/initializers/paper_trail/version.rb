module PaperTrail
  class Version < ActiveRecord::Base
    def user
      User.find_by(login: self.whodunnit)
    end
  end
end
