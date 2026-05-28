# Wipe non-user data so the rest of this file is idempotent.
# Users are seeded via find_or_create_by below so they can be re-run safely.
Treatment.destroy_all
Appointment.destroy_all
Pet.destroy_all
Owner.destroy_all
Vet.destroy_all

PHOTO_DIR = Rails.root.join("db", "seeds", "pets")

def attach_photo(pet, filename)
  path = PHOTO_DIR.join(filename)
  return unless File.exist?(path)

  pet.photo.attach(
    io:           File.open(path),
    filename:     filename,
    content_type: "image/jpeg"
  )
end

# ── Users (auth) ────────────────────────────────────────
USERS = [
  { email: "admin@vetclinic.com",  first_name: "Admin",  last_name: "User",     role: :admin },
  { email: "vet@vetclinic.com",    first_name: "Jane",   last_name: "Smith",    role: :vet },
  { email: "vet2@vetclinic.com",   first_name: "Carlos", last_name: "Mendoza",  role: :vet },
  { email: "owner@vetclinic.com",  first_name: "John",   last_name: "Doe",      role: :owner },
  { email: "owner2@vetclinic.com", first_name: "Maria",  last_name: "García",   role: :owner }
].map do |attrs|
  user = User.find_or_create_by!(email: attrs[:email]) do |u|
    u.first_name = attrs[:first_name]
    u.last_name  = attrs[:last_name]
    u.role       = attrs[:role]
    u.password   = "password123"
    u.password_confirmation = "password123"
  end
  user.update!(first_name: attrs[:first_name], last_name: attrs[:last_name], role: attrs[:role])
  user
end

admin_user, vet_user, vet2_user, owner_user, owner2_user = USERS

# Clear any leftover linkage from previous seed runs (re-seed safety).
Owner.update_all(user_id: nil)
Vet.update_all(user_id: nil)

# ── Vets (linked to vet-role users) ─────────────────────
dr_smith = Vet.create!(
  user:           vet_user,
  first_name:     "Jane",
  last_name:      "Smith",
  email:          "j.smith@vetclinic.cl",
  phone:          "+56922233344",
  specialization: "Medicina General"
)

dr_mendoza = Vet.create!(
  user:           vet2_user,
  first_name:     "Carlos",
  last_name:      "Mendoza",
  email:          "c.mendoza@vetclinic.cl",
  phone:          "+56933344455",
  specialization: "Cirugía"
)

# ── Owners (linked to owner-role users) ─────────────────
john = Owner.create!(
  user:       owner_user,
  first_name: "John",
  last_name:  "Doe",
  email:      "john.doe@email.com",
  phone:      "+56912345678",
  address:    "Av. Providencia 1234, Santiago"
)

maria = Owner.create!(
  user:       owner2_user,
  first_name: "Maria",
  last_name:  "García",
  email:      "maria.garcia@email.com",
  phone:      "+56987654321",
  address:    "Los Leones 567, Vitacura"
)

# An owner record with no associated user (legacy/walk-in customer).
lucia = Owner.create!(
  user:       nil,
  first_name: "Lucía",
  last_name:  "Fernández",
  email:      "lucia.fernandez@email.com",
  phone:      "+56955544433",
  address:    "Calle Nueva 89, Ñuñoa"
)

# ── Pets ────────────────────────────────────────────────
firulais = john.pets.create!(
  name: "Firulais", species: "dog", breed: "Labrador",
  date_of_birth: "2019-03-15", weight: 28.5
)
attach_photo(firulais, "dog1.jpg")

michi = john.pets.create!(
  name: "Michi", species: "cat", breed: "Siamés",
  date_of_birth: "2021-07-20", weight: 4.2
)
attach_photo(michi, "cat1.jpg")

luna = maria.pets.create!(
  name: "Luna", species: "cat", breed: "Persa",
  date_of_birth: "2020-05-30", weight: 3.8
)
attach_photo(luna, "cat2.jpg")

toby = maria.pets.create!(
  name: "Toby", species: "dog", breed: "Beagle",
  date_of_birth: "2023-02-14", weight: 12.0
)
attach_photo(toby, "dog2.jpg")

# Lucía's pets (no associated user, only an admin can manage them).
rex = lucia.pets.create!(
  name: "Rex", species: "dog", breed: "Pastor Alemán",
  date_of_birth: "2018-11-05", weight: 35.0
)
attach_photo(rex, "dog3.jpg")

bunny = lucia.pets.create!(
  name: "Bunny", species: "rabbit", breed: "Holland Lop",
  date_of_birth: "2022-01-10", weight: 2.1
)

