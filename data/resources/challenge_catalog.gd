class_name ChallengeCatalog
extends Resource
## All daily challenge templates; DailyChallenges rolls `per_day` a day from them.

@export var challenges: Array[ChallengeData] = []
## FAST challenges: a table counts if more than this share of patience is left.
@export var fast_patience: float = 0.5
@export var per_day: int = 3


func find(challenge_id: String) -> ChallengeData:
	for challenge in challenges:
		if challenge.id == challenge_id:
			return challenge
	return null
