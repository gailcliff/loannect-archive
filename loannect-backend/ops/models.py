from django.db import models, IntegrityError
import time

DbModel = models.Model
KeyViolation = IntegrityError
Q = models.Q


gender_choices = (
    ('M', 'Male'),
    ('F', 'Female'),
    ('O', 'Other'),
)
bid_status_choices = (
    (1, 'Confirmed'),   # means borrower has confirmed the request (after lender has accepted)
    (0, 'Pending'),     # means borrower hasn't yet confirmed, but lender has accepted
    (-1, 'Cancelled')   # means either the borrower has deleted their request or the lender has cancelled the request
)


def current_time_millis():
    time_millis = int(time.time() * 1000)
    return time_millis


class User(DbModel):
    full_name = models.TextField()
    country = models.CharField(max_length=5, db_comment='Letter code of country')
    phone = models.CharField(max_length=26)
    dob = models.DateField()
    gender = models.CharField(max_length=2, choices=gender_choices)
    email = models.EmailField(null=True)
    registered_on = models.BigIntegerField(default=current_time_millis)


class UserInsights(DbModel):
    user = models.OneToOneField(User, on_delete=models.PROTECT)

    nat_id = models.CharField(max_length=26, unique=True, editable=False)
    address = models.TextField()
    occupation = models.JSONField()
    other_jobs = models.TextField()
    income = models.JSONField()
    last_saved = models.BigIntegerField(default=current_time_millis)


class LoProposal(DbModel):
    user = models.ForeignKey(User, on_delete=models.PROTECT)    # the borrower who made the loan application.

    amount = models.IntegerField()
    purpose = models.TextField()
    tags = models.JSONField()
    term = models.SmallIntegerField()   # term in months
    repayment_plan = models.TextField()
    destination = models.JSONField()

    score = models.IntegerField(name='h', default=1000)  # each person starts with an arbitrary score of 1000
    proposed_on = models.BigIntegerField(default=current_time_millis)

    case_closed = models.BooleanField(default=False)   # will be set to true after user's request is accepted by lender
    # and the borrower confirms, or if the borrower decides to delete their lend request

    closer = models.ForeignKey(   # the lender who made the transaction. will be null if borrower deleted the request
        User,
        on_delete=models.PROTECT,
        related_name='closer',
        null=True
    )
    close_time = models.BigIntegerField(db_comment='time when case was closed', null=True)

    def to_map(self) -> dict:

        return {    # this is the schema of a schemas.LoProposal object
            "id": self.id,
            "user": self.user_id,   # user id, an integer
            "amount": self.amount,
            "purpose": self.purpose,
            "tags": self.tags,
            "term": self.term,
            "repayment_plan": self.repayment_plan,
            "destination": self.destination,
            "h": self.h,    # todo when a cue is received, update the score in the db to sync it with memory value
            "proposed_on": self.proposed_on
        }

    def proposal_already_accepted(self, lender) -> bool:
        bids_made_by_lender = self.bid_set.filter(bidder_id=lender)
        # todo a lender may cancel a proposal, and then try to accept it again. well, their previous bid is still in db.
        # what happens in such a scenario? should they be able to accept the lend request again?
        # if yes, todo only do due diligence with bids that haven't been cancelled (-1)
        # so above line would instead be:
        #   bids_made_by_lender = self.bid_set.filter(bidder_id=lender, bid_status__in={0, 1})
        # but you know, i don't think a lender should be allowed to accept a proposal request that they had earlier
        # accepted and then ended up cancelling. we don't want them to run circles around the borrower.
        return bids_made_by_lender.count() > 0

    def borrower_has_confirmed_any_bids(self) -> bool:
        # loop through the bids of the LoProposal. if any of the bids have already been confirmed by the borrower,
        # return True else False.
        # confirming a bid can only be done by the borrower, and we want to check if the borrower has confirmed any bids
        # from lenders.
        for bid in self.bid_set.all():
            if bid.bid_status == 1:
                return True

        return False


