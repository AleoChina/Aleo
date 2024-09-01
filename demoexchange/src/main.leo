// The 'demoexchange' program.
program demoexchange.aleo {


    record Cubias{
        owner : address
        amount : u64,
        cubias: u64,
    }


    struct CubiaInfo {
        cubia_id: field,
        max_cubia: u64,
        receiver: address,
        cubia_price: u64,
        total_cubia: u64,
    }

    // cubia id => cubias
    mapping unique_cubia: field => CubiaInfo;

    mapping account: address => u64;

    async transition buy_cubia (owner: address,  amount: u64,  cubias: u64) -> (Cubias, u64, Future) {

            // max for unique cubias
            let max_cubia: u64 = 1u64;

            // spend amount
            let price: u64 = 1000u64;

            let current_cubia : Cubias = Cubias{
                owner: owner,
                amount:  amount - price,
                cubias: cubias,
            };

            return (current_cubia, price, finalize_buy_cubia(owner, price, max_cubia));
    }

    async function finalize_buy_cubia (owner: address, price: u64, max_cubia: u64) {

            let hash_user_field: field = Keccak512::hash_to_field(owner);

            // random id
            let id: field = ChaCha::rand_field();

            let cubia_info: CubiaInfo = Mapping::get_or_use(unique_cubia, hash_user_field, CubiaInfo {
                cubia_id: id,
                max_cubia: 0u64,
                receiver: owner,
                cubia_price: price,
                total_cubia: 0u64,
            });


            let balance: u64 = Mapping::get_or_use(account, owner, 1000u64);
            Mapping::set(account, owner, balance - cubia_info.cubia_price);

            assert(balance > cubia_info.cubia_price);

            assert(cubia_info.receiver == owner);

            assert(cubia_info.max_cubia >= 0u64);

            assert(cubia_info.total_cubia <= 10000u64);

            Mapping::set(unique_cubia, hash_user_field, CubiaInfo {
                cubia_id: cubia_info.cubia_id,
                max_cubia: (cubia_info.max_cubia + max_cubia),
                receiver: cubia_info.receiver,
                cubia_price: (cubia_info.cubia_price + 100u64),
                total_cubia: cubia_info.total_cubia + max_cubia,
            });
    }


    async transition sale_cubia (owner: address, to_address: address) -> (address, address, Future){

        return (owner, to_address, finalize_sale_cubia(owner, to_address));
    }

    async function finalize_sale_cubia (owner: address, buyer: address) {

        let hash_user_field: field = Keccak512::hash_to_field(owner);
        let hash_receiver_field: field = Keccak512::hash_to_field(buyer);

        let cubia_info: CubiaInfo = Mapping::get_or_use(unique_cubia, hash_user_field, CubiaInfo {
            cubia_id: 111field,
            max_cubia: 10u64,
            receiver: owner,
            cubia_price: 600u64,
            total_cubia: 10u64,
        });


        let buyer_balance: u64 = Mapping::get_or_use(account, buyer, 1000u64);
        Mapping::set(account, buyer, buyer_balance - (cubia_info.max_cubia * cubia_info.cubia_price));

        let owner_balance: u64 = Mapping::get_or_use(account, owner, 1000u64);
        Mapping::set(account, owner, owner_balance + (cubia_info.max_cubia * cubia_info.cubia_price));

        let new_cubia_owner: u64 = cubia_info.max_cubia;

        Mapping::set(unique_cubia, hash_user_field, CubiaInfo {
            cubia_id: cubia_info.cubia_id,
            max_cubia: new_cubia_owner,
            receiver: owner,
            cubia_price: (cubia_info.cubia_price - 100u64),
            total_cubia: (cubia_info.total_cubia - cubia_info.max_cubia),
        });

        let new_cubia_buyer: u64 = cubia_info.max_cubia + new_cubia_owner;

        Mapping::set(unique_cubia, hash_receiver_field, CubiaInfo {
            cubia_id: cubia_info.cubia_id,
            max_cubia: new_cubia_buyer,
            receiver: buyer,
            cubia_price: cubia_info.cubia_price,
            total_cubia: cubia_info.total_cubia
        });

        Mapping::remove(unique_cubia, hash_user_field);
    }
}
