class TreatmentPolicy < ApplicationPolicy
  def create?
    user.admin? || assigned_vet?
  end

  def new?
    create?
  end

  def update?
    user.admin? || assigned_vet?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || assigned_vet?
  end

  def permitted_attributes
    [ :name, :medication, :dosage, :administered_at, :clinical_notes ]
  end

  private

  def assigned_vet?
    return false unless record.respond_to?(:appointment) && record.appointment
    return false unless record.appointment.vet
    record.appointment.vet.user_id == user.id
  end
end
