import json
from datetime import date
import math

from pydantic import BaseModel
from typing import Type
from enum import Enum

from ops import models as db_models

from .. import cache
from ..cache.proposal_loop import push_to_algo, get_feed


class BaseSchema(BaseModel):
    id: int | None = None
    __schema_cls__: Type[db_models.DbModel]

    def save(self, only_fields: set[str] | None = None, except_fields: set[str] | None = None):
        db_model = self.__schema_cls__.__call__(**self.model_dump(include=only_fields, exclude=except_fields))
        db_model.save()

        self.id = db_model.id

        return db_model


class Gender(str, Enum):
    MALE = 'M'
    FEMALE = 'F'
    OTHER = 'O'


class LoEligibility(Enum):
    OK = 1
    PENDING_APPROVAL = 2
    HAS_DEBT = 3
    PLEASE_WAIT = 4


class Calculator:
    @staticmethod
    def base_weekly_percent_interest_rate():
        return 2.8

    @staticmethod
    def base_daily_percent_interest_rate():
        return 0.4

    @staticmethod
    def get_weekly_instalments(amount: int) -> dict:
        def calculate_weekly_instalment_based_on_months(months: int) -> int:
            num_weeks = months * 4
            total_payout_based_on_months = amount * math.pow(  # Pe^(rt). t is no. of weeks, r is weekly interest rate
                math.e,
                ((Calculator.base_weekly_percent_interest_rate() / 100) * num_weeks)
            )
            weekly_instalment = total_payout_based_on_months / num_weeks
            return math.ceil(weekly_instalment)

        return {
            f"{month_no}": calculate_weekly_instalment_based_on_months(month_no) for month_no in range(1, 7)
        }


class User(BaseSchema):
    __schema_cls__ = db_models.User

    full_name: str
    country: str
    phone: str
    dob: date
    gender: Gender
    email: str | None = None

    @staticmethod
    def is_stamped(user_id: int) -> bool:
        # check if user provided their verification info. if they provided, then their user insights should be in the db
        # if not, return error
        try:
            # foo: str = db_models.User(id=user_id).userinsights.nat_id
            # return '#' in foo  # this step is unnecessary. we could've stopped at previous line
            temp = db_models.UserInsights.objects.get(user=db_models.User(id=user_id))
            return temp is not None
        except db_models.UserInsights.DoesNotExist:
            return False

    @staticmethod
    def get_lo_eligibility(user_id: int) -> LoEligibility:
        """
        check if the user is eligible for a loan
        user not eligible if:
        - they currently have a pending loan application (haven't yet got a lender)
        - they have an unfinished debt, and they are still repaying a loan, or they stopped paying
        - it's been less than two days since their most recent loan application (no bs'ing with frequent applications)
        :param user_id: the id if the user
        :return: bool of whether eligible for loan
        """

        # get latest pending loan application of user
        latest_borrower_proposal = LoProposal.get_latest_of_borrower(user_id)

        if latest_borrower_proposal is not None:
            # if latest_borrower_proposal is not null, it means the user has a pending loan application, therefore
            # they're not eligible for another one unless the current one gets closed (endorsed or cancelled)

            return LoEligibility.PENDING_APPROVAL
        else:
            # get latest 'closed' loan application of borrower (meaning they got a lender, or they cancelled their app)
            latest_closed_proposal = LoProposal.get_latest_of_borrower(user_id, closed=True)

            # first todo check if user has completed loan repayments fully
            # we can't use the above latest_borrower_proposal to check if loan has been repaid fully cause
            # it is not even 'closed' in the first place. only 'closed' proposals can have instalments (loan payments).
            # Load the latest LoProposal for the user that is closed and then do loproposal.lo.settled (if lo != null)
            # to check if user has finished payment. If loproposal.lo is None and the 'closed' is true in LoProposal,
            # it means the borrower deleted their loan application. we can use 'closer' to check if the loan application
            # got a lender, just to double-check.

            if latest_closed_proposal is not None:
                # check if user has completed loan payments
                # ...
                # ...

                def forty_eight_hour_rule_passed() -> bool:
                    millis_diff = db_models.current_time_millis() - latest_closed_proposal.proposed_on
                    days_diff = millis_diff / 86_400_000

                    return days_diff >= 2
                    # return days_diff >= 0.5     # todo beta. remove in prod

                if not forty_eight_hour_rule_passed():
                    return LoEligibility.PLEASE_WAIT

        return LoEligibility.OK


