#[starknet::contract]
mod BlocHealth {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::contract_address::ContractAddressZeroable;

    // Enums
    #[derive(Drop, Copy, Serde, PartialEq)]
    enum AccessRoles {
        Doctor,
        Staff,
        Nurse,
        Admin
    }

    #[derive(Drop, Copy, Serde, PartialEq)]
    enum Gender {
        Male,
        Female,
        Other
    }

    // Structs
    #[derive(Drop, Serde)]
    struct Staff {
        name: felt252,
        role: AccessRoles,
        email: felt252,
        phone: felt252,
    }

    #[derive(Drop, Serde)]
    struct ContactInfo {
        phone: felt252,
        email: felt252,
        residential_address: felt252,
        next_of_kin: felt252,
        next_of_kin_phone_number: felt252,
        next_of_kin_residential_address: felt252,
        health_insured: bool,
    }

    #[derive(Drop, Serde)]
    struct MedicalInfo {
        current_medications: felt252,
        allergies: felt252,
        medical_history_file: felt252,
    }

    #[derive(Drop, Serde)]
    struct EmergencyContact {
        name: felt252,
        phone: felt252,
        residential_address: felt252,
    }

    #[derive(Drop, Serde)]
    struct Appointment {
        current_medications: felt252,
        diagnosis: felt252,
        treatment_plan: felt252,
        date: u256,
        reason: felt252,
    }

    #[derive(Drop, Serde)]
    struct PatientReturnInfo {
        name: felt252,
        dob: u256,
        gender: Gender,
        contact_info: ContactInfo,
        medical_info: MedicalInfo,
    }

    // Storage
    #[storage]
    struct Storage {
        owner: ContractAddress,
        hospital_count: u256,
        // Hospital mappings
        hospital_name: LegacyMap::<felt252, felt252>,
        hospital_location: LegacyMap::<felt252, felt252>,
        hospital_doe: LegacyMap::<felt252, u256>,
        hospital_reg_no: LegacyMap::<felt252, u256>,
        hospital_staff_count: LegacyMap::<felt252, u256>,
        hospital_patient_count: LegacyMap::<felt252, u256>,
        hospital_owner: LegacyMap::<felt252, ContractAddress>,
        
        // Staff mappings
        hospital_staff: LegacyMap::<(felt252, ContractAddress), Staff>,
        
        // Patient mappings
        patient_name: LegacyMap::<(felt252, ContractAddress), felt252>,
        patient_dob: LegacyMap::<(felt252, ContractAddress), u256>,
        patient_gender: LegacyMap::<(felt252, ContractAddress), Gender>,
        patient_contact_info: LegacyMap::<(felt252, ContractAddress), ContactInfo>,
        patient_medical_info: LegacyMap::<(felt252, ContractAddress), MedicalInfo>,
        patient_appointment_count: LegacyMap::<(felt252, ContractAddress), u128>,
        
