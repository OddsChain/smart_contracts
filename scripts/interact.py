from brownie import Odds, OddsVRFHelper, accounts


def update_odds_destination_address():
    acct = accounts.load("test-1")

    odds = Odds[-1]

    destination_address = "0x9F6e36A08315c6890FE402799176cd7748FcB695".encode("utf-8")
    tx = odds.updateDestinationAddress(destination_address, {"from": acct})
    tx.wait(1)


def update_odds_vrf_helper_destination_address():
    acct = accounts.load("test-1")

    odds_vrf_helper = OddsVRFHelper[-1]

    destination_address = "0xF142710c99dEB5a8b829Cea2dcE9e74dECA0ff8f".encode("utf-8")
    tx = odds_vrf_helper.updateDestinationAddress(destination_address, {"from": acct})
    tx.wait(1)


def get_current_timestamp():
    current_t = Odds[-1].getCurrentTimeStamp()
    print(current_t)


def main():
    get_current_timestamp()


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