class UserInsights(BaseSchema):
    __schema_cls__ = db_models.UserInsights

    # the owner of this user insights
    user: object | None = None

    nat_id: str
    address: str
    occupation: dict
    other_jobs: str
    income: dict

    def set_owner(self, user_id: int):
        self.user = db_models.User(id=user_id)

    def save(self, **kwargs) -> dict:
        save_result = {
            'updated': True
        }

        try:
            # save existing record, conditionally
            # condition is that a user insights record can't be updated more than once in  a span of 30 days
            # use the 'last_saved' field to compute how much time has passed between last saved and today
            # if <= 30, not allowed, else save

            # existing = db_models.UserInsights.objects.get(user=self.user)
            # the user already exists in the db, so you can access the user's insights through user.userinsights getter.
            # if the respective record doesn't exist in the user insights table, an error will be thrown
            existing_insights = self.user.userinsights

            last_saved = existing_insights.last_saved
            now = db_models.current_time_millis()

            def conditional_save_allowed():
                millis_diff = now - last_saved

                # beta. todo remove in prod
                # minutes_diff = (millis_diff / 1000) / 60
                # print("minutes since last saved:", minutes_diff)
                # return minutes_diff >= 5

                # todo prod
                days_diff = millis_diff / 86_400_000
                return days_diff >= 30

            if conditional_save_allowed():
                # enough time has passed since last save. go on to save new record...
                print("updating user insights conditionally...")

                existing_insights.address = self.address
                existing_insights.occupation = self.occupation
                existing_insights.other_jobs = self.other_jobs
                existing_insights.income = self.income
                existing_insights.last_saved = now
                # id no. is immutable.
                existing_insights.save(update_fields={'address', 'occupation', 'other_jobs', 'income', 'last_saved'})
            else:
                # time between saves is below threshold. decline update save.
                save_result['updated'] = False
                save_result['error_type'] = 'mutation'
                save_result['msg'] = 'You can only make changes to this info starting from 30 days ' \
                                     'since you last updated it'

        except:
            # an error was thrown because the record wasn't found. this means this is a totally new record
            user_nat_id = self.nat_id
            try:
                # the user object that we initialized was just a plain 'lazy' user object with only the 'id' field
                # now let's get the actual user from the db and only load the 'country' field
                self.user.refresh_from_db(fields={'country'})
                self.nat_id = f"{self.user.country}#{user_nat_id}"  # examples: KE#8583932, US#342380, NG#54960002

                super().save()
                print("saved new user insights...")
            except db_models.KeyViolation:
                save_result['updated'] = False
                save_result['error_type'] = 'kyc'
                save_result['msg'] = f'An account with the ID No. {user_nat_id} already exists.\n\n Please contact us' \
                                     f' through the help menu on the app home page if you think this is a mistake.'

        return save_result


