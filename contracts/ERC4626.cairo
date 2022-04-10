%lang starknet
from starkware.cairo.common.cairo_builtins import (HashBuiltin,BitwiseBuiltin)
from starkware.cairo.common.bitwise import bitwise_and
from starkware.starknet.common.syscalls import (get_contract_address,get_caller_address)
from starkware.cairo.common.uint256 import (Uint256,uint256_eq,uint256_lt)
from contracts.lib.ERC20_lib import (
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
    ERC20_mint,
    ERC20_burn
)
from contracts.Interfaces.IERC20 import IERC20
from contracts.lib.safemath_lib import (
    uint256_checked_add,
    uint256_checked_mul,
    uint256_checked_sub_le,
    uint256_checked_div_rem) 

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
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr
    }(_assets:Uint256) -> (shares: Uint256):
    alloc_locals
    let (supply:Uint256) = ERC20_totalSupply()
    let (x) = uint256_eq(_assets,Uint256(0,0))
    let (y) = uint256_eq(supply,Uint256(0,0)) 
    let (z) = bitwise_and(x,y)    
    if z == 1:
            return(_assets)
        end
    let (current_total_assets:Uint256) = total_assets()
    let (a) = uint256_checked_mul(_assets,supply)
    let (b,_) = uint256_checked_div_rem(a,current_total_assets) 
    return(b)       
end

@view
func convert_to_assets{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(_shares:Uint256) -> (assets: Uint256):
    alloc_locals
    let (supply:Uint256) = ERC20_totalSupply()
    let (y) = uint256_eq(supply,Uint256(0,0))
        if y == 1:
            return(_shares)
        end
    let (current_total_assets:Uint256) = total_assets()
    let (a) = uint256_checked_mul(current_total_assets,_shares)
    let (b,_) = uint256_checked_div_rem(a,supply)
    return(b)
end

@view
func preview_deposit{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr
    }(_assets:Uint256) -> (shares: Uint256):
    let (shares) = convert_to_shares(_assets) 
    return(shares)
end

@view
func preview_mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr
    }(_shares:Uint256) -> (assets: Uint256):
    alloc_locals
    let (assets) = convert_to_assets(_shares)
    let (x) = convert_to_shares(assets)
    let (y) = uint256_lt(x,_shares)
    if y == 1:
        let (z) = uint256_checked_add(assets,Uint256(0,1))
        return(z)
    end
    return(assets)
end

@view
func preview_withdraw{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, 
        range_check_ptr
    }(_assets:Uint256) -> (shares: Uint256):
    alloc_locals
    let (shares) = convert_to_shares(_assets)
    let (x) = convert_to_assets(shares)
    let (y) = uint256_lt(x,_assets)
    if y == 1:
        let (z) = uint256_checked_add(shares,Uint256(0,1))
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
    return(Uint256(felt_max,felt_max))
end

@view
func max_mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (maximum_mint: Uint256):
    return(Uint256(felt_max,felt_max))
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
    let (erc20_decimals) = IERC20.decimals(_asset)
    ERC20_initializer(_name,_symbol,erc20_decimals)
    erc20.write(_asset)
    return()
end

#############################
#
# External Functions
#
#############################

@external
func deposit{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr
    }(_assets: Uint256, _receiver: felt) -> (shares: Uint256):
    alloc_locals
    let (shares:Uint256) = preview_deposit(_assets)
    
    let (is_equal) = uint256_eq(shares,Uint256(0, 0))    
    assert is_equal = 0
    
    let (caller) = get_caller_address()
    let (this_address) = get_contract_address()
    let (asset) = erc20.read()
    IERC20.transferFrom(asset,caller,this_address,_assets)
    
    ERC20_mint(_receiver,shares)
    Deposit.emit(caller, _receiver, _assets, shares)

    return(shares)
end

@external
func mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr
    }(_shares: Uint256, _receiver: felt) -> (assets: Uint256):
    alloc_locals
    let (assets:Uint256) = preview_mint(_shares)

    let (caller) = get_caller_address()
    let (this_address) = get_contract_address()
    let (asset) = erc20.read()
    IERC20.transferFrom(asset,caller,this_address,assets)
    
    ERC20_mint(_receiver,_shares)

    Deposit.emit(caller, _receiver, assets, _shares)

    return(assets)
end

@external
func withdraw{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr
    }(_assets: Uint256,
      _receiver: felt,
      _owner: felt) -> (shares: Uint256):
    alloc_locals 
    let (shares) = preview_withdraw(_assets)
    let (caller) = get_caller_address()    
    if caller != _owner:
        let (local allowed:Uint256) = ERC20_allowance(_owner,caller)
	let (local x) = uint256_eq(Uint256(felt_max,felt_max),allowed)
        if x == 0:
            let (local new_allowance:Uint256) = uint256_checked_sub_le(allowed,shares)
	    ERC20_increaseAllowance(_owner,new_allowance)
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
     else:
         tempvar syscall_ptr : felt* = syscall_ptr
         tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
         tempvar range_check_ptr = range_check_ptr
     end

    ERC20_burn(_owner,shares)

    Withdraw.emit(caller, _receiver, _owner, _assets, shares)
    
    let (asset) = erc20.read()
    IERC20.transfer(asset,_receiver,_assets)

    return(shares)
end

@external
func redeem{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr
    }(_shares: Uint256,
      _receiver: felt,
      _owner: felt) -> (assets: Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    if caller != _owner:
        let (local allowed:Uint256) = ERC20_allowance(_owner,caller)
        let (local x) = uint256_eq(Uint256(felt_max,felt_max),allowed)
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr 
       if x == 0:
            let (local new_allowance:Uint256) = uint256_checked_sub_le(allowed,_shares)
            ERC20_increaseAllowance(_owner,new_allowance)
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
       else:
            tempvar syscall_ptr : felt* = syscall_ptr
            tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr 
       end    
    else:
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end  

    let (assets:Uint256) = preview_redeem(_shares)
    let (is_equal) = uint256_eq(assets,Uint256(0,0))
    assert is_equal = 0

    ERC20_burn(_owner, _shares)

    Withdraw.emit(caller, _receiver, _owner, assets, _shares)
    
    let (asset) = erc20.read()
    IERC20.transfer(asset,_receiver,assets)
    
    return(assets)
end