        // Arrays require special handling in Cairo
        patient_addresses: LegacyMap::<(felt252, u256), ContractAddress>,
        patient_emergency_contacts: LegacyMap::<(felt252, ContractAddress, u256), EmergencyContact>,
        patient_emergency_contact_count: LegacyMap::<(felt252, ContractAddress), u256>,
        patient_appointment_dates: LegacyMap::<(felt252, ContractAddress, u256), u256>,
        patient_appointments: LegacyMap::<(felt252, ContractAddress, u256), Appointment>,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        HospitalCreated: HospitalCreated,
        HospitalStaffRoleUpdated: HospitalStaffRoleUpdated,
        PatientCreated: PatientCreated,
        VisitRecordCreated: VisitRecordCreated,
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalCreated {
        name: felt252,
        hospital_id: felt252,
        owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalStaffRoleUpdated {
        hospital_id: felt252,
        address: ContractAddress,
        role: AccessRoles,
    }

    #[derive(Drop, starknet::Event)]
    struct PatientCreated {
        name: felt252,
        patient: ContractAddress,
        dob: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct VisitRecordCreated {
        name: felt252,
        patient: ContractAddress,
        date: u256,
    }

    // Errors
    #[derive(Drop, starknet::Event)]
    enum BlocHealthError {
        IsNotValidAddressError: IsNotValidAddressError,
        HospitalDoesNotExistError: HospitalDoesNotExistError,
        NotHospitalOwnerError: NotHospitalOwnerError,
        HospitalStaffDoesNotExistsError: HospitalStaffDoesNotExistsError,
        NotAuthorizedForHospitalError: NotAuthorizedForHospitalError,
        PatientDoesNotExistsError: PatientDoesNotExistsError,
    }

    #[derive(Drop, starknet::Event)]
    struct IsNotValidAddressError {
        address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalDoesNotExistError {
        hospital_id: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct NotHospitalOwnerError {
        sender: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalStaffDoesNotExistsError {
        address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct NotAuthorizedForHospitalError {
        sender: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct PatientDoesNotExistsError {
        patient: ContractAddress,
    }

    // Constructor
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }

    // Implementation
    #[external(v0)]
    impl BlocHealthImpl of super::IBlocHealth<ContractState> {
        fn add_hospital(
            ref self: ContractState,
            hospital_id: felt252,
            name: felt252,
            location: felt252,
            doe: u256,
            hospital_reg_no: u256
        ) {
            // Check if hospital exists
            let doe_existing = self.hospital_doe.read(hospital_id);
            
            if doe_existing == 0 {
                let current_count = self.hospital_count.read();
                self.hospital_count.write(current_count + 1);
            }

            self.hospital_name.write(hospital_id, name);
            self.hospital_location.write(hospital_id, location);
            self.hospital_reg_no.write(hospital_id, hospital_reg_no);
            self.hospital_doe.write(hospital_id, doe);
            self.hospital_owner.write(hospital_id, get_caller_address());

            // Emit event
            self.emit(HospitalCreated { 
                name, 
                hospital_id, 
                owner: get_caller_address() 
            });
        }

        fn change_hospital_owner(
            ref self: ContractState,
            hospital_id: felt252,
            new_owner: ContractAddress
        ) {
            // Assert hospital exists and caller is owner
            self.assert_hospital_exists(hospital_id);
            self.assert_valid_address(new_owner);
            self.assert_only_hospital_owner(hospital_id);

            self.hospital_owner.write(hospital_id, new_owner);
        }

        fn update_hospital_staff_roles(
            ref self: ContractState,
            hospital_id: felt252,
            address: ContractAddress,
            name: felt252,
            role: AccessRoles,
            email: felt252,
            phone: felt252
        ) {
            // Assertions
            self.assert_hospital_exists(hospital_id);
            self.assert_valid_address(address);
            self.assert_only_hospital_owner(hospital_id);

            // Check if staff exists already
            let current_staff = self.hospital_staff.read((hospital_id, address));
            let is_new_staff = 
                current_staff.role != AccessRoles::Admin &&
                current_staff.role != AccessRoles::Doctor &&
                current_staff.role != AccessRoles::Nurse &&
                current_staff.role != AccessRoles::Staff;

            if is_new_staff {
                let current_count = self.hospital_staff_count.read(hospital_id);
                self.hospital_staff_count.write(hospital_id, current_count + 1);
            }

            // Update staff info
            let staff = Staff {
                name,
                role,
                email,
                phone
            };
            self.hospital_staff.write((hospital_id, address), staff);

            // Emit event
            self.emit(HospitalStaffRoleUpdated {
                hospital_id,
                address,
                role
            });
        }

        fn is_hospital_staff(
            self: @ContractState,
            hospital_id: felt252
        ) -> bool {
            self.assert_hospital_exists(hospital_id);
            let caller = get_caller_address();
            self.assert_hospital_staff_exists(hospital_id, caller);
            true
        }

        fn delete_hospital(
            ref self: ContractState,
            hospital_id: felt252
        ) {
            self.assert_hospital_exists(hospital_id);
            self.assert_only_hospital_owner(hospital_id);

            // Delete hospital
            self.hospital_name.write(hospital_id, 0);
            self.hospital_location.write(hospital_id, 0);
            self.hospital_reg_no.write(hospital_id, 0);
            self.hospital_doe.write(hospital_id, 0);
            self.hospital_owner.write(hospital_id, ContractAddressZeroable::zero());

            // Update count
            let current_count = self.hospital_count.read();
            self.hospital_count.write(current_count - 1);
        }

        fn delete_hospital_staff(
            ref self: ContractState,
            hospital_id: felt252,
            address: ContractAddress
        ) {
            self.assert_hospital_exists(hospital_id);
            self.assert_valid_address(address);
            self.assert_only_hospital_owner(hospital_id);
            self.assert_hospital_staff_exists(hospital_id, address);

            // Delete staff
            let empty_staff = Staff {
                name: 0,
                role: AccessRoles::Staff, // Default value
                email: 0,
                phone: 0
            };
            self.hospital_staff.write((hospital_id, address), empty_staff);

            // Update count
            let current_count = self.hospital_staff_count.read(hospital_id);
            self.hospital_staff_count.write(hospital_id, current_count - 1);
        }

        fn create_patient_record(
            ref self: ContractState,
            hospital_id: felt252,
            patient: ContractAddress,
            name: felt252,
            gender: Gender,
            dob: u256,
            contact_info: ContactInfo,
            medical_info: MedicalInfo,
            emergency_contacts: Array<EmergencyContact>
        ) {
            self.assert_hospital_exists(hospital_id);
            self.assert_valid_address(patient);
            self.assert_authorized_role(hospital_id);

            // Check if patient exists
            let existing_dob = self.patient_dob.read((hospital_id, patient));
            
            if existing_dob == 0 {
                let current_count = self.hospital_patient_count.read(hospital_id);
                self.hospital_patient_count.write(hospital_id, current_count + 1);
                
                // Add to patient addresses array
                self.patient_addresses.write((hospital_id, current_count), patient);
            }

            // Update patient info
            self.patient_name.write((hospital_id, patient), name);
            self.patient_dob.write((hospital_id, patient), dob);
            self.patient_gender.write((hospital_id, patient), gender);
            self.patient_contact_info.write((hospital_id, patient), contact_info);
            self.patient_medical_info.write((hospital_id, patient), medical_info);

            // Add emergency contacts
            let mut i: u256 = 0;
            let contacts_len = emergency_contacts.len();
            let mut contact_count: u256 = 0;

            while i < contacts_len.into() {
                if let Option::Some(contact) = emergency_contacts.get(i.try_into().unwrap()) {
                    self.patient_emergency_contacts.write((hospital_id, patient, contact_count), *contact);
                    contact_count += 1;
                }
                i += 1;
            }

            self.patient_emergency_contact_count.write((hospital_id, patient), contact_count);

            // Emit event
            self.emit(PatientCreated {
                name,
                patient,
                dob
            });
        }

        fn get_all_patients(
            self: @ContractState,
            hospital_id: felt252
        ) -> Array<PatientReturnInfo> {
            self.assert_hospital_exists(hospital_id);
            self.assert_authorized_to_retrieve(hospital_id);

            let patient_count = self.hospital_patient_count.read(hospital_id);
            let mut patients: Array<PatientReturnInfo> = ArrayTrait::new();
            let mut i: u256 = 0;

            while i < patient_count {
                let patient_address = self.patient_addresses.read((hospital_id, i));
                
                let patient_info = PatientReturnInfo {
                    name: self.patient_name.read((hospital_id, patient_address)),
                    dob: self.patient_dob.read((hospital_id, patient_address)),
                    gender: self.patient_gender.read((hospital_id, patient_address)),
                    contact_info: self.patient_contact_info.read((hospital_id, patient_address)),
                    medical_info: self.patient_medical_info.read((hospital_id, patient_address))
                };
                
                patients.append(patient_info);
                i += 1;
            }

            patients
        }

        fn get_patient_record(
            self: @ContractState,
            hospital_id: felt252,
            patient: ContractAddress
        ) -> (PatientReturnInfo, Array<EmergencyContact>) {
            self.assert_hospital_exists(hospital_id);
            self.assert_authorized_to_retrieve_including_patient(hospital_id, patient);

            let patient_info = PatientReturnInfo {
                name: self.patient_name.read((hospital_id, patient)),
                dob: self.patient_dob.read((hospital_id, patient)),
                gender: self.patient_gender.read((hospital_id, patient)),
                contact_info: self.patient_contact_info.read((hospital_id, patient)),
                medical_info: self.patient_medical_info.read((hospital_id, patient))
            };

            // Get emergency contacts
            let contact_count = self.patient_emergency_contact_count.read((hospital_id, patient));
            let mut contacts: Array<EmergencyContact> = ArrayTrait::new();
            let mut i: u256 = 0;

            while i < contact_count {
                let contact = self.patient_emergency_contacts.read((hospital_id, patient, i));
                contacts.append(contact);
                i += 1;
            }

            (patient_info, contacts)
        }

        fn delete_patient_record(
            ref self: ContractState,
            hospital_id: felt252,
            patient: ContractAddress
        ) {
            self.assert_hospital_exists(hospital_id);
            self.assert_authorized_role(hospital_id);
            self.assert_patient_exists(hospital_id, patient);

            // Remove from patient addresses array
            let patient_count = self.hospital_patient_count.read(hospital_id);
            let mut i: u256 = 0;

            while i < patient_count {
                let address = self.patient_addresses.read((hospital_id, i));
                
                if address == patient {
                    // Replace with last element and remove last
                    let last_address = self.patient_addresses.read((hospital_id, patient_count - 1));
                    self.patient_addresses.write((hospital_id, i), last_address);
                    break;
                }
                
                i += 1;
            }

            // Clear patient data
            self.patient_name.write((hospital_id, patient), 0);
            self.patient_dob.write((hospital_id, patient), 0);
            // We can't easily reset enum in Cairo, but we can use a default value
            self.patient_gender.write((hospital_id, patient), Gender::Other);
            
            // Update count
            self.hospital_patient_count.write(hospital_id, patient_count - 1);
        }

        fn upload_appointment(
            ref self: ContractState,
            hospital_id: felt252,
            patient: ContractAddress,
            date: u256,
            appointment: Appointment
        ) {
            self.assert_hospital_exists(hospital_id);
            self.assert_authorized_role(hospital_id);
            self.assert_patient_exists(hospital_id, patient);

            // Check if appointment exists
            let existing_appointment = self.patient_appointments.read((hospital_id, patient, date));
            
            if existing_appointment.date == 0 {
                let current_count: u128 = self.patient_appointment_count.read((hospital_id, patient));
                self.patient_appointment_count.write((hospital_id, patient), current_count + 1);
                
                // Add to appointment dates array
                self.patient_appointment_dates.write((hospital_id, patient, current_count.into()), date);
            }

            // Update appointment
            self.patient_appointments.write((hospital_id, patient, date), appointment);

            // Emit event
            let patient_name = self.patient_name.read((hospital_id, patient));
            self.emit(VisitRecordCreated {
                name: patient_name,
                patient,
                date
            });
        }

        fn get_patient_appointments(
            self: @ContractState,
            hospital_id: felt252,
            patient: ContractAddress
        ) -> Array<Appointment> {
            self.assert_hospital_exists(hospital_id);
            self.assert_authorized_to_retrieve_including_patient(hospital_id, patient);

            let appointment_count: u128 = self.patient_appointment_count.read((hospital_id, patient));
            let mut appointments: Array<Appointment> = ArrayTrait::new();
            let mut i: u256 = 0;

            while i < appointment_count.into() {
                let date = self.patient_appointment_dates.read((hospital_id, patient, i));
                let appointment = self.patient_appointments.read((hospital_id, patient, date));
                appointments.append(appointment);
                i += 1;
            }

            appointments
        }
    }

    // Internal functions
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn assert_valid_address(self: @ContractState, address: ContractAddress) {
            let zero_address = ContractAddressZeroable::zero();
            assert(address != zero_address, 'Invalid address');
        }

        fn assert_hospital_exists(self: @ContractState, hospital_id: felt252) {
            let hospital_owner = self.hospital_owner.read(hospital_id);
            let zero_address = ContractAddressZeroable::zero();
            assert(hospital_owner != zero_address, 'Hospital does not exist');
        }

        fn assert_only_hospital_owner(self: @ContractState, hospital_id: felt252) {
            let hospital_owner = self.hospital_owner.read(hospital_id);
            let caller = get_caller_address();
            assert(caller == hospital_owner, 'Not hospital owner');
        }

        fn assert_hospital_staff_exists(self: @ContractState, hospital_id: felt252, address: ContractAddress) {
            let staff = self.hospital_staff.read((hospital_id, address));
            assert(
                staff.role == AccessRoles::Admin ||
                staff.role == AccessRoles::Doctor ||
                staff.role == AccessRoles::Nurse ||
                staff.role == AccessRoles::Staff,
                'Staff does not exist'
            );
        }

        fn assert_patient_exists(self: @ContractState, hospital_id: felt252, patient: ContractAddress) {
            let dob = self.patient_dob.read((hospital_id, patient));
            assert(dob != 0, 'Patient does not exist');
        }

        fn assert_authorized_role(self: @ContractState, hospital_id: felt252) {
            let caller = get_caller_address();
            let hospital_owner = self.hospital_owner.read(hospital_id);
            let staff = self.hospital_staff.read((hospital_id, caller));
            
            assert(
                caller == hospital_owner ||
                staff.role == AccessRoles::Admin ||
                staff.role == AccessRoles::Doctor ||
                staff.role == AccessRoles::Nurse,
                'Not authorized'
            );
        }

        fn assert_authorized_to_retrieve(self: @ContractState, hospital_id: felt252) {
            let caller = get_caller_address();
            let hospital_owner = self.hospital_owner.read(hospital_id);
            let staff = self.hospital_staff.read((hospital_id, caller));
            
            assert(
                caller == hospital_owner ||
                staff.role == AccessRoles::Admin ||
                staff.role == AccessRoles::Doctor ||
                staff.role == AccessRoles::Nurse ||
                staff.role == AccessRoles::Staff,
                'Not authorized'
            );
        }

        fn assert_authorized_to_retrieve_including_patient(
            self: @ContractState, 
            hospital_id: felt252, 
            patient: ContractAddress
        ) {
            let caller = get_caller_address();
            let hospital_owner = self.hospital_owner.read(hospital_id);
            let staff = self.hospital_staff.read((hospital_id, caller));
            
            assert(
                caller == patient ||
                caller == hospital_owner ||
                staff.role == AccessRoles::Admin ||
                staff.role == AccessRoles::Doctor ||
                staff.role == AccessRoles::Nurse ||
                staff.role == AccessRoles::Staff,
                'Not authorized'
            );
        }
    }
}

// Interface for the contract
#[starknet::interface]
trait IBlocHealth<TContractState> {
    fn add_hospital(
        ref self: TContractState,
        hospital_id: felt252,
        name: felt252,
        location: felt252,
        doe: u256,
        hospital_reg_no: u256
    );

    fn change_hospital_owner(
        ref self: TContractState,
        hospital_id: felt252,
        new_owner: ContractAddress
    );

    fn update_hospital_staff_roles(
        ref self: TContractState,
        hospital_id: felt252,
        address: ContractAddress,
        name: felt252,
        role: BlocHealth::AccessRoles,
        email: felt252,
        phone: felt252
    );

    fn is_hospital_staff(
        self: @TContractState,
        hospital_id: felt252
    ) -> bool;

    fn delete_hospital(
        ref self: TContractState,
        hospital_id: felt252
    );

    fn delete_hospital_staff(
        ref self: TContractState,
        hospital_id: felt252,
        address: ContractAddress
    );

    fn create_patient_record(
        ref self: TContractState,
        hospital_id: felt252,
        patient: ContractAddress,
        name: felt252,
        gender: BlocHealth::Gender,
        dob: u256,
        contact_info: BlocHealth::ContactInfo,
        medical_info: BlocHealth::MedicalInfo,
        emergency_contacts: Array<BlocHealth::EmergencyContact>
    );

    fn get_all_patients(
        self: @TContractState,
        hospital_id: felt252
    ) -> Array<BlocHealth::PatientReturnInfo>;

    fn get_patient_record(
        self: @TContractState,
        hospital_id: felt252,
        patient: ContractAddress
    ) -> (BlocHealth::PatientReturnInfo, Array<BlocHealth::EmergencyContact>);

    fn delete_patient_record(
        ref self: TContractState,
        hospital_id: felt252,
        patient: ContractAddress
    );

    fn upload_appointment(
        ref self: TContractState,
        hospital_id: felt252,
        patient: ContractAddress,
        date: u256,
        appointment: BlocHealth::Appointment
    );

    fn get_patient_appointments(
        self: @TContractState,
        hospital_id: felt252,
        patient: ContractAddress
    ) -> Array<BlocHealth::Appointment>;
}