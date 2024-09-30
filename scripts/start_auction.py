import os
import subprocess

def start_auction(land_id, starting_bid, instant_sell_price):

    print(f"Starting auction for land ID {land_id} with starting bid {starting_bid} and instant sell price {instant_sell_price}...")
    
  
    invoke_cmd = f"starknet invoke --function start_auction --inputs {land_id} {starting_bid} {instant_sell_price} --network alpha --address <contract_address> --abi contract_abi.json"
    

    os.system(invoke_cmd)

if __name__ == "__main__":
    land_id = input("Enter Land ID: ")
    starting_bid = input("Enter Starting Bid: ")
    instant_sell_price = input("Enter Instant Sell Price: ")
    
    start_auction(land_id, starting_bid, instant_sell_price)
