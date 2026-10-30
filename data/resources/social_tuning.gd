class_name SocialTuning
extends Resource
## Balance for "Xóm Đèn Review" (XomDenReview): posts per shift, likes,
## follower gain/loss, tiers and their rewards. data/social/social_tuning.tres.

## Posts after a shift (fewer if fewer tables came).
@export var min_posts: int = 2
@export var max_posts: int = 4
## One more post per this many tables served (on top of min_posts).
@export var tables_per_post: int = 3
## Posts kept in the save (newest first).
@export var max_saved_posts: int = 20

## Post stars from the patience left when served (>= value -> stars).
@export var five_star_patience: float = 0.6
@export var four_star_patience: float = 0.4
@export var three_star_patience: float = 0.2
## Below this freshness (0-100) the dish costs a star.
@export var stale_freshness: float = 50.0

## Likes = (base + stars * per_star + followers * follower_share) * random(spread).
@export var likes_base: float = 3.0
@export var likes_per_star: float = 4.0
@export var likes_follower_share: float = 0.06
@export var likes_spread: float = 0.3
@export var hot_likes_scale: float = 1.5

## Follower change by the day's rating (index = stars, 0 unused).
@export var followers_by_stars: Array[int] = [0, -8, -3, 2, 6, 12]
## Extra followers per like on today's posts.
@export var followers_per_like: float = 0.1
@export var followers_per_hot_dish: int = 1
@export var followers_per_challenge: int = 3
@export var followers_per_lost: int = 2

## Tiers: name, followers needed, one-time reward (k), spawn interval scale.
@export var tier_names: Array[String] = ["Quán vỉa hè", "Quán quen", "Quán có tiếng", "Quán nổi tiếng"]
@export var tier_followers: Array[int] = [0, 40, 120, 300]
@export var tier_reward_k: Array[int] = [0, 60, 150, 300]
## Multiplies the time between guests (lower = more guests).
@export var tier_spawn_scale: Array[float] = [1.0, 0.95, 0.9, 0.85]
