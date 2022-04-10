%lang starknet
from starkware.starknet.common.syscalls import (get_contract_address,get_caller_address)
from starkware.cairo.common.uint256 import (Uint256,uint256_not)
from lib.cairo-contracts.openzeppelin.token.erc20.library import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,

    ERC20_initializer,
    ERC20_approve,
    ERC20_increaseAllowance,
    ERC20_decreaseAllowance,
    ERC20_transfer,
    ERC20_transferFrom,
    ERC20_mint
)
from contracts.Interfaces.IERC20 import IERC20

const felt_max = 2 ** 64

@event
func Deposit(caller: felt, owner: felt, assets: Uint256, shares: Uint256):
end

@event
func Withdraw(caller: felt, receiver: felt, owner: felt, assets: Uint256, shares: Uint256):
end

#############################
#
# STORAGE VALUES
#
#############################

@storage_var
func erc20() -> (address: felt):
end

#############################
#
# View Funtions
#
#############################

@view
func total_assets{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (assets: Uint256):
    let (asset) = erc20.read()
    let (this_address) = get_contract_address()
    let (assets:Uint256) = IERC20.balanceOf(asset,this_address) 
    return(assets)
end

@view
func convert_to_shares{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_assets:Uint256) -> (shares: Uint256):
    let (supply:Uint256) = ERC20_totalSupply.read()
    tempvar x = _assets == Uint256(0,0)
    tempvar y = supply == Uint256(0,0) 
        if bitwise_and(x,y):
            return(assets)
        end
    let (total_assets:Uint256) = total_assets.read()
    let (a) = uint256_mul(assets,supply)
    let (b) = uint256_div(a,total_assets) 
    return(b)       
end

@view
func convert_to_assets{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_shares:Uint256) -> (assets: Uint256):
    let (supply:Uint256) = ERC20_totalSupply.read()
    tempvar y = supply == Uint256(0,0)
        if y:
            return(_shares)
        end
    let (total_assets:Uint256) = total_assets.read()
    let (a) = uint256_mul(total_assets,_shares)
    let (b) = uint256_div(a,supply)
    return(b)
end

@view
func preview_deposit{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_assets:Uint256) -> (shares: Uint256):
    let (shares) = convert_to_shares(_assets) 
    return(shares)
end

@view
func preview_mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_shares:Uint256) -> (assets: Uint256):
    let (assets) = convert_to_assets(shares)
    let (x) = convert_to_shares(assets)
    let (y) = uint256_lt(x,_shares)
    if y:
        let (z) = uint256_add(assets,Uint256(0,1))
        return(z)
    end
    return(assets)
end

@view
func preview_withdraw{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_assets:Uint256) -> (shares: Uint256):
    let (shares) = convert_to_shares(_assets)
    let (x) = convert_to_assets(shares)
    let (y) = uint256_lt(x,_assets)
    if y:
        let (z) = uint256_add(shares,Uint256(0,1))
        return(z)
    end
    return(shares)
end

@view
func preview_redeem{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_shares:Uint256) -> (shares: Uint256):
    let (assets) = convert_to_assets(_shares)
    return(assets)
end

@view
func max_deposit{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (maximum_deposit: Uint256):
    return(Uint256(max_felt,max_felt))
end

@view
func max_mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (maximum_mint: Uint256):
    return(Uint256(max_felt,max_felt))
end

@view
func max_withdraw{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_owner: felt) -> (maximum_withdraw: Uint256):
    let (asset) = erc20.read() 
    let (owner_balance:Uint256) = IERC20.balanceOf(asset,_owner) 
    let (assets:Uint256) = convert_to_assets(owner_balance)
    return(assets)
end

@view
func max_redeem{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_owner: felt) -> (maximum_redeem: Uint256):
    let (asset) = erc20.read()
    let (owner_balance:Uint256) = IERC20.balanceOf(asset,_owner)
    return(owner_balance)
end

#############################
#
# Constructor
#
#############################

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _asset : felt, _name : felt, _symbol : felt):
    erc20_decimals = IERC20.decimals(_asset)
    ERC20_initializer(_name,_symbol,erc20_decimals)
    erc20.write(_asset)
end

#############################
#
# External Functions
#
#############################

@external
func deposit{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr
    }(_assets: Uint256, _receiver: felt) -> (shares: Uint256):
    let (shares:Uint256) = preview_deposit(_assets)
    
    assert shares != Uint256(0, 0)
    
    let (caller) = get_caller_address()
    let (this_address) = get_contract_address()
    let (asset) = erc20.read()
    IERC20.transferFrom(asset,caller,this_address,_assets)
    
    ERC20_mint(_receiver,shares)
    Deposit.emit(caller, receiver, _assets, shares)

    after_deposit(_assets, shares)

    return(shares)
end

@external
func mint{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr
    }(_shares: Uint256, _receiver: felt) -> (assets: Uint256):
    let (assets:Uint256) = previewMint(_shares)

    let (caller) = get_caller_address()
    let (this_address) = get_contract_address()
    IERC20.transferFrom(caller,this_address,_assets)

    ERC20_mint(_receiver,_shares)

    Deposit.emit(caller, receiver, _assets, shares)

    return(assets)
end

@external
func withdraw{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr
    }(_assets: Uint256,
      _receiver: felt,
      _owner: felt) -> (shares: Uint256):
    
    let (shares) = preview_withdraw(_assets)
    let (caller) = get_caller_address()    

    if caller != _owner:
        let (allowed:Uint256) = ERC20_allowance.read(_owner,caller)
	if allowed != Uint256(felt_max,felt_max):
            let (new_allowance:Uint256) = uint256_sub(allowed,shares)
	    ERC20_allowance.write(_owner,caller,new_allowance)
        end  
    end

    ERC20_burn(_owner, shares)

    Withdraw.emit(caller, _receiver, _owner, _assets, shares)
    
    let (asset) = erc20.read()
    IERC20.transfer(asset,_receiver,assets)

    return(shares)
end

@external
func redeem{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr
    }(_shares: Uint256,
      _receiver: felt,
      _owner: felt) -> (assets: Uint256):

    let (caller) = get_caller_address()
    if caller != owner:
        let (allowed:Uint256) = ERC20_allowance.read(_owner,caller)
        if allowed != Uint256(felt_max,felt_max):
            let (new_allowance:Uint256) = uint256_sub(allowed,shares)
            ERC20_allowance.write(_owner,caller,new_allowance)
        end    
    end  

    let (assets:Uint256) = preview_redeem(_shares)
    assert assets != Uint256(0,0)

    ERC20_burn(_owner, _shares)

    Withdraw.emit(caller, _receiver, _owner, _assets, shares)
    
    let (asset) = erc20.read()
    IERC20.transfer(asset,_receiver,assets)
    
    return(assets)
end
