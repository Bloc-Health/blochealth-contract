// SPDX-License-Identifier: MIT
#[starknet::contract]
mod BlocHealth {
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::Map;
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use core::zeroable::NonZero;
    use traits::Into;
    use traits::TryInto;
    use core::result::ResultTrait;

    // Constants
    const ZERO_ADDRESS: felt252 = 0;

    // Enums
    #[derive(Copy, Drop, Serde, PartialEq)]
    enum AccessRole {
        Doctor: (),
        Staff: (),
        Nurse: (),
        Admin: ()
    }

    #[derive(Copy, Drop, Serde, PartialEq)]
    enum Gender {
        Male: (),
        Female: (),
        Other: ()
    }

    // Structs
    #[derive(Drop, Serde, starknet::Store)]
    struct MedicalInfo {
        current_medications: ByteArray,
        allergies: ByteArray,
        medical_file_link: ByteArray
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct EmergencyContact {
        name: ByteArray,
        relationship: ByteArray,
        phone: ByteArray,
        email: ByteArray,
        address: ByteArray
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct ContactInfo {
        email: ByteArray,
        phone: ByteArray,
        address: ByteArray,
        next_of_kin_name: ByteArray,
        next_of_kin_phone: ByteArray,
        next_of_kin_email: ByteArray
    }

    #[derive(Drop, Serde)]
    struct Staff {
        name: ByteArray,
        role: AccessRole,
        email: ByteArray,
        phone: ByteArray
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct Appointment {
        date: u64,
        reason: ByteArray,
        diagnosis: ByteArray,
        treatment: ByteArray,
        doctor: ContractAddress
    }

    #[derive(Drop, Serde)]
    struct Patient {
        id: ByteArray,
        name: ByteArray,
        date_of_birth: u64,
        gender: Gender,
        contact_info: ContactInfo,
        medical_info: MedicalInfo,
        emergency_contacts: Array<EmergencyContact>,
        appointments: Array<Appointment>
    }

    #[derive(Drop, Serde)]
    struct PatientReturnInfo {
        id: ByteArray,
        name: ByteArray,
        date_of_birth: u64,
        gender: Gender,
        contact_info: ContactInfo,
        medical_info: MedicalInfo,
        emergency_contacts: Array<EmergencyContact>,
        appointments: Array<Appointment>
    }

    #[derive(Drop, Serde)]
    struct Hospital {
        name: ByteArray,
        location: ByteArray,
        registration_number: ByteArray,
        owner: ContractAddress,
        staff_count: u32,
        patient_count: u32
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        HospitalCreated: HospitalCreated,
        HospitalStaffRoleUpdated: HospitalStaffRoleUpdated,
        PatientCreated: PatientCreated,
        VisitRecordCreated: VisitRecordCreated
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalCreated {
        hospital_id: ByteArray,
        name: ByteArray,
        owner: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalStaffRoleUpdated {
        hospital_id: ByteArray,
        staff_address: ContractAddress,
        role: AccessRole
    }

    #[derive(Drop, starknet::Event)]
    struct PatientCreated {
        hospital_id: ByteArray,
        patient_id: ByteArray,
        name: ByteArray
    }

    #[derive(Drop, starknet::Event)]
    struct VisitRecordCreated {
        hospital_id: ByteArray,
        patient_id: ByteArray,
        date: u64,
        doctor: ContractAddress
    }

    // Errors
    #[derive(Drop, starknet::Event)]
    struct HospitalDoesNotExistError {
        hospital_id: ByteArray
    }

    #[derive(Drop, starknet::Event)]
    struct NotHospitalOwnerError {
        caller: ContractAddress,
        owner: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct InvalidAddressError {
        address: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct StaffDoesNotExistError {
        hospital_id: ByteArray,
        staff_address: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct PatientDoesNotExistError {
        hospital_id: ByteArray,
        patient_id: ByteArray
    }

    #[derive(Drop, starknet::Event)]
    struct UnauthorizedRoleError {
        caller: ContractAddress,
        required_role: AccessRole
    }

    // Storage
    #[storage]
    struct Storage {
        owner: ContractAddress,
        hospital_count: u32,
        hospitals: Map<ByteArray, Hospital>,
        hospital_staff_roles: Map<(ByteArray, ContractAddress), AccessRole>,
        hospital_patients: Map<(ByteArray, ByteArray), Patient>,
        hospital_patient_addresses: Map<ByteArray, Array<ByteArray>>
    }

    // Constructor
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
        self.hospital_count.write(0);
    }

    // Modifiers and helper functions
    fn is_valid_address(address: ContractAddress) -> bool {
        address.is_non_zero()
    }

    fn hospital_exists(self: @ContractState, hospital_id: ByteArray) -> bool {
        !self.hospitals.read(hospital_id).name.is_empty()
    }

    fn only_hospital_owner(self: @ContractState, hospital_id: ByteArray) -> bool {
        let caller = get_caller_address();
        let hospital = self.hospitals.read(hospital_id);
        
        if hospital.owner != caller && caller != self.owner.read() {
            return false;
        }
        
        true
    }

    fn hospital_staff_exists(self: @ContractState, hospital_id: ByteArray, staff_address: ContractAddress) -> bool {
        let role = self.hospital_staff_roles.read((hospital_id, staff_address));
        // Check if role is set
        match role {
            AccessRole::Doctor(_) | AccessRole::Staff(_) | AccessRole::Nurse(_) | AccessRole::Admin(_) => true,
            _ => false
        }
    }

    fn patient_exists(self: @ContractState, hospital_id: ByteArray, patient_id: ByteArray) -> bool {
        !self.hospital_patients.read((hospital_id, patient_id)).id.is_empty()
    }

    fn is_authorized_role(self: @ContractState, hospital_id: ByteArray, allowed_roles: Array<AccessRole>) -> bool {
        let caller = get_caller_address();
        
        // Contract owner is always authorized
        if caller == self.owner.read() {
            return true;
        }
        
        // Hospital owner is always authorized
        let hospital = self.hospitals.read(hospital_id);
        if caller == hospital.owner {
            return true;
        }
        
        // Check if caller has one of the allowed roles
        let caller_role = self.hospital_staff_roles.read((hospital_id, caller));
        
        // Iterate through allowed roles and check if caller's role matches
        let mut i = 0;
        let len = allowed_roles.len();
        
        while i < len {
            if caller_role == *allowed_roles.at(i) {
                return true;
            }
            i += 1;
        }
        
        false
    }

    // Implementation
    #[external(v0)]
    impl BlocHealthImpl of super::IBlocHealth<ContractState> {
        // Hospital Functions
        fn add_hospital(
            ref self: ContractState,
            hospital_id: ByteArray,
            name: ByteArray,
            location: ByteArray,
            registration_number: ByteArray
        ) {
            let caller = get_caller_address();
            assert(is_valid_address(caller), "Invalid caller address");
            
            // Ensure hospital doesn't already exist
            assert(!hospital_exists(@self, hospital_id), "Hospital already exists");
            
            // Create hospital
            let hospital = Hospital {
                name: name,
                location: location,
                registration_number: registration_number,
                owner: caller,
                staff_count: 0,
                patient_count: 0
            };
            
            self.hospitals.write(hospital_id, hospital);
            
            // Initialize patient addresses array
            let patient_addresses = ArrayTrait::<ByteArray>::new();
            self.hospital_patient_addresses.write(hospital_id, patient_addresses);
            
            // Increment hospital count
            let count = self.hospital_count.read();
            self.hospital_count.write(count + 1);
            
            // Emit event
            self.emit(HospitalCreated {
                hospital_id: hospital_id,
                name: name,
                owner: caller
            });
        }

        fn change_hospital_owner(
            ref self: ContractState,
            hospital_id: ByteArray,
            new_owner: ContractAddress
        ) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            assert(is_valid_address(new_owner), "Invalid new owner address");
            assert(only_hospital_owner(@self, hospital_id), "Caller is not hospital owner");
            
            // Update hospital owner
            let mut hospital = self.hospitals.read(hospital_id);
            hospital.owner = new_owner;
            self.hospitals.write(hospital_id, hospital);
        }

        fn update_hospital_staff_roles(
            ref self: ContractState,
            hospital_id: ByteArray,
            staff_address: ContractAddress,
            role: AccessRole
        ) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            assert(is_valid_address(staff_address), "Invalid staff address");
            assert(only_hospital_owner(@self, hospital_id), "Caller is not hospital owner");
            
            // Update staff role
            self.hospital_staff_roles.write((hospital_id, staff_address), role);
            
            // Update staff count if this is a new staff member
            if !hospital_staff_exists(@self, hospital_id, staff_address) {
                let mut hospital = self.hospitals.read(hospital_id);
                hospital.staff_count += 1;
                self.hospitals.write(hospital_id, hospital);
            }
            
            // Emit event
            self.emit(HospitalStaffRoleUpdated {
                hospital_id: hospital_id,
                staff_address: staff_address,
                role: role
            });
        }

        fn delete_hospital(ref self: ContractState, hospital_id: ByteArray) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            assert(only_hospital_owner(@self, hospital_id), "Caller is not hospital owner");
            
            // Clear hospital data
            let empty_hospital = Hospital {
                name: ByteArray::new(),
                location: ByteArray::new(),
                registration_number: ByteArray::new(),
                owner: Zeroable::zero(),
                staff_count: 0,
                patient_count: 0
            };
            
            self.hospitals.write(hospital_id, empty_hospital);
            
            // Decrement hospital count
            let count = self.hospital_count.read();
            self.hospital_count.write(count - 1);
        }

        fn delete_hospital_staff(
            ref self: ContractState,
            hospital_id: ByteArray,
            staff_address: ContractAddress
        ) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            assert(is_valid_address(staff_address), "Invalid staff address");
            assert(only_hospital_owner(@self, hospital_id), "Caller is not hospital owner");
            assert(hospital_staff_exists(@self, hospital_id, staff_address), "Staff does not exist");
            
            // Remove staff role
            // In Cairo, we can't actually delete mapping entries, so we set it to a default value
            let role = AccessRole::Staff(());  // Using Staff as a default/empty role
            self.hospital_staff_roles.write((hospital_id, staff_address), role);
            
            // Update staff count
            let mut hospital = self.hospitals.read(hospital_id);
            hospital.staff_count -= 1;
            self.hospitals.write(hospital_id, hospital);
        }

        // Staff Functions
        fn is_hospital_staff(self: @ContractState, hospital_id: ByteArray) -> bool {
            let caller = get_caller_address();
            hospital_staff_exists(self, hospital_id, caller)
        }

        // Patient Functions
        fn create_patient_record(
            ref self: ContractState,
            hospital_id: ByteArray,
            patient_id: ByteArray,
            name: ByteArray,
            date_of_birth: u64,
            gender: Gender,
            contact_info: ContactInfo,
            medical_info: MedicalInfo,
            emergency_contacts: Array<EmergencyContact>
        ) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            
            // Check authorization - only doctors, nurses, and admins can create patients
            let mut allowed_roles = ArrayTrait::<AccessRole>::new();
            allowed_roles.append(AccessRole::Doctor(()));
            allowed_roles.append(AccessRole::Nurse(()));
            allowed_roles.append(AccessRole::Admin(()));
            
            assert(is_authorized_role(@self, hospital_id, allowed_roles), "Unauthorized role");
            
            // Create patient record
            let appointments = ArrayTrait::<Appointment>::new();
            
            let patient = Patient {
                id: patient_id,
                name: name,
                date_of_birth: date_of_birth,
                gender: gender,
                contact_info: contact_info,
                medical_info: medical_info,
                emergency_contacts: emergency_contacts,
                appointments: appointments
            };
            
            // Check if this is a new patient or an update
            let is_new = !patient_exists(@self, hospital_id, patient_id);
            
            // Update patient record
            self.hospital_patients.write((hospital_id, patient_id), patient);
            
            // If new patient, add to list and update count
            if is_new {
                let mut patient_addresses = self.hospital_patient_addresses.read(hospital_id);
                patient_addresses.append(patient_id);
                self.hospital_patient_addresses.write(hospital_id, patient_addresses);
                
                let mut hospital = self.hospitals.read(hospital_id);
                hospital.patient_count += 1;
                self.hospitals.write(hospital_id, hospital);
                
                // Emit event
                self.emit(PatientCreated {
                    hospital_id: hospital_id,
                    patient_id: patient_id,
                    name: name
                });
            }
        }

        fn add_patient_appointment(
            ref self: ContractState,
            hospital_id: ByteArray,
            patient_id: ByteArray,
            date: u64,
            reason: ByteArray,
            diagnosis: ByteArray,
            treatment: ByteArray
        ) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            assert(patient_exists(@self, hospital_id, patient_id), "Patient does not exist");
            
            // Check authorization - only doctors can add appointments
            let mut allowed_roles = ArrayTrait::<AccessRole>::new();
            allowed_roles.append(AccessRole::Doctor(()));
            
            assert(is_authorized_role(@self, hospital_id, allowed_roles), "Unauthorized role");
            
            // Get doctor address
            let doctor = get_caller_address();
            
            // Create appointment
            let appointment = Appointment {
                date: date,
                reason: reason,
                diagnosis: diagnosis,
                treatment: treatment,
                doctor: doctor
            };
            
            // Add appointment to patient record
            let mut patient = self.hospital_patients.read((hospital_id, patient_id));
            patient.appointments.append(appointment);
            self.hospital_patients.write((hospital_id, patient_id), patient);
            
            // Emit event
            self.emit(VisitRecordCreated {
                hospital_id: hospital_id,
                patient_id: patient_id,
                date: date,
                doctor: doctor
            });
        }

        fn get_patient_record(
            self: @ContractState,
            hospital_id: ByteArray,
            patient_id: ByteArray
        ) -> PatientReturnInfo {
            // Validate inputs
            assert(hospital_exists(self, hospital_id), "Hospital does not exist");
            assert(patient_exists(self, hospital_id, patient_id), "Patient does not exist");
            
            // Check authorization - all staff can view patient records
            let mut allowed_roles = ArrayTrait::<AccessRole>::new();
            allowed_roles.append(AccessRole::Doctor(()));
            allowed_roles.append(AccessRole::Nurse(()));
            allowed_roles.append(AccessRole::Admin(()));
            allowed_roles.append(AccessRole::Staff(()));
            
            assert(is_authorized_role(self, hospital_id, allowed_roles), "Unauthorized role");
            
            // Get patient record
            let patient = self.hospital_patients.read((hospital_id, patient_id));
            
            // Convert to PatientReturnInfo
            PatientReturnInfo {
                id: patient.id,
                name: patient.name,
                date_of_birth: patient.date_of_birth,
                gender: patient.gender,
                contact_info: patient.contact_info,
                medical_info: patient.medical_info,
                emergency_contacts: patient.emergency_contacts,
                appointments: patient.appointments
            }
        }

        fn get_all_patients(self: @ContractState, hospital_id: ByteArray) -> Array<PatientReturnInfo> {
            // Validate inputs
            assert(hospital_exists(self, hospital_id), "Hospital does not exist");
            
            // Check authorization - all staff can view patients
            let mut allowed_roles = ArrayTrait::<AccessRole>::new();
            allowed_roles.append(AccessRole::Doctor(()));
            allowed_roles.append(AccessRole::Nurse(()));
            allowed_roles.append(AccessRole::Admin(()));
            allowed_roles.append(AccessRole::Staff(()));
            
            assert(is_authorized_role(self, hospital_id, allowed_roles), "Unauthorized role");
            
            // Get patient addresses
            let patient_addresses = self.hospital_patient_addresses.read(hospital_id);
            
            // Create result array
            let mut result = ArrayTrait::<PatientReturnInfo>::new();
            
            // Get patient info for each patient
            let mut i = 0;
            let len = patient_addresses.len();
            
            while i < len {
                let patient_id = *patient_addresses.at(i);
                let patient = self.hospital_patients.read((hospital_id, patient_id));
                
                let patient_info = PatientReturnInfo {
                    id: patient.id,
                    name: patient.name,
                    date_of_birth: patient.date_of_birth,
                    gender: patient.gender,
                    contact_info: patient.contact_info,
                    medical_info: patient.medical_info,
                    emergency_contacts: patient.emergency_contacts,
                    appointments: patient.appointments
                };
                
                result.append(patient_info);
                i += 1;
            }
            
            result
        }

        fn delete_patient_record(
            ref self: ContractState,
            hospital_id: ByteArray,
            patient_id: ByteArray
        ) {
            // Validate inputs
            assert(hospital_exists(@self, hospital_id), "Hospital does not exist");
            assert(patient_exists(@self, hospital_id, patient_id), "Patient does not exist");
            
            // Check authorization - only admins can delete patients
            let mut allowed_roles = ArrayTrait::<AccessRole>::new();
            allowed_roles.append(AccessRole::Admin(()));
            
            assert(is_authorized_role(@self, hospital_id, allowed_roles), "Unauthorized role");
            
            // Create empty patient to "delete" the record
            let empty_emergency_contacts = ArrayTrait::<EmergencyContact>::new();
            let empty_appointments = ArrayTrait::<Appointment>::new();
            
            let empty_contact_info = ContactInfo {
                email: ByteArray::new(),
                phone: ByteArray::new(),
                address: ByteArray::new(),
                next_of_kin_name: ByteArray::new(),
                next_of_kin_phone: ByteArray::new(),
                next_of_kin_email: ByteArray::new()
            };
            
            let empty_medical_info = MedicalInfo {
                current_medications: ByteArray::new(),
                allergies: ByteArray::new(),
                medical_file_link: ByteArray::new()
            };
            
            let empty_patient = Patient {
                id: ByteArray::new(),
                name: ByteArray::new(),
                date_of_birth: 0,
                gender: Gender::Other(()),
                contact_info: empty_contact_info,
                medical_info: empty_medical_info,
                emergency_contacts: empty_emergency_contacts,
                appointments: empty_appointments
            };
            
            self.hospital_patients.write((hospital_id, patient_id), empty_patient);
            
            // Remove patient from list
            let mut patient_addresses = self.hospital_patient_addresses.read(hospital_id);
            let mut new_addresses = ArrayTrait::<ByteArray>::new();
            
            let mut i = 0;
            let len = patient_addresses.len();
            
            while i < len {
                let current_id = *patient_addresses.at(i);
                if current_id != patient_id {
                    new_addresses.append(current_id);
                }
                i += 1;
            }
            
            self.hospital_patient_addresses.write(hospital_id, new_addresses);
            
            // Update patient count
            let mut hospital = self.hospitals.read(hospital_id);
            hospital.patient_count -= 1;
            self.hospitals.write(hospital_id, hospital);
        }
    }
}

// Interface
#[starknet::interface]
trait IBlocHealth<TContractState> {
    // Hospital Functions
    fn add_hospital(
        ref self: TContractState,
        hospital_id: ByteArray,
        name: ByteArray,
        location: ByteArray,
        registration_number: ByteArray
    );
    