# ── Appointments ────────────────────────────────────────
a1 = Appointment.create!(
  pet: firulais, vet: dr_smith,
  date: "2024-11-10 10:00:00", reason: "Control anual y vacunas",
  status: :completed
)

a2 = Appointment.create!(
  pet: michi, vet: dr_mendoza,
  date: "2024-12-05 11:30:00", reason: "Castración",
  status: :completed
)

a3 = Appointment.create!(
  pet: luna, vet: dr_smith,
  date: "2025-01-15 09:00:00", reason: "Revisión dermatológica",
  status: :in_progress
)

a4 = Appointment.create!(
  pet: toby, vet: dr_mendoza,
  date: "2026-06-20 14:00:00", reason: "Revisión general",
  status: :scheduled
)

a5 = Appointment.create!(
  pet: rex, vet: dr_smith,
  date: "2024-10-01 16:00:00", reason: "Lesión en cadera",
  status: :cancelled
)

# ── Treatments (rich-text clinical notes) ───────────────
a1.treatments.create!(
  name:            "Vacuna antirrábica",
  medication:      "Rabisin",
  dosage:          "1 ml IM",
  administered_at: "2024-11-10 10:30:00",
  clinical_notes:  <<~HTML
    <h2>Diagnosis</h2>
    <p>Annual rabies vaccination, no complications.</p>
    <h3>Observations</h3>
    <ul>
      <li><strong>Temperature:</strong> 38.5 °C (within normal range)</li>
      <li><strong>Heart rate:</strong> 90 bpm</li>
      <li><strong>Reaction:</strong> none observed during 15-minute monitoring window</li>
    </ul>
    <p><em>Next dose due in 12 months.</em></p>
  HTML
)

a1.treatments.create!(
  name:            "Desparasitación",
  medication:      "Drontal Plus",
  dosage:          "1 comprimido",
  administered_at: "2024-11-10 10:45:00",
  clinical_notes:  <<~HTML
    <h2>Treatment</h2>
    <p>Oral broad-spectrum antiparasitic administered without incident.</p>
    <ul>
      <li><strong>Targets:</strong> roundworm, hookworm, tapeworm</li>
      <li><strong>Schedule:</strong> repeat every 3 months</li>
    </ul>
  HTML
)

a2.treatments.create!(
  name:            "Castración",
  medication:      "Propofol + Isoflurano",
  dosage:          "Según peso corporal",
  administered_at: "2024-12-05 12:00:00",
  clinical_notes:  <<~HTML
    <h2>Surgical report</h2>
    <p>Routine feline neuter procedure completed successfully.</p>
    <h3>Post-op plan</h3>
    <ul>
      <li><strong>Day 1-3:</strong> indoor rest, cone collar at all times</li>
      <li><strong>Day 7:</strong> incision check</li>
      <li><strong>Pain control:</strong> meloxicam 0.05 mg/kg PO once daily for 3 days</li>
    </ul>
  HTML
)

a3.treatments.create!(
  name:            "Antiinflamatorio",
  medication:      "Meloxicam",
  dosage:          "0.1 mg/kg",
  administered_at: "2025-01-15 09:30:00",
  clinical_notes:  <<~HTML
    <h2>Findings</h2>
    <p>Mild <strong>dermatitis</strong> on the back; intermittent scratching.</p>
    <h3>Next steps</h3>
    <ul>
      <li>Topical anti-itch shampoo, twice weekly</li>
      <li>Re-evaluate in <strong>2 weeks</strong></li>
    </ul>
  HTML
)

a3.treatments.create!(
  name:            "Radiografía",
  medication:      "N/A",
  dosage:          "N/A",
  administered_at: "2025-01-15 09:15:00",
  clinical_notes:  <<~HTML
    <h2>Imaging report</h2>
    <p>No bone abnormalities on the lateral or ventro-dorsal projections.</p>
    <ul>
      <li>Spine: normal alignment</li>
      <li>Hip joints: normal</li>
      <li>Recommendation: focus on skin-level treatment</li>
    </ul>
  HTML
)

puts "✅ Seed completado:"
puts "  Users:        #{User.count} (#{User.group(:role).count})"
puts "  Owners:       #{Owner.count} (linked to users: #{Owner.where.not(user_id: nil).count})"
puts "  Vets:         #{Vet.count} (linked to users: #{Vet.where.not(user_id: nil).count})"
puts "  Pets:         #{Pet.count} (with photos: #{Pet.joins(:photo_attachment).count})"
puts "  Appointments: #{Appointment.count}"
puts "  Treatments:   #{Treatment.count}"
