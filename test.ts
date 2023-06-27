import { BigInt } from "@graphprotocol/graph-ts";
import {
  Odds,
  BetWinnings_Claimed,
  Bet_Accepted,
  Bet_Denied,
  Bet_Joined,
  Bet_Refunded,
  Bet_Validated,
  SingleBet_Created,
  ValidatorReportDecided,
  Validator_Assigned,
  Validator_Joined,
  Validator_Reported,
  supportValidator,
} from "../generated/Odds/Odds";
import { Bet } from "../generated/schema";

// export function handleBetWinnings_Claimed(event: BetWinnings_Claimed): void {}

export function handleBet_Accepted(event: Bet_Accepted): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.endTime = event.params.betEndTime;
  betEntity.accepted = true;

  betEntity.save();
}

export function handleBet_Denied(event: Bet_Denied): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.accepted = false;

  betEntity.save();
}

export function handleBet_Joined(event: Bet_Joined): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.participants = event.params.participants;

  betEntity.yesPool = event.params.yesPool;
  betEntity.noPool = event.params.noPool;
  betEntity.yesPool = event.params.yesParticipants;
  betEntity.yesPool = event.params.noParticipants;

  betEntity.save();
}

// export function handleBet_Refunded(event: Bet_Refunded): void {}

export function handleBet_Validated(event: Bet_Validated): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.outCome = event.params.outcome;
  betEntity.validationCount = event.params.validationCount;
  betEntity.claimWaitTime = event.params.claimWaitTime;

  betEntity.save();
}

export function handleSingleBet_Created(event: SingleBet_Created): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.betID = event.params.betID;
  betEntity.betDescription = event.params.description;
  betEntity.betType = event.params.betType;

  if (event.params.betType == false) {
    betEntity.validators = event.params.validators;
    betEntity.endTime = event.params.betEndTime;
    betEntity.accepted = true;
  }

  if (event.params.betType == true) {
    betEntity.toBeSetTime = event.params.betEndTime;
  }

  betEntity.creator = event.params.creator;

  betEntity.save();
}

export function handleValidatorReportDecided(
  event: ValidatorReportDecided
): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.currentlyChallenged = false;
  betEntity.reportOutcome = event.params.reportOutcome;

  betEntity.save();
}

export function handleValidator_Assigned(event: Validator_Assigned): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.validators = [event.params.validator];

  betEntity.save();
}

// export function handleValidator_Joined(event: Validator_Joined): void {}

export function handleValidator_Reported(event: Validator_Reported): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.maliciousValidator = event.params.validator;
  betEntity.reportDescription = event.params.description;
  betEntity.currentlyChallenged = true;
  betEntity.voteTime = event.params.voteTime;
  betEntity.reporter = event.params.reporter;

  betEntity.save();
}

export function handlesupportValidator(event: supportValidator): void {
  let betEntity = Bet.load(generateBetEntityId(event.params.betID));

  if (!betEntity) betEntity = new Bet(generateBetEntityId(event.params.betID));

  betEntity.support = event.params.support;

  betEntity.oppose = event.params.oppose;

  betEntity.save();
}

function generateBetEntityId(betId: BigInt): string {
  return "BetID" + betId.toString();
}



type Bet @entity {
    id: String!
    betID: BigInt!
    betDescription: String!
    betType: Boolean!
    validators: [Bytes!]
    participants: [Bytes!]
    creator: Bytes!
    endTime: BigInt
    outCome: BigInt
    accepted: Boolean
    validationCount: BigInt
    claimWaitTime: BigInt
    toBeSetTime: BigInt
    yesPool: BigInt
    noPool: BigInt
    totalPool: BigInt
    yesParticipants: BigInt
    noParticipants: BigInt
    reporter: Bytes
    maliciousValidator: Bytes
    reportDescription: String
    currentlyChallenged: Boolean
    voteTime: BigInt
    support: BigInt
    oppose: BigInt
    reportOutcome: BigInt
  }
  