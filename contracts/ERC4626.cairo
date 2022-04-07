
from starkware.starknet.common.syscalls import (get_contract_address,)
import ERC20
from starkware.cairo.common.uint256 import (Uint256,uint256_not)
import getcaller

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
func totalAssets{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (assets: Uint256):
    let (asset) = erc20.read()
    let (this_address) = get_contract_address()
    let (assets:Uint256) = IERC20.balanceOf(asset,this_address) 
    return(assets)
end

    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        uint256 supply = totalSupply();

        return
            (assets == 0 || supply == 0)
                ? (assets * 10**decimals()) / 10**_asset.decimals()
                : (assets * supply) / totalAssets();
    }

func convertToShares{
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
    YOU ARE HERE!!!! <----------------------------------------------------------------------------------------------------------
    return(assets)       
 
    end
end


#############################
#
# Constructor
#
#############################

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _asset : felt, _name : felt, _symbol : felt):
    erc20_decimals = IERC20(_asset).decimals()
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
    let (shares:Uint256) = previewDeposit(_assets)
    
    assert shares != Uint256(0, 0)
    
    let (caller) = get_caller_address()
    let (this_address) = get_contract_address()
    let (asset) = erc20.read()
    IERC20.transferFrom(asset,caller,this_address,_assets)
    
    ERC20_mint(_receiver,shares)
    Deposit.emit(caller, receiver, _assets, shares)

    afterDeposit(_assets, shares)

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
    
    let (shares) = previewWithdraw(_assets)
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

    let (assets:Uint256) = previewRedeem(_shares)
    assert assets != Uint256(0,0)

    ERC20_burn(_owner, _shares)

    Withdraw.emit(caller, _receiver, _owner, _assets, shares)
    
    let (asset) = erc20.read()
    IERC20.transfer(asset,_receiver,assets)
    
    return(assets)
end


#############################
#
# Internal Functions
#
#############################

