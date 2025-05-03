use blochealth_contract::{BlocHealth, IBlocHealthDispatcher, IBlocHealthDispatcherTrait};
use starknet::{ContractAddress, contract_address_const};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};
use snforge_std::{
    declare, spy_events, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait,
};

/// Deploys a fresh instance of the BlocHealth contract.
fn deploy_contract() -> ContractAddress {
    let contract = declare("BlocHealth").unwrap().contract_class();
    let (address, _) = contract.deploy(@array![]).unwrap();
    address
}

/// Helper to register a hospital and return its generated ID.
fn register_hospital(dispatcher: IBlocHealthDispatcher, owner: ContractAddress) -> felt252 {
    let reg_no = 42_u64;
    dispatcher.add_hospital('MyHospital', 'MyLocation', 1_u64, reg_no, owner);

    // Calculate the hospital ID the same way the contract does
    let mut state = PoseidonTrait::new();
    state = state.update_with(reg_no);
    state.finalize()
}

#[test]
fn test_add_hospital_emits_event() {
    let addr = deploy_contract();
    let dispatcher = IBlocHealthDispatcher { contract_address: addr };
    let mut spy = spy_events();
    let owner = dispatcher.get_owner();

    let hospital_id = register_hospital(dispatcher, owner);

    spy.assert_emitted(
        @array![
            (
                addr,
                BlocHealth::Event::HospitalCreated(
                    BlocHealth::HospitalCreated {
                        name: 'MyHospital',
                        hospital_id,
                        owner,
                    }
                )
            )
        ],
    );
}

#[test]
fn test_add_staff_success() {
    let addr = deploy_contract();
    let dispatcher = IBlocHealthDispatcher { contract_address: addr };
    let mut spy = spy_events();
    let owner = dispatcher.get_owner();

    let hospital_id = register_hospital(dispatcher, owner);

    let staff_addr = contract_address_const::<'STAFF1'>();
    dispatcher.add_staff(
        hospital_id,
        staff_addr,
        BlocHealth::AccessRoles::Doctor,
        'DrAlice',
        'alice@hospital.test',
        '555-1234',
    );

    spy.assert_emitted(
        @array![
            (
                addr,
                BlocHealth::Event::StaffAdded(
                    BlocHealth::StaffAdded {
                        hospital_id,
                        address: staff_addr, // Changed from staff_address to address
                        role: BlocHealth::AccessRoles::Doctor,
                    }
                )
            )
        ],
    );

    let hospital = dispatcher.get_hospital(hospital_id);
    assert_eq!(hospital.staff_count, 1_u64);
}

