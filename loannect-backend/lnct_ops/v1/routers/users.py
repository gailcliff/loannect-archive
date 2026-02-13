from fastapi import APIRouter

from ..schemas import User, UserInsights

router = APIRouter(
    prefix='/people',
    tags=['people']
)


@router.post('')
def register_user(user: User):
    user.save()

    return user.id


@router.put('/stamp/{user_id}')
def stamp_user(user_id: int, insights: UserInsights):
    insights.set_owner(user_id)
    save_result = insights.save()

    return save_result

