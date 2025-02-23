module lawyer_platform::main { use sui::object::{Self, UID}; use sui::transfer; use sui::tx_context::{Self, TxContext}; use sui::event;

// Errors
const ENotWhitelisted: u64 = 0;

// Lawyer status
struct Lawyer has key, store {
    id: UID,
    address: address,
    is_whitelisted: bool,
    is_delegate: bool,
}

// Admin capability
struct AdminCap has key {
    id: UID
}

struct LawyerWhitelisted has copy, drop {
    lawyer_id: address,
    admin: address
}

struct DelegateAdded has copy, drop {
    lawyer_id: address,
    admin: address
}

// Initialize function
fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap {
        id: object::new(ctx)
    }, tx_context::sender(ctx))
}

// Admin whitelist lawyer
public entry fun whitelist_lawyer(
    admin: &AdminCap,
    lawyer: &mut Lawyer,
    ctx: &mut TxContext
) {
    lawyer.is_whitelisted = true;

    event::emit(LawyerWhitelisted {
        lawyer_id: lawyer.address,
        admin: tx_context::sender(ctx)
    });
}

// Admin add delegate
public entry fun add_delegate(
    admin: &AdminCap,
    lawyer: &mut Lawyer,
    ctx: &mut TxContext
) {
    assert!(lawyer.is_whitelisted, ENotWhitelisted);
    lawyer.is_delegate = true;

    event::emit(DelegateAdded {
        lawyer_id: lawyer.address,
        admin: tx_context::sender(ctx)
    });
}

// Lawyer registration
public entry fun register_lawyer(
    ctx: &mut TxContext
) {
    let lawyer = Lawyer {
        id: object::new(ctx),
        address: tx_context::sender(ctx),
        is_whitelisted: false,
        is_delegate: false,
    };

    transfer::share_object(lawyer);
}