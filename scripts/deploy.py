from brownie import accounts, OddsVRFHelper, Odds, OddsToken
from web3 import Web3


# deployed to fantom network
def deploy_odds_vrf_helper():
    acct = accounts.load("test-1")

    gateway = "0x97837985Ec0494E7b9C71f5D3f9250188477ae14"
    gas_receiver = "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6"
    vrf_coordinator = "0xbd13f08b8352A3635218ab9418E340c60d6Eb418"
    subscription_id = 281
    destination_address = ""

    odds_vrf_helper = OddsVRFHelper.deploy(
        gateway,
        gas_receiver,
        vrf_coordinator,
        destination_address,
        subscription_id,
        {"from": acct},
    )


# deployed to moonbase alpha
def deploy_odds_token():
    acct = accounts.load("test-1")

    odds_token = OddsToken.deploy({"from": acct})


# deployed to moonbase alpha
def deploy_odds():
    acct = accounts.load("test-1")

    gateway = "0x5769D84DD62a6fD969856c75c7D321b84d455929"
    gas_receiver = "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6"
    odds_token_address = OddsToken[-1].address
    destination_address = ""
    estimated_cross_chain_gas = Web3.toWei("0.37", "ether")

    odds = Odds.deploy(
        gateway,
        gas_receiver,
        odds_token_address,
        destination_address,
        estimated_cross_chain_gas,
        {"from": acct},
    )


# DONT FORGET TO FUND THE TWO CONTRACTS WITH DEV AND FTM !!!!!


def withdraw_fund_odds_vrf_helper():
    acct = accounts.load("test-1")
    OddsVRFHelper[-1].withdrawAllFunds({"from": acct})


def withdraw_fund_odds():
    acct = accounts.load("test-1")
    Odds[-1].withdrawAllFunds({"from": acct})


def main():
    deploy_odds()


# moonbeam-test
# fantom-testnet


# currennt odds token address = 0xEF53020fEb7b71E4B700531894991Cc7Ca553fb4
# current odds vrf helper address = 0x9F6e36A08315c6890FE402799176cd7748FcB695
# current odds core address = 0xe6B02DAde1E307FFE66a0664a7Ead2c8236eF5c7
