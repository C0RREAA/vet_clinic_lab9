class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [ :show, :edit, :update, :destroy ]

  def index
    @appointments = policy_scope(Appointment).includes(:pet, :vet)
  end

  def show
    authorize @appointment
    @appointment = Appointment
      .includes(:pet, :vet, treatments: :rich_text_clinical_notes)
      .find(@appointment.id)
  end

  def new
    @appointment = Appointment.new
    authorize @appointment
  end

  def create
    @appointment = Appointment.new(permitted_attributes(Appointment.new))
    # Vet-role users can't set vet_id (filtered by policy); force to their own Vet.
    if current_user.vet? && current_user.vet
      @appointment.vet = current_user.vet
    end
    authorize @appointment
    if @appointment.save
      redirect_to @appointment, notice: "Appointment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @appointment
  end

  def update
    authorize @appointment
    if @appointment.update(permitted_attributes(@appointment))
      redirect_to @appointment, notice: "Appointment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @appointment
    @appointment.destroy
    redirect_to appointments_path, notice: "Appointment was successfully destroyed."
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end
end