    fn change_hospital_owner(
        ref self: TContractState,
        hospital_id: ByteArray,
        new_owner: ContractAddress
    );
    
    fn update_hospital_staff_roles(
        ref self: TContractState,
        hospital_id: ByteArray,
        staff_address: ContractAddress,
        role: AccessRole
    );
    
    fn delete_hospital(
        ref self: TContractState,
        hospital_id: ByteArray
    );
    
    fn delete_hospital_staff(
        ref self: TContractState,
        hospital_id: ByteArray,
        staff_address: ContractAddress
    );
    
    // Staff Functions
    fn is_hospital_staff(
        self: @TContractState,
        hospital_id: ByteArray
    ) -> bool;
    
    // Patient Functions
    fn create_patient_record(
        ref self: TContractState,
        hospital_id: ByteArray,
        patient_id: ByteArray,
        name: ByteArray,
        date_of_birth: u64,
        gender: Gender,
        contact_info: ContactInfo,
        medical_info: MedicalInfo,
        emergency_contacts: Array<EmergencyContact>
    );
    
    fn add_patient_appointment(
        ref self: TContractState,
        hospital_id: ByteArray,
        patient_id: ByteArray,
        date: u64,
        reason: ByteArray,
        diagnosis: ByteArray,
        treatment: ByteArray
    );
    
    fn get_patient_record(
        self: @TContractState,
        hospital_id: ByteArray,
        patient_id: ByteArray
    ) -> PatientReturnInfo;
    
    fn get_all_patients(
        self: @TContractState,
        hospital_id: ByteArray
    ) -> Array<PatientReturnInfo>;
    
    fn delete_patient_record(
        ref self: TContractState,
        hospital_id: ByteArray,
        patient_id: ByteArray
    );
}