class LoProposal(BaseSchema):
    __schema_cls__ = db_models.LoProposal

    # the borrower
    user: object | None = None

    amount: int
    purpose: str
    tags: list[str]
    term: int
    repayment_plan: str
    destination: dict   # where to send the loan money (payment method e.g bank or mobile money account)

    h: int | None = 1000  # default value of score
    proposed_on: int | None = None

    def set_proposer(self, proposers_id: int):
        # we're only setting the User so that we can provide a foreign key
        # reference to the User table and be able to fetch user details.
        # !!! The user has to be a solid User object, not just User instance with
        # only the id provided.

        # The user has no significance at all apart from the scenario where we need to fetch user details.
        # In other scenarios it will just be an integer which is the user's id
        self.user = db_models.User.objects.get(id=proposers_id)

    def save(self, **kwargs):
        # todo prevent user from making a proposal if there is an existing proposal that is not closed. there is already
        # get keeping to prevent user from ever having to make this action, but let's do double-gate-keeping.
        # on second thought, i might not do this. former is sufficient enough.

        # save the proposal (new record)
        saved: db_models.LoProposal = super().save(except_fields={'proposed_on', 'h'})
        self.proposed_on = saved.proposed_on  # this was an auto-saved field, so get the value from the saved record

        # saved the proposal, now we have to cache to redis
        self.cache()

        # now add user to algorithm loop
        push_to_algo(self)

    def cache(self):
        cache_dat = self.detailed_borrower_info()
        cache.cache_map(key=self.user if isinstance(self.user, int) else self.user.id, value=cache_dat)

    def detailed_borrower_info(self) -> dict:
        """
        This method loads detailed information about a LoProposal, including details of the borrower such
        as their name and occupation

        :return: the detailed data
        """

        # get the user. if the user has already been loaded from the db, don't make a trip to the db again
        # if not, it means self.user is an int which is the user's id. now use that id to fetch User object from db
        user = self.user if isinstance(self.user, db_models.User) else db_models.User.objects.get(id=self.user)

        # get the user's profile through user.userinsights so that we can access other info like occupation
        user_insights = user.userinsights

        # get the user's credit/debit history
        # todo load this into cache too. no actually, user will get this when they click on the respective list item

        user_profile = {
            # this is the reason we had to load the full solid user object from the db...
            # ...cause we needed info like their name
            'user_name': user.full_name,
            'country': user.country,
            'since': user.registered_on,
            'info': {
                'occupation': user_insights.occupation,
                'other_jobs': user_insights.other_jobs
            }
        }

        to_cache: dict = self.to_map()
        to_cache['user_profile'] = json.dumps(user_profile)

        return to_cache

    def detangled_detailed_borrower_info(self) -> dict:
        detail = self.detailed_borrower_info()

        detail['user_profile'] = json.loads(detail['user_profile'])
        detail['tags'] = json.loads(detail['tags'])
        detail['destination'] = json.loads(detail['destination'])

        return detail

    def to_map(self) -> dict:
        """
        :return: map that will be put in cache
        """
        to_dict = self.model_dump(exclude={'user', 'tags', 'destination'})

        # if it's a user object, get id through user.id
        # else, the user id is already an int.
        # we want to add the user's id to dict, not the user object
        to_dict['user'] = self.user if isinstance(self.user, int) else self.user.id

        # we're only converting these to strings cause of redis, but when returning data to the user
        # it will be decoded to back json array
        to_dict['tags'] = json.dumps(self.tags)
        to_dict['destination'] = json.dumps(self.destination)

        return to_dict

    @staticmethod
    def get_latest_of_borrower(borrower_id: int, closed: bool = False) -> db_models.LoProposal | None:
        """
        get the latest LoProposal of the borrower from the db. we're only interested in one LoProposal, not multiple
        if closed is False, get latest pending application, cause a user can't have multiple pending
        loan applications at the same time in prod. And, user has to finish repaying loan before getting another one.
        :param closed: whether to get the latest closed or unclosed LoProposal
        :param borrower_id: the db_models.User id of the borrower
        :return: the latest loan application of the borrower given the params
        """

        latest_proposal = db_models.LoProposal.objects \
            .filter(user=db_models.User(id=borrower_id), case_closed=closed) \
            .order_by('-proposed_on') \
            .first()

        return latest_proposal

    @staticmethod
    def feed(history: list[int]) -> list:
        return get_feed(history=history)

    @staticmethod
    def from_db() -> list:
        from_db = db_models.LoProposal.objects.filter(case_closed=False)

        proposals = [LoProposal(**proposal_in_db.to_map()) for proposal_in_db in from_db]

        return proposals

    def __str__(self):
        return str(self.to_map())


