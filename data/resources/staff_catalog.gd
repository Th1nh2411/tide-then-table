class_name StaffCatalog
extends Resource
## Everyone who could work at the restaurant, and the job ads Rin can post
## (index = tier - 1): a better ad costs more and brings better people.

@export var staff: Array[StaffData] = []
@export var ad_labels: Array[String] = ["Dán tờ rơi", "Đăng hội nhóm việc làm", "Gửi trung tâm việc làm"]
@export var ad_costs: Array[int] = [50, 200, 500]
## Applicants one ad brings (at most), and how many can work at once.
@export var applicants_per_ad: int = 2
@export var max_hired: int = 2
## Applicants waiting at most (oldest leave).
@export var max_candidates: int = 4
## Day the "Nhân viên" button shows up (the first days stay simple).
@export var unlock_day: int = 3


func find(id: String) -> StaffData:
	for person in staff:
		if person.id == id:
			return person
	return null
