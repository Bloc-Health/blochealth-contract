use starknet::ContractAddress;
// use BlocHealth::{
//     AccessRoles, Gender, PatientReturnInfo, EmergencyContact, ContactInfo, MedicalInfo, Appointment,
// };

#[starknet::interface]
pub trait IBlocHealth<TContractState> {
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn add_hospital(ref self: TContractState, name: felt252, location: felt252, doe: u64, hospital_reg_no: u64, owner: ContractAddress);
}

#[starknet::contract]
pub mod BlocHealth {
    use super::IBlocHealth;
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map, Vec, VecTrait, MutableVecTrait};
    use core::starknet::contract_address::ContractAddress;
    use core::starknet::get_caller_address;
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::starknet::storage_access::Store;

    #[derive(Drop, Serde, PartialEq, Copy)]
    pub enum AccessRoles {
        Admin,
        Doctor,
        Nurse,
        Staff,
    }

    #[derive(Drop, Serde, PartialEq, Copy)]
    pub enum Gender {
        Male,
        Female,
        Other,
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct Hospital {
        name: felt252,
        location: felt252,
        doe: u64,
        hospital_reg_no: u64,
        staff_count: u64,
        patient_count: u64,
        owner: ContractAddress,
        // patient_addresses: Vec<ContractAddress>,
    }

    #[derive(Drop, Serde)]
    struct Staff {
        name: felt252,
        role: AccessRoles,
        email: felt252,
        phone: felt252,
    }

    #[derive(Drop, Serde)]
    struct Patient {
        name: felt252,
        dob: u64,
        gender: Gender,
        contact_info: ContactInfo,
        medical_info: MedicalInfo,
        appointment_count: u32,
        appointment_dates: Array<u64>,
        emergency_contacts: Array<EmergencyContact>,
    }

    #[derive(Drop, Serde)]
    pub struct PatientReturnInfo {
        name: felt252,
        dob: u64,
        gender: Gender,
        contact_info: ContactInfo,
        medical_info: MedicalInfo,
    }

    #[derive(Drop, Serde)]
    pub struct ContactInfo {
        phone: felt252,
        email: felt252,
        residential_address: felt252,
        next_of_kin: felt252,
        next_of_kin_phone_number: felt252,
        next_of_kin_residential_address: felt252,
        health_insurance: bool,
    }

    #[derive(Drop, Serde)]
    pub struct MedicalInfo {
        current_medications: felt252,
        allergies: felt252,
        medical_history_file: felt252,
        chronic_conditions: Option<Array<felt252>>,
        surgeries: Option<Array<felt252>>,
    }

    #[derive(Drop, Serde)]
    pub struct EmergencyContact {
        name: felt252,
        phone: felt252,
        residential_address: felt252,
        relationship: Option<felt252>,
    }

    #[derive(Drop, Serde)]
    pub struct Appointment {
        current_medications: felt252,
        diagnosis: felt252,
        treatment_plan: felt252,
        date: u64,
        reason: felt252,
        lab_results: Option<Array<felt252>>,
    }

    #[storage]
    struct Storage {
        pub owner: ContractAddress,
        pub hospital_count: u256,
        pub hospitals: Map<felt252, Hospital>,
        pub hospital_staff: Map<(felt252, ContractAddress), Staff>, // hospital_id
        pub hospital_patients: Map<(felt252, ContractAddress), Patient>, // hospital_id
        pub patient_appointments: Map<
            (felt252, felt252, u64), Appointment,
        > // hospital_id, patient_id, appointment_id
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        HospitalCreated: HospitalCreated,
        StaffAdded: StaffAdded,
        PatientAdded: PatientAdded,
        VisitRecordCreated: VisitRecordCreated,
        // AppointmentScheduled: AppointmentScheduled,
    // AppointmentCancelled: AppointmentCancelled,
    // AppointmentRescheduled: AppointmentRescheduled,
    }

    #[derive(Drop, starknet::Event)]
    struct HospitalCreated {
        name: felt252,
        hospital_id: felt252,
        owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct StaffAdded {
        hospital_id: felt252,
        address: ContractAddress,
        role: AccessRoles,
    }

    #[derive(Drop, starknet::Event)]
    struct PatientAdded {
        name: felt252,
        hospital_id: felt252,
        patient: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct VisitRecordCreated {
        name: felt252,
        patient: ContractAddress,
        date: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }

    #[abi(embed_v0)]
    impl BlocHealthImpl of IBlocHealth<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
        fn add_hospital(ref self: ContractState, name: felt252, location: felt252, doe: u64, hospital_reg_no: u64, owner: ContractAddress) {
            let hospital = Hospital {
                name,
                location,
                doe,
                hospital_reg_no,
                owner,
                staff_count: 0,
                patient_count: 0,
                // patient_addresses: array![],
            };

            let hospital_id: felt252 = PoseidonTrait::new().update_with(hospital_reg_no).finalize();

            // Store the hospital in the storage map
            self.hospitals.entry(hospital_id).write(hospital);

            // Increment the hospital count
            self.hospital_count.write(self.hospital_count.read() + 1);

            // Emit an event for the created hospital
            self.emit(HospitalCreated {
                name,
                hospital_id,
                owner,
            });
        }
    }
}
