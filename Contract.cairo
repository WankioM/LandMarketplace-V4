%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.starknet.common.storage import Storage
from starkware.starknet.common.math_utils import assert_integer, safe_add
from starkware.starknet.common.utils import felt_to_address

# ERC721 implementation for Cairo can be found in community-built repositories.
# We will assume this is implemented, and we will focus on auction logic.
# Events in Starknet
@event
func Start(owner: felt, auction_id: felt, token_id: felt):
end

@event
func Bid(sender: felt, amount: felt):
end

@event
func Refund(bidder: felt, amount: felt):
end

@event
func End(winner: felt, amount: felt):
end

@event
func Cancel(owner: felt, auction_id: felt, token_id: felt):
end

# Contract storage
struct Land:
    owner: felt
    bidder: felt
    current_bid: felt
    starting_price: felt
    instant_selling_price: felt
    for_sale: felt

# Storage mapping for Lands and Auctions
@storage_var
func lands(token_id: felt) -> Land:
end

@storage_var
func auction_end(auction_id: felt) -> felt:
end

@storage_var
func all_auctions(auction_id: felt) -> felt:
end

@storage_var
func auction_duration() -> felt:
end

@storage_var
func auctions() -> felt:
end

@storage_var
func cancel_auction_penalty() -> felt:
end

# Initialize contract
@constructor
func constructor():
    let caller = get_caller_address()
    contract_owner.write(caller)
    auction_duration.write(10800)  # e.g., 3 hours in seconds
    auctions.write(0)
    cancel_auction_penalty.write(1000000000000000000)  # 1 ether equivalent in Starknet
end

# Helper function to ensure the caller is the owner of the auction
@view
func is_owner(auction_id: felt) -> felt:
    let caller = get_caller_address()
    let token_id = all_auctions.read(auction_id)
    let land = lands.read(token_id)
    assert(caller == land.owner)
    return 1
end

# Function to start an auction
@external
func start_auction(token_id: felt, starting_price: felt, instant_selling_price: felt):
    let caller = get_caller_address()

    # Ensure the caller owns the land
    let land = lands.read(token_id)
    assert(land.owner == caller)
    assert(land.for_sale == 0)

    # Update land data to mark it as for sale
    lands.write(token_id, Land(owner=caller, bidder=caller, current_bid=0, starting_price=starting_price, instant_selling_price=instant_selling_price, for_sale=1))

    # Increment auctions and set the auction end time
    let current_auctions = auctions.read()
    auction_end.write(current_auctions, get_block_timestamp() + auction_duration.read())
    all_auctions.write(current_auctions, token_id)
    auctions.write(current_auctions + 1)

    # Emit auction start event
    emit Start(owner=caller, auction_id=current_auctions, token_id=token_id)
end

# Function to place a bid
@external
func make_bid(auction_id: felt):
    let caller = get_caller_address()
    let timestamp = get_block_timestamp()

    # Ensure the auction is still ongoing
    let end_time = auction_end.read(auction_id)
    assert(timestamp <= end_time)

    # Retrieve auction information
    let token_id = all_auctions.read(auction_id)
    let land = lands.read(token_id)
    assert(caller != land.owner)  # Caller can't bid on their own land

    # Check bid amount
    let current_bid = land.current_bid
    let bid_amount = calldata[0]
    assert(bid_amount > current_bid)  # New bid must be higher than current

    # Refund the previous bidder, if applicable
    if current_bid > 0:
        send_refund(land.bidder, current_bid)

    # Update the bid in the auction
    lands.write(token_id, Land(owner=land.owner, bidder=caller, current_bid=bid_amount, starting_price=land.starting_price, instant_selling_price=land.instant_selling_price, for_sale=land.for_sale))

    emit Bid(sender=caller, amount=bid_amount)
end

# Helper function to handle refunds
@internal
func send_refund(bidder: felt, amount: felt):
    if amount > 0:
        # Implement refund logic (e.g., send funds back to the previous bidder)
        # Starknet uses different transfer mechanisms for funds
        # For now, we just emit an event
        emit Refund(bidder=bidder, amount=amount)
end

# Cancel auction (pay penalty to contract owner)
@external
func cancel_auction(auction_id: felt):
    let caller = get_caller_address()

    # Ensure the caller is the owner and auction is ongoing
    assert(is_owner(auction_id))
    let end_time = auction_end.read(auction_id)
    assert(get_block_timestamp() <= end_time)

    let token_id = all_auctions.read(auction_id)
    let land = lands.read(token_id)
    assert(land.for_sale == 1)

    # Pay penalty to contract owner
    let penalty = cancel_auction_penalty.read()
    send_refund(contract_owner.read(), penalty)

    # Reset the auction state
    lands.write(token_id, Land(owner=land.owner, bidder=caller, current_bid=0, starting_price=0, instant_selling_price=0, for_sale=0))

    emit Cancel(owner=caller, auction_id=auction_id, token_id=token_id)
end

# End auction and transfer ownership
@external
func end_auction(auction_id: felt):
    let caller = get_caller_address()

    # Ensure the auction has ended
    assert(is_owner(auction_id))
    let end_time = auction_end.read(auction_id)
    assert(get_block_timestamp() >= end_time)

    let token_id = all_auctions.read(auction_id)
    let land = lands.read(token_id)
    let winning_bid = land.current_bid

    assert(winning_bid > 0)
    assert(land.bidder != land.owner)

    # Transfer the winning bid to the landowner and transfer ownership
    send_refund(land.owner, winning_bid)
    lands.write(token_id, Land(owner=land.bidder, bidder=land.bidder, current_bid=0, starting_price=0, instant_selling_price=0, for_sale=0))

    emit End(winner=land.bidder, amount=winning_bid)
end
