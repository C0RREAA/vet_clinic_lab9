class PetsController < ApplicationController
  before_action :set_pet, only: [ :show, :edit, :update, :destroy ]

  def index
    @pets = policy_scope(Pet).includes(:owner)
  end

  def show
    authorize @pet
  end

  def new
    @pet = Pet.new
    authorize @pet
  end

  def create
    @pet = Pet.new(permitted_attributes(Pet.new))
    # Owner-role users can't set owner_id (filtered by policy).
    # We force the pet to belong to their own Owner record.
    if current_user.owner? && current_user.owner
      @pet.owner = current_user.owner
    end
    authorize @pet
    if @pet.save
      redirect_to @pet, notice: "Pet was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @pet
  end

  def update
    authorize @pet
    if @pet.update(permitted_attributes(@pet))
      redirect_to @pet, notice: "Pet was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pet
    @pet.destroy
    redirect_to pets_path, notice: "Pet was successfully destroyed."
  end

  private

  def set_pet
    @pet = Pet.find(params[:id])
  end
end