class Bid(BaseSchema):
    __schema_cls__ = db_models.Bid

    auctioneer: object
    bidder: object
    proposal: object  # id of the LoProposal in the db
    source: dict | None = None  # source of funds

    # the LoProposal.
    # when saving the record for the first time, we only need 'bid' which is the id of the LoProposal in the db.
    # when fetching the records, we'll need the schemas.LoProposal that each Bid record refers to, cause it carries
    # important detail about the loan application. we don't want to make double http requests and db trips to fetch the
    # Bid and LoProposal individually, we just package them at a go.
    bid_detail: LoProposal | dict | None = None

    bidder_info: dict | None = None     # user profile info of the bidder (the lender)

    bid_status: int | None = None
    bid_time: int | None = None
    close_time: int | None = None

    def make_bid(self):
        self.save()

    def save(self, **kwargs):
        self.proposal: db_models.LoProposal = db_models.LoProposal(id=self.proposal)

        # check if user (lender) has already accepted this proposal
        proposal_already_accepted = self.proposal.proposal_already_accepted(lender=self.bidder)

        if not proposal_already_accepted:
            # only accept proposal if it hasn't been accepted already. you don't want a duplicate situation where a
            # lender accepts a proposal more than once.

            self.auctioneer = db_models.User(id=self.auctioneer)
            self.bidder = db_models.User(id=self.bidder)

            super().save(only_fields={'auctioneer', 'bidder', 'proposal'})

    def made(self) -> bool:
        return self.id is not None
        # return True # todo beta

    @staticmethod
    def get_bidder_bids(bidder: int, bid_status: int) -> list:
        # this is only for the bidder. the auctioneer (borrower) will use another method to get people who have
        # made bids to their proposals

        # todo proposals stay in the proposal loop unless they're 'endorsed'. after being endorsed they are removed from
        # the loop and the redis cache

        bidder = db_models.User(id=bidder)
        bids = db_models.Bid.objects.filter(bidder=bidder, bid_status=bid_status) \
            if bid_status != 0 \
            else db_models.Bid.objects.filter(bidder=bidder, bid_status__in={0, 1}, close_time__isnull=True)

        # setting close_time=None filters out transactions that were already completed, or cancelled by either party.
        # we only want to get pending transactions that haven't been confirmed by the borrower yet, or confirmed by
        # the borrower but waiting for further action (sending money or cancellation) from the lender.

        # we're ordering by bid_status in descending order so that we get confirmed bids (status 1) at the top of the
        # list so that the user can see those first. otherwise, the user could have accepted multiple requests but the
        # only accepted one is at the end of the list. if it bubbles up to the top of the list, it is easier to notice,
        # even if there's multiple confirmed bids.
        bids_arr = [Bid(**bid.to_map()) for bid in bids.order_by('-bid_status')]

        for bid in bids_arr:
            # noinspection DuplicatedCode
            cache_dat = bid.bid_detail.detangled_detailed_borrower_info()

            bid.bid_detail = cache_dat

        return bids_arr

    @staticmethod
    def get_auctioneer_bids(auctioneer: int) -> dict | None:
        latest_proposal = LoProposal.get_latest_of_borrower(auctioneer)

        if latest_proposal is not None:
            pending_bids = latest_proposal.bid_set.all()
            bids_arr = [Bid(**bid.to_map(include_bid_detail=False)) for bid in pending_bids]

            return {
                "application": latest_proposal.to_map(),
                "bids": bids_arr
            }
        else:
            return None

    @staticmethod
    def confirm(bid_id: int, proposal_id: int) -> bool:
        """
        A borrower wants to confirm a lend request that a lender accepted, i.e a lender has showed interest in lending
        to a borrower and the borrower is confirming that, so that the loan transaction can begin. This is called
        'confirming a bid'.
        What you don't want is for the borrower to confirm more than one bid from multiple lenders (or the same lender
        for that matter - this is taken care of in schemas.Bid.make_bid)

        :param bid_id: db id of the bid
        :param proposal_id: db id of the proposal
        :return: true if this function resulted in bid confirmation, false if bid had already been confirmed earlier
        """

        proposal = db_models.LoProposal(id=proposal_id)

        if not proposal.borrower_has_confirmed_any_bids():
            # calling borrower_has_confirmed_any_bids() loops through the bids of the LoProposal.
            # if any of the bids have already been confirmed, it breaks the loop and returns True.
            # if the loop finishes without returning immaturely, that is, when none of the bids have already been
            # confirmed (none have status 1), return False, meaning we are good to go (confirm this Bid in the db).
            # i.e, we only set a bid to status 1 if none of the bids of the parent LoProposal have been confirmed
            # already.
            # confirming a bid can only be done by the borrower, and we don't want the borrower to confirm > one bid

            bid = db_models.Bid(id=bid_id)
            bid.bid_status = 1
            bid.save(update_fields={'bid_status'})

            return True
        else:
            return False

    @staticmethod
    def initiate_transaction(bid_id: int) -> bool:
        try:
            pending = db_models.PendingTransaction(
                bid=db_models.Bid(id=bid_id)
            )
            pending.save()

            return True
        except:
            # print(e)
            return False


