lang starknet

@contract_interface
namespace IERC20:

    @view
    func name() -> (name: felt):
    end

    @view
    func symbol() -> (symbol: felt):
    end

    @view
    func totalSupply() -> (totalSupply: Uint256):
    end

    @view
    func decimals() -> (decimals: felt):
    end

    @view
    func balanceOf(account: felt) -> (balance: Uint256):
    end

    @view
    func allowance(owner: felt, spender: felt) -> (remaining: Uint256):
    end

    #
    # Externals
    #

    @external
    func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    end

    @external
    func transferFrom() -> (success: felt):
    end

    @external
    func approve(spender: felt, amount: Uint256) -> (success: felt):
    end

    @external
    func increaseAllowance(spender: felt, added_value: Uint256) -> (success: felt):
    end

    @external
    func decreaseAllowance(spender: felt, subtracted_value: Uint256) -> (success: felt):
    end
end
