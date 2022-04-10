import pytest

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_increase_balance():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    #NEED TO DEPLOY ERC20 FIRST!!!
    # Deploy the contract.
    #contract = await starknet.deploy("./contracts/ERC4626.cairo",
                constructor_calldata=["","TokenName","TKN"])

    # Invoke increase_balance() twice.
    #await contract.increase_balance(amount=10).invoke()
    #await contract.increase_balance(amount=20).invoke()

    # Check the result of get_balance().
    #execution_info = await contract.get_balance().call()
    #assert execution_info.result == (30,)