class PendingTransaction(BaseSchema):
    __schema_cls__ = db_models.PendingTransaction

    @staticmethod
    def get_user_pending_send_transaction(user_id: int) -> Bid | None:
        # get the latest unclosed pending transaction where the user is the lender
        pending_send = db_models.PendingTransaction.objects\
            .filter(bid__bidder_id=user_id, bid__bid_status=1, bid__close_time__isnull=True,
                    bidder_conf=False, close_time__isnull=True)\
            .order_by('-initiation_time')\
            .first()

        if pending_send is not None:
            bid = Bid(**pending_send.bid.to_map())

            # noinspection DuplicatedCode
            borrower_info = bid.bid_detail.detangled_detailed_borrower_info()

            bid.bid_detail = borrower_info
            bid.close_time = pending_send.initiation_time  # only temporary, doesn't affect db state. just put to give
            # the lender information about what time they initiated the transaction by accepting terms.

            return bid

        return None

    @staticmethod
    def get_user_pending_receipt_transaction(user_id: int) -> Bid | None:
        # get the latest transaction that the user has received but hasn't confirmed receipt

        # constraints - bid_status must be 1, meaning the lender didn't cancel, and the lender must have completed the
        # transaction (bidder_conf is True) and the borrower hasn't confirmed receipt (auctioneer_conf = False)
        pending_receipt = db_models.PendingTransaction.objects \
            .filter(bid__auctioneer_id=user_id, bid__bid_status=1, bid__close_time__isnull=True,
                    bidder_conf=True, auctioneer_conf=False, close_time__isnull=True) \
            .order_by('-initiation_time') \
            .first()

        if pending_receipt is not None:
            bid = Bid(**pending_receipt.bid.to_map())
            bid.close_time = pending_receipt.bidder_conf_time   # setting this close_time is just temporary. it doesn't
            # affect db state. (it's just to give the user the time when the lender sent the money).
            # if bidder_conf is True, then bidder_conf_time is not
            # null. hence, add this to the bid so that the borrower can see the time when the lender sent the money.
            # at this time, models.Bid is not yet closed, so we can't use models.Bid close_time because it's still None
            # at this point. if auctioneer_conf in PendingTransaction is False, then models.Bid.close_time is definitely
            # null, because close_time is only set once lender confirms and borrower confirms too. if either of them
            # cancel, close_time is also set (and both confs in PendingTransaction are set to True).
            # if bidder_conf is True, then models.Bid.source is also not null, and so schemas.Bid.source will not
            # be null either.

            return bid

        return None

    @staticmethod
    def user_expecting_receipt(user_id: int) -> bool:
        latest_unclosed_proposal = LoProposal.get_latest_of_borrower(user_id)

        if latest_unclosed_proposal is not None:
            # if borrower has confirmed any bids, they are now expecting to receive money from the lender at any time.
            # if not, their loan application is still pending approval by lenders, or they haven't confirmed any bid
            # from any lender yet. a borrower can only confirm one bid for one loan application at any one time.
            return latest_unclosed_proposal.borrower_has_confirmed_any_bids()
        else:
            # the borrower doesn't have any pending loan applications. they can't be expecting receipt of money.
            return False

    @staticmethod
    def confirm_complete(bid: Bid, source: dict):
        # todo use information (bidder_info etc) in bid (schemas.Bid) to send notification of money sent to borrower
        db_bid = db_models.Bid(id=bid.id)

        # there is a one-to-one relationship between PendingTransaction and Bid, so we can fetch a PendingTransaction
        # by the bid/bid id, and it would still work the same as if we fetched using the PendingTransaction's id
        pending_transaction = db_models.PendingTransaction.objects.get(bid=db_bid)

        # update completion status of lender
        pending_transaction.bidder_conf = True
        pending_transaction.bidder_conf_time = db_models.current_time_millis()

        # update source of funds in db_models.Bid
        db_bid.source = source

        db_bid.save(update_fields={'source'})
        pending_transaction.save(update_fields={'bidder_conf', 'bidder_conf_time'})

        return bid.id

    @staticmethod
    def confirm_receipt(bid: Bid):
        db_bid = db_models.Bid(id=bid.id)
        pending_transaction = db_models.PendingTransaction.objects.get(bid=db_bid)
        proposal = db_models.LoProposal.objects.get(id=bid.proposal)  # todo notify lender using borrower info
        close_time = db_models.current_time_millis()

        # update completion status of borrower
        pending_transaction.auctioneer_conf = True
        pending_transaction.auctioneer_conf_time = close_time
        pending_transaction.close_time = close_time

        db_bid.close_time = close_time

        proposal.closer = db_models.User(id=bid.bidder)  # the closer is the lender
        proposal.close_time = close_time
        proposal.case_closed = True

        pending_transaction.save(update_fields={'auctioneer_conf', 'auctioneer_conf_time', 'close_time'})
        db_bid.save(update_fields={'close_time'})
        proposal.save(update_fields={'closer', 'close_time', 'case_closed'})

        weekly_instalment = Calculator.get_weekly_instalments(proposal.amount)[f"{proposal.term}"]
        total_payback = weekly_instalment * (proposal.term * 4)  # weekly instalment * months * 4
        weekly_rate = Calculator.base_weekly_percent_interest_rate()

        new_qualified_loan = db_models.Lo(
            proposal=proposal,
            bid=db_bid,
            payback=total_payback,
            wk_instalment=weekly_instalment,
            wk_rate=weekly_rate
        )

        new_qualified_loan.save()

        # todo close pending transaction and bid and proposal. add to Lo
        # todo remove proposal from cache and redis

        return new_qualified_loan.id    # id of the new schemas.Lo record


