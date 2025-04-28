module cross_call::evm {

    use std::u64::{Self};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::event::{Self};
    use sui::sui::{SUI};

    const SUI_DECIMALS: u8 = 9;
    const ETH_DECIMALS: u8 = 18;

    const ErrorInvalidTarget: u64 = 1;
    const ErrorCoinNotEnough: u64 = 2;
    const ErrorSequence: u64 = 3;

    public struct Deposit has key, store {
        id: UID,
        sequence: u256,
        evm_sequence: u256,
        balance: Balance<SUI>
    }

    public struct AdminCap has key, store {
        id: UID
    }

    public struct DepositAndCall has copy, drop {
        sequence: u256,
        sender: address,
        call_value: u256,
        gas_price: u256,
        gas_limit: u256,
        call_data: vector<u8>
    }

    public struct CrossChainCall has copy, drop {
        evm_sequence: u256
    }

    fun init(ctx: &mut TxContext) {
        let cap = AdminCap { id: object::new(ctx) };
        transfer::public_transfer(cap, tx_context::sender(ctx));

        let deposit = Deposit { id: object::new(ctx), sequence: 0, evm_sequence: 0, balance: balance::zero() };
        transfer::public_share_object(deposit);
    }

    public entry fun crossChainCall(_: &mut AdminCap, deposit: &mut Deposit, evm_sequence: u256) {
        assert!(evm_sequence == deposit.evm_sequence + 1, ErrorSequence);
        deposit.evm_sequence = evm_sequence;
        event::emit(CrossChainCall { evm_sequence });
    }

    public entry fun withdraw(
        _: &mut AdminCap,
        deposit: &mut Deposit,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let withdrawBalance = deposit.balance.split(amount);
        transfer::public_transfer(coin::from_balance(withdrawBalance, ctx), receiver);
    }

    public entry fun depositAndCall(
        deposit: &mut Deposit,
        coin: Coin<SUI>,
        call_value: u256, // evm链的单位
        gas_price: u256, // evm链的单位
        gas_limit: u256, // evm链的单位
        target: vector<u8>,
        data: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&target) == 42, ErrorInvalidTarget);
        let coinValue = coin.value();
        let gas = gas_price * gas_limit;
        let consume = (((gas + call_value) / (u64::pow(10, ETH_DECIMALS - SUI_DECIMALS) as u256)) as u64);
        assert!(consume <= coinValue, ErrorCoinNotEnough);

        let sender = tx_context::sender(ctx);

        let mut bal = coin::into_balance(coin);
        let consumeBal = bal.split(consume);
        deposit.balance.join(consumeBal);

        if (bal.value() > 0) {
            transfer::public_transfer(coin::from_balance(bal, ctx), sender);
        } else {
            balance::destroy_zero(bal);
        };

        let mut call_data = vector::empty<u8>();
        vector::append(&mut call_data, target);
        vector::append(&mut call_data, data);

        let sequence = deposit.sequence + 1;
        deposit.sequence = sequence;

        event::emit(DepositAndCall {
            sequence,
            sender,
            call_value,
            gas_price,
            gas_limit,
            call_data
        });
    }
}