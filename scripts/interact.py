from brownie import Odds, OddsVRFHelper, OddsToken, accounts


def update_odds_destination_address():
    acct = accounts.load("test-1")

    odds = Odds[-1]

    destination_address = "0xf6F74F2aCd9F11ED7873Bc95f666A9b876b305ed".encode("utf-8")
    tx = odds.updateDestinationAddress(destination_address, {"from": acct})
    tx.wait(1)


def update_odds_vrf_helper_destination_address():
    acct = accounts.load("test-1")

    odds_vrf_helper = OddsVRFHelper[-1]

    destination_address = "0xf3e30B0891521D595247AEB48F72105A4434B09E".encode("utf-8")
    tx = odds_vrf_helper.updateDestinationAddress(destination_address, {"from": acct})
    tx.wait(1)


def get_current_timestamp():
    current_t = Odds[-1].getCurrentTimeStamp()
    print(current_t)


def get_recernt_odds():
    print(Odds[-1].address)


def mint_odds_token():
    acct = accounts.load("test-1")
    amount = 100000 * 10**18
    user = "0x5F7FbE4bf8987FA77Ec6C22FD3f3d558B3b68D4e"
    user_two = "0x52047DE4458AfaaFF7C6B954C63033A21EfCD2E6"

    OddsToken[-1].mintFree(user_two, amount, {"from": acct})


def main():
    update_odds_vrf_helper_destination_address()
