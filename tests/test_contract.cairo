use blochealth_contract::IBlocHealthDispatcherTrait;
use starknet::{ContractAddress, contract_address_const};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use blochealth_contract::{BlocHealth, IBlocHealthDispatcher};

fn deploy_contract() -> ContractAddress {
    let contract = declare("BlocHealth").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    contract_address
}

#[test]
fn test_add_hospital() {
    let contract_address = deploy_contract();
    let dispatcher = IBlocHealthDispatcher { contract_address };
    let mut spy = spy_events();
    let hospital = BlocHealth::Hospital {
        name: 'Hospital1',
        location: 'Loc1',
        doe: 1,
        hospital_reg_no: 9,
        staff_count: 0,
        patient_count: 0,
        owner: contract_address_const::<'OWNER'>(),
    };

    dispatcher
        .add_hospital(
            hospital.name,
            hospital.location,
            hospital.doe,
            hospital.hospital_reg_no,
            hospital.owner,
        );
    let hospital_id: felt252 = PoseidonTrait::new()
        .update_with(hospital.hospital_reg_no)
        .finalize();
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    BlocHealth::Event::HospitalCreated(
                        BlocHealth::HospitalCreated {
                            name: hospital.name,
                            hospital_id,
                            owner: hospital.owner,
                        },
                    ),
                ),
            ],
        );
}
