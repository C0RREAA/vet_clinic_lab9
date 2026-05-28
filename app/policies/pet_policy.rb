class PetPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || user.vet? || owned_by_user?
  end

  def create?
    user.admin? || user.owner?
  end

  def new?
    create?
  end

  def update?
    user.admin? || owned_by_user?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || owned_by_user?
  end

  def permitted_attributes
    base = [ :name, :species, :breed, :date_of_birth, :weight, :photo ]
    base << :owner_id if user.admin?
    base
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.vet?
        scope.all
      else
        scope.joins(:owner).where(owners: { user_id: user.id })
      end
    end
  end

  private

  def owned_by_user?
    record.owner && record.owner.user_id == user.id
  end
end