class Instalment(BaseSchema):
    __schema_cls__ = db_models.Instalment

    amount: int
    source: dict
    instalment_time: int
    confirmed: bool

    @staticmethod
    def confirm(instalment_id: int):
        instalment = db_models.Instalment(id=instalment_id)
        instalment.confirmed = True

        instalment.save(update_fields={'confirmed'})

        return instalment_id


class Lo(BaseSchema):
    __schema_cls__ = db_models.Lo

    proposal: LoProposal | dict
    bid: Bid
    payback: int
    wk_instalment: int
    wk_rate: float
    initiated_on: int
    settled: bool
    finished_on: int | None = None
    instalments: list[Instalment] | None = None
    next_instalment: int | None = None
    fraction_complete: float | None = None
    percent_complete: float | None = None

    curr_time: int | None = None

    @staticmethod
    def get_user_current_loan(user_id: int):
        # get the user's current loan by checking the latest loan where they are the borrower
        lo = db_models.Lo.objects.filter(proposal__user_id=user_id, settled=False).order_by('-initiated_on').first()

        if lo is None:
            return None
        else:
            # we're not gonna fetch detailed borrower info because the borrower already has this info in their frontend.
            # fetching it would be redundant. this method can only be invoked by the borrower any way, not the lender.

            lo = Lo(**lo.to_map())
            lo.fill_in_params()

            return lo

    @staticmethod
    def get_user_current_lend_outs(user_id: int):
        # get unsettled lend outs (loans that the user has lent whose payments haven't been completed by borrowers)
        los = db_models.Lo.objects.filter(proposal__closer_id=user_id, settled=False).order_by('-initiated_on')

        lend_outs = []

        for lend_out in los:
            lend_out = Lo(**lend_out.to_map())

            lend_out.proposal = lend_out.proposal.detangled_detailed_borrower_info()
            lend_out.fill_in_params()

            lend_outs.append(lend_out)

        return lend_outs

    @staticmethod
    def is_user_owed(user_id: int) -> bool:
        return len(Lo.get_user_current_lend_outs(user_id)) > 0

    def get_fraction_of_payment_complete(self) -> float:
        if len(self.instalments) == 0:
            return 0.0

        fraction_complete = round(self.get_total_paid() / self.payback, 4)
        return float(1 if fraction_complete > 1 else fraction_complete)

    def fill_in_params(self):
        self.curr_time = db_models.current_time_millis()
        self.next_instalment = self.get_next_instalment()

        self.fraction_complete = self.get_fraction_of_payment_complete()
        self.percent_complete = round(self.fraction_complete * 100, 2)

    def get_total_paid(self) -> int:
        total = 0
        for instalment in self.instalments:
            total += instalment.amount

        return total

    def get_total_debt(self) -> int:
        debt = self.payback - self.get_total_paid()

        return 0 if debt < 0 else debt

    def get_next_instalment(self) -> int:
        millis_in_a_week = 86_400_000 * 7

        # basically number of full weeks passed since initiation
        num_expected_complete_instalments = (self.curr_time - self.initiated_on) // millis_in_a_week

        expected_paid_by_now = num_expected_complete_instalments * self.wk_instalment
        total_paid_by_now = self.get_total_paid()
        total_debt = self.get_total_debt()

        debt_until_now = 0 if total_paid_by_now > expected_paid_by_now else (expected_paid_by_now - total_paid_by_now)

        to_pay = debt_until_now + self.wk_instalment

        print(f"expected complete instalments {num_expected_complete_instalments}")
        print(f"expected paid by now {expected_paid_by_now}")
        print(f"total paid by now {total_paid_by_now}")
        print(f"total debt {total_debt}")
        print(f"debt until now {debt_until_now}")
        print(f"amount to pay {to_pay}")

        return to_pay if total_debt > to_pay else total_debt

    @staticmethod
    def repay_instalment(lo_id: int, amount: int, source: dict) -> int:
        instalment = db_models.Instalment(
            lo=db_models.Lo(id=lo_id),
            amount=amount,
            source=source
        )
        instalment.save()
        return instalment.id
