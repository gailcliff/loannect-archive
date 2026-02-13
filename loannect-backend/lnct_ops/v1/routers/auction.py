from fastapi import APIRouter, Query
from typing import Annotated

from ..schemas import Bid

router = APIRouter(prefix='/auction', tags=['bids'])


@router.post('/bid')
def accept_lend_request(bid: Bid):
    # lender is accepting lend request of a borrower
    bid.make_bid()

    # return bool of whether the bid was made or not
    return bid.made()


@router.get('/bids/{bidder}')
def get_bidder_bids(bidder: int, bid_status: int = 0):
    return Bid.get_bidder_bids(bidder, bid_status=bid_status)


@router.get('/bids/auctioneer/{auctioneer}')
def get_auctioneer_bids(auctioneer: int):
    bids = Bid.get_auctioneer_bids(auctioneer)

    response = {
        "has_pending": bids is not None,
    }

    if bids is not None:
        response["pending"] = bids

    return response


@router.put('/bids/confirm/{bid_id}')
def confirm_bid(bid_id: int, proposal_id: Annotated[int, Query(alias='proposal')]) -> bool:

    # if borrower has already confirmed a bid, put functionality that prevents them from confirming another
    # bid of the same LoProposal (done)
    # todo prevent confirming if borrower had already deleted the proposal (lender could have loaded proposal from
    # server and before their list could be refreshed, borrower deleted it. so confirming wouldn't work)
    # todo borrower shouldn't be able to delete proposal if they have confirmed any bid

    return Bid.confirm(bid_id, proposal_id)


@router.get('/terms')
def get_terms(amount: int, base_weekly_rate: float):
    return f"""Terms and Conditions

1. By participating as a lender, you lend to borrowers on Loannect at your will. After lending, you earn money (profit) on the interest of the loan as the borrower repays, until they clear the debt.

2. Lending: By choosing to lend to a borrower, you agree to lend them the full amount that they borrowed. You will lend KSH {amount} to this borrower. \
However, between now and when you actually send the money to the borrower, you are free to cancel the transaction at any time.

3. Interest Rate: The interest rate for each loan is determined by Loannect. For this loan, the interest rate is {base_weekly_rate}% per week.

4. Repayment Schedule: Borrowers will repay the loan in instalments on a weekly basis from the time you lend to the time they finish off the loan repayment.

5. Risk Acknowledgment: Loannect does credit-scoring in our system and only displays to you loan applications from borrowers who have satisfactory credit scores and are likely to repay their requested loan amounts. \
However, by lending, you understand that lending carries a degree of risk, and that borrowers may default on repayments.

6. Late Payments: In case of late payments, the borrower's remaining debt will increase by 3% per week.

7. Default: If a borrower defaults on the loan, credit reporting, collections and legal action may be pursued to recover outstanding amounts.


By participating as a lender, you acknowledge understanding and agreeing to these terms.
"""
# 6. No Guarantee: You acknowledge that Loannect does not guarantee the repayment of loans by borrowers.
