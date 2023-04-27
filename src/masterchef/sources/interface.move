module masterchef::interface {
    use std::vector;

    use sui::clock::{Clock};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Coin};

    use masterchef::masterchef::{Self, MasterChefStorage, AccountStorage};
    use masterchef::utils;

    use sdoge::sdoge::{SDOGEStorage};
    /**
    * @notice It allows a user to deposit a Coin<T> in a farm to earn Coin<SDOGE>. 
    * @param storage The MasterChefStorage shared object
    * @param accounts_storage The AccountStorage shared object
    * @param sdoge_storage The shared Object of SDOGE
    * @param clock_object The Clock object created at genesis
    * @param vector_token  A list of Coin<Y>, the contract will merge all coins into with the `coin_y_amount` and return any extra value 
    * @param coin_token_amount The desired amount of Coin<X> to send
    */
    entry public fun stake<T>(
        storage: &mut MasterChefStorage,
        accounts_storage: &mut AccountStorage,
        sdoge_storage: &mut SDOGEStorage,
        clock_object: &Clock,
        vector_token: vector<Coin<T>>,
        coin_token_amount: u64,
        ctx: &mut TxContext
    ) {

        // Create a coin from the vector. It keeps the desired amound and sends any extra coins to the caller
        // vector total value - coin desired value
        let token = utils::handle_coin_vector<T>(vector_token, coin_token_amount, ctx);

        // Stake and send Coin<SDOGE> rewards to the caller.
        transfer::public_transfer(
        masterchef::stake(
            storage,
            accounts_storage,
            sdoge_storage,
            clock_object,
            token,
            ctx
        ),
        tx_context::sender(ctx)
        );
    }

    /**
    * @notice It allows a user to withdraw an amount of Coin<T> from a farm. 
    * @param storage The MasterChefStorage shared object
    * @param accounts_storage The AccountStorage shared object
    * @param sdoge_storage The shared Object of SDOGE
    * @param clock_object The Clock object created at genesis
    * @param coin_value The amount of Coin<T> the caller wishes to withdraw
    */
    entry public fun unstake<T>(
        storage: &mut MasterChefStorage,
        accounts_storage: &mut AccountStorage,
        sdoge_storage: &mut SDOGEStorage,
        clock_object: &Clock,
        coin_value: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        // Unstake yields Coin<SDOGE> rewards.
        let (coin_sdoge, coin) = masterchef::unstake<T>(
            storage,
            accounts_storage,
            sdoge_storage,
            clock_object,
            coin_value,
            ctx
        );
        transfer::public_transfer(coin_sdoge, sender);
        transfer::public_transfer(coin, sender);
    }

    /**
    * @notice It allows a user to withdraw his/her rewards from a specific farm. 
    * @param storage The MasterChefStorage shared object
    * @param accounts_storage The AccountStorage shared object
    * @param sdoge_storage The shared Object of SDOGE
    * @param clock_object The Clock object created at genesis
    */
    entry public fun get_rewards<T>(
        storage: &mut MasterChefStorage,
        accounts_storage: &mut AccountStorage,
        sdoge_storage: &mut SDOGEStorage,
        clock_object: &Clock,
        ctx: &mut TxContext   
    ) {
        transfer::public_transfer(masterchef::get_rewards<T>(storage, accounts_storage, sdoge_storage, clock_object, ctx) ,tx_context::sender(ctx));
    }

    /**
    * @notice It updates the Coin<T> farm rewards calculation.
    * @param storage The MasterChefStorage shared object
    * @param clock_object The Clock object created at genesis
    */
    entry public fun update_pool<T>(storage: &mut MasterChefStorage, clock_object: &Clock) {
        update_pool<T>(storage, clock_object);
    }

    /**
    * @notice It updates all pools.
    * @param storage The MasterChefStorage shared object
    * @param clock_object The Clock object created at genesis
    */
    entry public fun update_all_pools(storage: &mut MasterChefStorage, clock_object: &Clock) {
        update_all_pools(storage, clock_object);
    }

    /**
    * @dev A utility function to return to the frontend the allocation, pool_balance and _account balance of farm for Coin<X>
    * @param storage The MasterChefStorage shared object
    * @param accounts_storage the AccountStorage shared object of the masterchef contract
    * @param account The account of the user that has Coin<X> in the farm
    * @param farm_vector The list of farm data we will be mutation/adding
    */
    fun get_farm<X>(
        storage: &MasterChefStorage,
        accounts_storage: &AccountStorage,
        account: address,
        farm_vector: &mut vector<vector<u64>>
    ) {
        let inner_vector = vector::empty<u64>();
        let (allocation, _, _, pool_balance) = masterchef::get_pool_info<X>(storage);

        vector::push_back(&mut inner_vector, allocation);
        vector::push_back(&mut inner_vector, pool_balance);

        if (masterchef::account_exists<X>(storage, accounts_storage, account)) {
        let (account_balance, _) = masterchef::get_account_info<X>(storage, accounts_storage, account);
        vector::push_back(&mut inner_vector, account_balance);
        } else {
        vector::push_back(&mut inner_vector, 0);
        };

        vector::push_back(farm_vector, inner_vector);
    }

    /**
    * @dev The implementation of the get_farm function. It collects information for ${num_of_farms}.
    * @param storage The MasterChefStorage shared object
    * @param accounts_storage the AccountStorage shared object of the masterchef contract
    * @param account The account of the user that has Coin<X> in the farm
    * @param num_of_farms The number of farms we wish to collect data from for a maximum of 5
    */
    public fun get_farms<A, B, C, D, E>(
        storage: &MasterChefStorage,
        accounts_storage: &AccountStorage,
        account: address,
        num_of_farms: u64
    ): vector<vector<u64>> {
        let farm_vector = vector::empty<vector<u64>>(); 

        get_farm<A>(storage, accounts_storage, account, &mut farm_vector);

        if (num_of_farms == 1) return farm_vector;

        get_farm<B>(storage, accounts_storage, account, &mut farm_vector);

        if (num_of_farms == 2) return farm_vector;

        get_farm<C>(storage, accounts_storage, account, &mut farm_vector);

        if (num_of_farms == 3) return farm_vector;

        get_farm<D>(storage, accounts_storage, account, &mut farm_vector);

        if (num_of_farms == 4) return farm_vector;

        get_farm<E>(storage, accounts_storage, account, &mut farm_vector);

        if (num_of_farms == 5) return farm_vector;

        farm_vector
    }
}