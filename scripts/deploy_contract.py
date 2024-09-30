import os
import subprocess

def deploy_contract():
  
    print("Deploying the contract...")
    compile_cmd = "starknet-compile Contract.cairo --output contract.json --abi contract_abi.json"
    deploy_cmd = "starknet deploy --contract contract.json --network alpha"
    

    os.system(compile_cmd)
    os.system(deploy_cmd)

if __name__ == "__main__":
    deploy_contract()
