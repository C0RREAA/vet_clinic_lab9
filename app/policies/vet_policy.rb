class VetPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
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
    [ :first_name, :last_name, :email, :phone, :specialization ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def own_record?
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
