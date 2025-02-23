module lawyer_platform::escrow { use sui::object::{Self, UID}; use sui::transfer; use sui::tx_context::{Self, TxContext}; use sui::coin::{Self, Coin}; use sui::sui::SUI; use sui::event;

// Errors
const EInvalidAmount: u64 = 0;
const EAlreadyCompleted: u64 = 1;

// Events
struct PaymentDeposited has copy, drop {
    appointment_id: vector<u8>,
    client: address,
    amount: u64
}

struct PaymentReleased has copy, drop {
    appointment_id: vector<u8>,
    lawyer: address,
    amount: u64
}

struct PaymentRefunded has copy, drop {
    appointment_id: vector<u8>,
    client: address,
    amount: u64
}

// Escrow object to hold payment
struct Escrow has key {
    id: UID,
    appointment_id: vector<u8>,
    amount: u64,
    client: address,
    lawyer: address,
    is_completed: bool,
    coin: Coin<SUI>
}

// Admin capability
struct AdminCap has key {
    id: UID
}

// Initialize function - called once when module is published
fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap {
        id: object::new(ctx)
    }, tx_context::sender(ctx))
}

// Client deposits payment
public entry fun deposit_payment(
    appointment_id: vector<u8>,
    lawyer: address,
    payment: Coin<SUI>,
    ctx: &mut TxContext
) {
    let amount = coin::value(&payment);
    assert!(amount > 0, EInvalidAmount);

    let escrow = Escrow {
        id: object::new(ctx),
        appointment_id,
        amount,
        client: tx_context::sender(ctx),
        lawyer,
        is_completed: false,
        coin: payment
    };

    event::emit(PaymentDeposited {
        appointment_id: escrow.appointment_id,
        client: tx_context::sender(ctx),
        amount
    });

    transfer::share_object(escrow);
}

// Admin releases payment to lawyer
public entry fun release_to_lawyer(
    _: &AdminCap,
    escrow: &mut Escrow,
    ctx: &mut TxContext
) {
    assert!(!escrow.is_completed, EAlreadyCompleted);

    let payment = coin::split(&mut escrow.coin, escrow.amount, ctx);
    transfer::public_transfer(payment, escrow.lawyer);

    escrow.is_completed = true;

    event::emit(PaymentReleased {
        appointment_id: escrow.appointment_id,
        lawyer: escrow.lawyer,
        amount: escrow.amount
    });
}

// Admin refunds payment to client
public entry fun refund_to_client(
    _: &AdminCap,
    escrow: &mut Escrow,
    ctx: &mut TxContext
) {
    assert!(!escrow.is_completed, EAlreadyCompleted);

    let payment = coin::split(&mut escrow.coin, escrow.amount, ctx);
    transfer::public_transfer(payment, escrow.client);

    escrow.is_completed = true;

    event::emit(PaymentRefunded {
        appointment_id: escrow.appointment_id,
        client: escrow.client,
        amount: escrow.amount
    });
}

// View functions
public fun get_escrow_info(escrow: &Escrow): (address, address, u64, bool) {
    (escrow.client, escrow.lawyer, escrow.amount, escrow.is_completed)
}