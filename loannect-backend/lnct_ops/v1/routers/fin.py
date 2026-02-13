from fastapi import APIRouter, Body
from typing import Annotated
from enum import Enum
from ..schemas import PendingTransaction, Lo, Instalment


class TransactionType(str, Enum):
    SEND = 'send'
    RECEIPT = 'receipt'


router = APIRouter(prefix='/fin', tags=['fin'])


@router.get('/pending/{user_id}')
def get_pending_transaction(user_id: int, transaction_type: TransactionType):
    """
    get the latest pending 'send' or 'receipt' transaction for the user, depending on the transaction type.
    :param transaction_type: either 'send' or 'receipt'
    :param user_id: the user for whom to fetch pending transaction for
    :return: a dict of two entries, latest pending 'send' and 'receipt' transaction. null values if not existing
    """

    return PendingTransaction.get_user_pending_send_transaction(user_id) \
        if transaction_type is TransactionType.SEND \
        else PendingTransaction.get_user_pending_receipt_transaction(user_id)


@router.get('/expecting_receipt/{user}')
def expecting_receipt(user: int):
    return PendingTransaction.user_expecting_receipt(user)


@router.get('/debt/{user}')
def get_current_loan(user: int) -> Lo | None:
    return Lo.get_user_current_loan(user)


@router.get('/lends/{user}')
def get_current_lend_outs(user: int):
    return Lo.get_user_current_lend_outs(user)


@router.post('/repay/{lo_id}')
def repay_loan(lo_id: int, amount: Annotated[int, Body()], source: Annotated[dict, Body()]):

    return Lo.repay_instalment(lo_id, amount, source)


@router.get('/owed/{user}')
def check_if_user_is_owed(user: int):
    return Lo.is_user_owed(user)


@router.put('/confirm-instalment/{instalment}')
def confirm_instalment_received(instalment: int):
    return Instalment.confirm(instalment)
