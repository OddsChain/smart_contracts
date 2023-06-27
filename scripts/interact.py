from brownie import Odds, OddsVRFHelper, OddsToken, accounts


def update_odds_destination_address():
    acct = accounts.load("test-1")

    odds = Odds[-1]

    destination_address = "0x9F6e36A08315c6890FE402799176cd7748FcB695".encode("utf-8")
    tx = odds.updateDestinationAddress(destination_address, {"from": acct})
    tx.wait(1)


def update_odds_vrf_helper_destination_address():
    acct = accounts.load("test-1")

    odds_vrf_helper = OddsVRFHelper[-1]

    destination_address = "0xe6B02DAde1E307FFE66a0664a7Ead2c8236eF5c7".encode("utf-8")
    tx = odds_vrf_helper.updateDestinationAddress(destination_address, {"from": acct})
    tx.wait(1)


def get_current_timestamp():
    current_t = Odds[-1].getCurrentTimeStamp()
    print(current_t)


def get_recernt_odds():
    print(Odds[-1].address)


def mint_odds_token():
    acct = accounts.load("test-1")
    amount = 1000 * 10**18
    user = "0x5F7FbE4bf8987FA77Ec6C22FD3f3d558B3b68D4e"

    OddsToken[-1].mintFree(user, amount, {"from": acct})


def main():
    mint_odds_token()


# ENTITY TYPES FOR SUBGRAPH


# 1. Bet Entity
# - betID
# - bet description
# - bet type || false == private validation && true == public validation
# - validators array
# - participants array
# - creator of bet
# - end time for bet
# - outcome of bet || 1 - yes won && 2 - no won
# - accepted
# - validation count for private bets
# - claim wait time for validators to challenge
# - to be set time for entry end time for public validator acceptance
# - bet statistics
#     - yesPool
#     - noPool
#     - totalPool
#     - yesPartcipants
#     - noParticipants
#     - yesOutcomeCount
#     - noOutcomeCount
# - bet report
#     - reporter
#     - maliciousValidator
#     - betId
#     - description
#     - currentlyChallenged
#     - voteTime
#     - support
#     - oppose
#     - reportOutcome
