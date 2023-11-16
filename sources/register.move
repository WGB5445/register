module register::register {
    use std::signer;
    use aptos_std::smart_table;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::code;
    use aptos_framework::event;

    struct CapTable has key{
        caps: smart_table::SmartTable<address, SignerCapability>,
        new_event_handler: event::EventHandle<NewEvent>,
        into_event_handler: event::EventHandle<IntoEvent>,
        publish_event_handler:  event::EventHandle<PublishEvent>,
    }

    struct NewEvent has copy,store,drop {
        owner: address,
        seed: vector<u8>,
        newAddress: address,
    }

    struct PublishEvent has copy,store,drop {
        owner: address,
        seed: vector<u8>,
        newAddress: address,
    }

    struct IntoEvent has copy,store,drop {
        owner: address,
        seed: vector<u8>,
        newAddress: address,
    }


    fun init_module(sender: &signer){
        move_to(sender, CapTable {
            caps: smart_table::new(),
            new_event_handler: account::new_event_handle(sender),
            into_event_handler:  account::new_event_handle(sender),
            publish_event_handler: account::new_event_handle(sender),
        });
    }

    public entry fun new (sender: &signer, seed: vector<u8>) acquires CapTable {
        let ( signer, cap) = account::create_resource_account(sender, seed);
        let cap_table =  borrow_global_mut<CapTable>(@register);
        smart_table::add(&mut cap_table.caps, signer::address_of(&signer), cap);
        event::emit_event(
            &mut cap_table.new_event_handler,
            NewEvent {
                owner: signer::address_of(sender),
                seed,
                newAddress:signer::address_of(&signer),
            }
        );
    }

    public entry fun publish_package_txn(sender: &signer,seed: vector<u8> , metadata_serialized: vector<u8>, code: vector<vector<u8>>) acquires CapTable {
        let address = account::create_resource_address(&signer::address_of(sender), seed);
        let cap_table =  borrow_global_mut<CapTable>(@register);
        let cap = smart_table::borrow(&mut cap_table.caps, address);
        assert!( smart_table::contains(&cap_table.caps, address) , 1);
        let signer = &account::create_signer_with_capability(cap) ;
        code::publish_package_txn(
            &account::create_signer_with_capability(cap),
            metadata_serialized,
            code
        );
        event::emit_event(&mut cap_table.publish_event_handler, PublishEvent{
            owner: signer::address_of(sender),
            seed,
            newAddress:signer::address_of(signer),
        })
    }

    public fun into (sender: &signer, seed: vector<u8>): SignerCapability acquires CapTable {
        let address = account::create_resource_address(&signer::address_of(sender), seed);
        let cap_table =  borrow_global_mut<CapTable>(@register);
        assert!( smart_table::contains(&cap_table.caps, address) , 1);
        let cap = smart_table::remove(&mut cap_table.caps, address);
        let signer = &account::create_signer_with_capability(&cap) ;
        event::emit_event(&mut cap_table.publish_event_handler, PublishEvent{
            owner: signer::address_of(sender),
            seed,
            newAddress:signer::address_of(signer),
        });
        cap
    }
}
