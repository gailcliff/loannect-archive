from fastapi import APIRouter, Body
from typing import Annotated
from ..schemas import Bid, PendingTransaction

router = APIRouter(prefix='/le', tags=['le'])


@router.post('/initiate/{bid}')
def initiate_transaction(bid: int):
    return Bid.initiate_transaction(bid)


@router.put('/complete')
def confirm_transaction_complete(bid: Bid, source: Annotated[dict, Body()]):
    # lender is confirming completion of transaction. update state
    return PendingTransaction.confirm_complete(bid, source)


@router.put('/received')
def confirm_transaction_receipt(bid: Bid):
    return PendingTransaction.confirm_receipt(bid)