class Bid(DbModel):
    auctioneer = models.ForeignKey(User, on_delete=models.PROTECT, related_name='auctioneer', db_comment='the borrower')
    bidder = models.ForeignKey(User, on_delete=models.PROTECT, related_name='bidder', db_comment='the lender bidding')
    source = models.JSONField(null=True)    # source of funds if bidder decides to lend. set once lender confirms send
    proposal = models.ForeignKey(LoProposal, on_delete=models.PROTECT, db_comment='the bid application')

    bid_status = models.SmallIntegerField(choices=bid_status_choices, default=0)
    bid_time = models.BigIntegerField(default=current_time_millis)

    # todo only set once transaction has been completed (borrower and lender have both confirmed) or been cancelled.
    # cancelled meaning borrower deleted application or lender cancelled lend request.
    # if cancelled, bid_status will be -1
    close_time = models.BigIntegerField(db_comment='time when bid was closed', null=True)

    def to_map(self, include_bid_detail: bool = True) -> dict:

        to_map = {
            "id": self.id,
            "auctioneer": self.auctioneer_id,
            "bidder": self.bidder_id,
            "bidder_info": {
                "user_name": self.bidder.full_name,
                "country": self.bidder.country
            },
            "proposal": self.proposal_id,

            "bid_status": self.bid_status,
            "bid_time": self.bid_time,
            "close_time": self.close_time
        }

        if include_bid_detail:
            to_map["bid_detail"] = self.proposal.to_map()

        if self.source is not None:
            to_map['source'] = self.source

        return to_map


class PendingTransaction(DbModel):
    bid = models.OneToOneField(Bid, on_delete=models.PROTECT)
    initiation_time = models.BigIntegerField(default=current_time_millis)

    bidder_conf = models.BooleanField(default=False)    # whether lender has confirmed
    bidder_conf_time = models.BigIntegerField(null=True)    # time when lender confirmed
    auctioneer_conf = models.BooleanField(default=False)    # whether borrower has confirmed
    auctioneer_conf_time = models.BigIntegerField(null=True)    # time when borrower confirmed

    close_time = models.BigIntegerField(null=True)  # set time only if lender cancels or transaction is completed
    # (lender confirms completion and borrower finally confirms receipt of funds).
    # as long as a new PendingTransaction is added to db, lender won't be able to add anymore as long as they haven't
    # cancelled or complete the previous PendingTransaction. at any one time a specific lender and a specific borrower
    # can only have one PendingTransaction where close_time is null


class Lo(DbModel):
    """Once a loan request has been endorsed. this table will store the loan and
    the status update of whether it has been paid in full.
    A new entry of this table is only created when a loan request has been endorsed.

    Has a child table called: instalments
    """
    proposal = models.OneToOneField(LoProposal, on_delete=models.PROTECT)
    bid = models.OneToOneField(Bid, on_delete=models.PROTECT)
    payback = models.IntegerField()  # total repayment. interest is payback - proposal.amount
    wk_instalment = models.IntegerField()   # weekly instalment. num instalments is proposal.term * 4
    wk_rate = models.DecimalField(max_digits=5, decimal_places=2)  # weekly interest rate (not as %age, value e.g 2.8)

    initiated_on = models.BigIntegerField(default=current_time_millis)
    settled = models.BooleanField(default=False)
    finished_on = models.BigIntegerField(null=True)

    def to_map(self) -> dict:
        to_map = vars(self)
        to_map['proposal'] = self.proposal.to_map()
        to_map['bid'] = self.bid.to_map(include_bid_detail=False)
        to_map['instalments'] = self.get_instalments()

        return to_map

    def get_instalments(self) -> list:
        return [
            {
                'id': instalment.id,
                'amount': instalment.amount,
                'source': instalment.source,
                'instalment_time': instalment.instalment_time,
                'confirmed': instalment.confirmed,
            } for instalment in self.instalment_set.all()
        ]


class Instalment(DbModel):
    """
    As a borrower pays back a loan, each instalment adds a new record to this table. Each instalment is related
    to a schemas.Lo qualified loan. To check if the user has completed payment, just aggregate their loans and if they
    add up to >= the lo.payback, they have completed payment.
    """
    lo = models.ForeignKey(Lo, on_delete=models.PROTECT)
    amount = models.IntegerField()  # amount of the instalment
    source = models.JSONField()    # source of instalment (payment info borrower used to pay the instalment)
    instalment_time = models.BigIntegerField(default=current_time_millis)
    confirmed = models.BooleanField(default=False)  # whether lender has confirmed receipt or not
    # maybe include percent_complete in future to prevent having to aggregate rows
    # percent_complete = models.DecimalField(max_digits=5, decimal_places=2)
