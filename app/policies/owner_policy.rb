class OwnerPolicy < ApplicationPolicy
  def index?
    user.admin? || user.vet?
  end

  def show?
    user.admin? || user.vet? || own_record?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin? || own_record?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

  def permitted_attributes
    [ :first_name, :last_name, :email, :phone, :address ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.vet?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def own_record?
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
