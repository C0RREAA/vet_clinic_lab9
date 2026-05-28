class TreatmentsController < ApplicationController
  before_action :set_appointment
  before_action :set_treatment, only: [ :edit, :update, :destroy ]

  def new
    @treatment = @appointment.treatments.build
    authorize @treatment
  end

  def create
    @treatment = @appointment.treatments.build(permitted_attributes(@appointment.treatments.build))
    authorize @treatment
    if @treatment.save
      redirect_to @appointment, notice: "Treatment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @treatment
  end

  def update
    authorize @treatment
    if @treatment.update(permitted_attributes(@treatment))
      redirect_to @appointment, notice: "Treatment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @treatment
    @treatment.destroy
    redirect_to @appointment, notice: "Treatment was successfully destroyed."
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  end

  def set_treatment
    @treatment = @appointment.treatments.find(params[:id])
  end
end
