from starkware.starknet.testing.starknet import Starknet
import pytest

@pytest.mark.asyncio
async def test_start_auction():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("Contract.cairo")

    await contract.start_auction(1, 1000, 5000).invoke()
    auction = await contract.get_auction(1).call()
    assert auction == (1000, 5000, True)
