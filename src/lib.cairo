use starknet::ContractAddress;

#[starknet::interface]
pub trait IBlocHealth<TContractState> {
    fn get_owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod BlocHealth {
    use super::IBlocHealth;
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use core::starknet::contract_address::ContractAddress;
    use core::starknet::get_caller_address;

    #[derive(Drop, Serde, PartialEq, Copy)]
    enum AccessRoles {
        Admin,
        Doctor,
        Nurse,
        Staff,
    }

    #[derive(Drop, Serde, PartialEq, Copy)]
    enum Gender {
        Male,
        Female,
        Other,
    }

    #[derive(Drop, Serde)]
    struct Hospital {
        name: felt252,
        location: felt252,
        doe: u64,
        hospital_reg_no: u64,
        staff_count: u64,
        patient_count: u64,
        owner: ContractAddress,
        // roles: Map<ContractAddress, Staff>,
        patient_addresses: Array<felt252>,
        // patients: Map<felt252, Patient>,
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
        // appointments: Map<u64, Appointment>,
        emergency_contacts: Array<EmergencyContact>,
    }

    #[derive(Drop, Serde)]
    struct ContactInfo {
        phone: felt252,
        email: felt252,
        residential_address: felt252,
        next_of_kin: felt252,
        next_of_kin_phone_number: felt252,
        next_of_kin_residential_address: felt252,
        health_insurance: bool,
    }

    #[derive(Drop, Serde)]
    struct MedicalInfo {
        current_medications: felt252,
        allergies: felt252,
        medical_history_file: felt252,
        // chronic_conditions: Array<felt252>,
    // surgeries: Array<felt252>,
    // immunizations: Array<felt252>
    }

    #[derive(Drop, Serde)]
    struct EmergencyContact {
        name: felt252,
        phone: felt252,
        residential_address: felt252,
        // relationship: felt252,
    }

    #[derive(Drop, Serde)]
    struct Appointment {
        current_medications: felt252,
        diagnosis: felt252,
        treatment_plan: felt252,
        date: u64,
        reason: felt252,
        // lab_results: Array<felt252>,
    }

    // #[derive(Drop, Serde)]
    // struct MedicalRecord {
    //     date: u64,
    //     lab_results: Array<felt252>,
    //     diagnosis: felt252,
    //     treatment: felt252,
    //     doctor: ContractAddress,
    //     hospital: Hospital,
    // }

    #[storage]
    struct Storage {
        pub owner: ContractAddress,
        pub hospital_count: u256,
        pub hospitals: Map<felt252, Hospital>,
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
    }
}
