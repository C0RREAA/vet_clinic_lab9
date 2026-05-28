class AppointmentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || assigned_vet? || pet_owner?
  end

  def create?
    user.admin? || assigned_vet? || pet_owner?
  end

  def new?
    user.admin? || user.vet? || user.owner?
  end

  def update?
    user.admin? || assigned_vet? || pet_owner?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || assigned_vet? || pet_owner?
  end

  def permitted_attributes_for_create
    if user.admin?
      [ :date, :reason, :status, :pet_id, :vet_id ]
    elsif user.vet?
      # Vet creates: can pick pet, vet_id is forced server-side to themselves.
      [ :date, :reason, :status, :pet_id ]
    else
      # Owner creates: must pick one of their own pets and any vet.
      [ :date, :reason, :status, :pet_id, :vet_id ]
    end
  end

  def permitted_attributes_for_update
    if user.admin?
      [ :date, :reason, :status, :pet_id, :vet_id ]
    elsif user.vet?
      # Vet can't change vet_id.
      [ :date, :reason, :status, :pet_id ]
    else
      # Owner can't change pet_id.
      [ :date, :reason, :status, :vet_id ]
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.vet?
        scope.joins(:vet).where(vets: { user_id: user.id })
      else
        scope.joins(pet: :owner).where(owners: { user_id: user.id })
      end
    end
  end

  private

  def assigned_vet?
    record.respond_to?(:vet) && record.vet && record.vet.user_id == user.id
  end

  def pet_owner?
    record.respond_to?(:pet) && record.pet && record.pet.owner && record.pet.owner.user_id == user.id
  end
end
