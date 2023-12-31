# Overview

Odds is a decentralized betting platform built on smart contracts and running on moonbeam. It enables users to engage in betting activities without the need for extensive verification of the bet outcomes. This means that users can place a wide range of bets, from highly public events like predicting the outcome of an NBA match, to more personal matters like guessing if their mother will return from work before 9 pm. This versatility is made possible by the platform's combination of public and private validator mechanisms.

# Create Any Kind Of Yes Or No Bet

In each permissionless bet on Odds, the outcomes are based on "yes" or "no" possibilities. For instance, if a user creates a bet predicting that the Miami Heat will defeat the Denver Nuggets in the NBA Finals 2023, other users can choose to join either the "yes" or "no" side of the bet based on their own beliefs, along with their chosen stake. The higher the stake they contribute to their chosen outcome, the greater the potential reward.

The rewards in Odds are not generated by the platform itself but by the users who participate in the bets. To illustrate this, let's consider the NBA Finals example. Suppose the Denver Nuggets end up winning against the Miami Heat (as a fellow basketball enthusiast, I understand your passion!). In this scenario, the original bet, which claimed that the Miami Heat would win, is proven false after validation. As a result, all the users who staked on the "no" side of the bet emerge as winners, receiving a portion of the pool that was contributed by the users who bet "yes." The distribution of the pool among the winning users is based on the amount they staked.

# Accounts & Odds Token

Within the application, users have accounts that enable them to deposit our native token, ODDS, into their wallet. This wallet functionality allows users to perform various actions such as creating both public and private bets, claiming winnings from bets, joining existing bets, and requesting refunds. To engage in any activity on the application, users must ensure that their account balance is topped up.
If users need test ODDS tokens for experimentation or testing purposes, they can generate them by accessing the faucet page provided within the application.

# Bet Validation

Validation
Bet validation is a crucial procedure employed to determine the results of permissionless bets. Validators, who are users themselves, play a significant role in this process. Depending on the type of bet, there are two distinct categories of validators involved: Public Validators and Private Validators. Each type of bet requires a specific set of validators for its validation.

## Private Bets

Private bets, as the name suggests, do not necessarily restrict participation to a select few individuals; rather, they employ a validation mechanism that operates privately. In this context, "private" refers to the validation process rather than the number of participants.
In private bets, the bet creator has the ability to handpick three different validators who will collectively determine the outcome of the bet. It is strongly recommended that users exercise caution when joining private bets unless they are familiar with the validators involved.
To illustrate this, let's consider a scenario where friends place a bet on a game of FIFA, and other friends who are present during the game act as the validators. The crucial factors here are that the friends serving as validators must be available to witness the bet's outcome, and there must be a mutual trust among the bet participants and the private validators.
Once the game concludes, and two out of the three validators reach a consensus on the outcome, their decision—either "yes" or "no"—will determine the final result of the bet. Consequently, the winners will receive a portion of the stake amount from the losing side of the bet.
In summary: Private bets employ a private validation mechanism where the bet creator selects three validators. Users should exercise caution when joining private bets without knowledge of the validators. A real-life example of private bets could be friends betting on a FIFA game, with friends present during the match acting as validators. The outcome of the bet is determined by a consensus among two out of the three validators. Winners receive a share of the losing side's stake amount based on the validators' decision.

## Public Bets

In contrast to private bets, public bets utilize a validation mechanism that is publicly accessible. When it comes to public bets, users must undergo a specific process to ensure that their bets meet the requirements for public participation.

# Chainlink VRF And Public Bets Flow

Public Validators are the users who validate the outcomes of bets that anyone can join from across the globe. They operate under a system similar to Proof-of-Stake (POS) chains, which will be explained shortly.
To become a public validator, users are required to stake 1000 Odds tokens. Once they meet this requirement, they can enjoy the benefits of being a public validator.
The process for public bets involves several steps and considerations. Here is an ordered numbered list to clarify each point:

- When a user creates a public bet, it enters a pending state.
- Chainlink VRF (Verifiable Random Function) is utilized to assign a validator to the bet.
- The assigned validator reviews the bet to ensure it can be publicly verified by all other validators. For instance, betting on the outcome of a Premier League match is a - suitable example, whereas a friendly game of FIFA with a friend is not, as it lacks public validation.
- The validator is responsible for validating other factors, such as the bet entry time not exceeding the public outcome.
- Once the validator accepts the bet, users from around the world can participate until the bet's entry time expires.
- After the entry time is over, the validator validates the bet and determines its outcome.
- Winners must wait for a specific claim wait time, which applies to all bets.
- During this period, other validators can review the bet outcome. If they suspect that the validator acted maliciously and chose the wrong outcome, they can report the validator.
- Reported bets undergo a voting process among the validators to determine whether the reported act was malicious or not.
- If there is no challenge from other validators, winners can claim their rewards.
- If a challenge arises and it is determined that the validator acted maliciously, all participants are refunded. However, if the validator is found to have acted correctly, winners can claim their rewards as usual.

## The responsibilities and functions of a Public Validator

- Outcome Determination: Public validators have the authority to decide the outcome of public bets.
- Challenging Incorrect Outcomes: They are tasked with challenging other validators within the network who provide incorrect or inaccurate outcomes for bets.
- Voting on Challenged Outcomes: Public validators participate in the voting process to determine the final outcome of challenged bets, alongside other validators.
- Validation of Public Verifiability: Public validators are responsible for accepting or rejecting bets based on their ability to be publicly verified by every other validator in the network. They ensure that the bets meet the requirement of being openly verifiable.

# The advantages of being a Public Validator

- Reward Sharing: Public Validators receive a 10% share of the total rewards from the losing pool for every bet where they determine the outcome.
- Reporting Malicious Validators: By actively reporting validators who provide incorrect outcomes for bets and participating in the process of slashing and voting them out, Public Validators have the opportunity to claim the stakes of these malicious validators.

# Chainlink Use Case

For a full detailed explanation of the chainlink usecase. Visit our documentation.
Link - https://francis-4.gitbook.io/odds/use-cases/chainlink-use-case

To assign a validator for public bets, we utilized Chainlink VRF. However, since Chainlink VRF is not supported on Moonbeam, we employed Axelar to facilitate a cross-chain request. This allowed us to obtain a random number, which was then used to assign a validator at random for the public bet.

Sections in the smart contract that implements this

- `OddsVRFHelper` Contract - https://github.com/OddsChain/smart_contracts/blob/master/contracts/OddsVRFHelper.sol

  To receive the cross-chain request from the Odds contract and send back the fulfilled random number to it.

- `Odds` Contract - https://github.com/OddsChain/smart_contracts/blob/master/contracts/Odds.sol

  Contains all the core logic for the application. Also makes a cross chain request request for a random number when a publicbet is created, via chainlink VRF to the OddsVRFHelper and receives it to assign a random validator to the public bet.

# LINKS

- Live website - https://courageous-kheer-634a82.netlify.app/
- Youtube Video - https://youtu.be/jpBsil4wz3c
- Project Github - https://github.com/orgs/OddsChain/repositories
- Smart contract repo - https://github.com/OddsChain/smart_contracts
- Frontend Repo - https://github.com/OddsChain/frontend
- Subgraph Repo - https://github.com/OddsChain/subgraph
- Documentation - https://francis-4.gitbook.io/odds/
