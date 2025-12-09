from web3 import Web3
from .abis import ERC20_ABI, ESCROW_ABI

# polygon amoy RPC (use any RPC you prefer)
RPC_URL = "https://rpc-amoy.polygon.technology"

# connect
web3 = Web3(Web3.HTTPProvider(RPC_URL))

# contract addresses
TOKEN_ADDRESS = "0x48B0DB4e87D280AFB3fDC572f61A641E7261D74D"
ESCROW_ADDRESS = "0xbe6E842E5CCD8752EF538B7874530F3bE702e8Ae"

# owner's private key (prototype only)
OWNER_PRIVATE_KEY = "ce60907eb0556287ec1452c7c625cd93daf1f376392ad0e5dc6159e9502d3765"
OWNER_ADDRESS = Web3.to_checksum_address("0x7f06ccb5869a837c73a63b899388f9a256d5d12d")

# Initialize Contracts
token_contract = web3.eth.contract(address=TOKEN_ADDRESS, abi=ERC20_ABI)
escrow_contract = web3.eth.contract(address=ESCROW_ADDRESS, abi=ESCROW_ABI)


