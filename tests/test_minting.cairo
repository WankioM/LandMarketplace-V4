from starkware.starknet.testing.starknet import Starknet
import pytest

@pytest.mark.asyncio
async def test_minting():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("Contract.cairo")

    await contract.mint(1, "land1").invoke()
    land = await contract.get_land(1).call()
    assert land == (1, "land1")
