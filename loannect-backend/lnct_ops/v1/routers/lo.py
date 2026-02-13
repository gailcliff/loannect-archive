from fastapi import APIRouter, Body, Depends
from typing import Annotated
import math

from ..schemas import LoProposal, User, LoEligibility, Calculator
from ..cache import proposal_loop


router = APIRouter(
    prefix='/lo',
    tags=['lo'],
    dependencies=[Depends(proposal_loop.preload_proposal_loop)]
)


# @router.on_event('startup')
# def preload():
#     from asgiref.sync import sync_to_async
#     sync_to_async(proposal_loop.preload_proposal_loop)


lo_tags = sorted([
    "Rent",
    "Bills",
    "Clothes",
    "Education",
    "Medical",
    "Home Repairs",
    "Car Repairs",
    "Business",
    "Travel",
    "Wedding",
    "Vacation",
    "Debt Consolidation",
    "Moving Expenses",
    "Groceries",
    "Utilities",
    "Emergencies",
    "Entertainment",
    "Childcare",
    "Furniture",
    "Electronics",
    "Gifts",
    "Pet Expenses",
    "Tuition Fees",
    "Hobbies",
    "Relocation",
    "Home Improvement",
    "Special Occasions",
    "Vehicle Purchase",
    "Down Payment",
    "Taxes",
    "Legal Fees",
    "Insurance",
    "Equipment",
    "Software",
    "Start-up Costs",
    "Advertising",
    "Marketing",
    "Inventory",
    "Office Supplies",
    "Professional Services",
    "Training",
    "Consulting",
    "Equipment Rental",
    "Event Planning",
    "Publications",
    "Research",
    "Charity",
    "Community Projects",
    "Art Supplies",
    "Concert Tickets",
    "Gym Membership",
    "Sports Equipment",
    "Dance Classes",
    "Books",
    "Music",
    "Restaurant Expenses",
    "Beauty Products",
    "Home Decor",
    "Gardening",
    "Party Supplies",
    "Baby Expenses",
    "Photography",
    "Jewelry",
    "Gambling",
    "Home Appliances",
    "Electronics Repair",
    "Dating Expenses",
    "Mobile Apps",
    "Subscriptions",
    "Fitness Programs",
    "Cosmetic Surgery",
    "Fashion",
    "Collectibles",
    "Social Events",
    "Retirement Savings",
    "Repayment of Previous Loan",
    "Student Loans",
    "Online Courses",
    "Child Education",
    "Artwork",
    "Real Estate",
    "Rental Property",
    "Student Housing",
    "Scholarships",
    "Property Taxes",
    "Home Insurance",
    "Car Insurance",
    "Pet Insurance",
    "Health Insurance",
    "Life Insurance",
    "Credit Card Debt",
    "Emergency Fund",
    "Investment",
    "Savings",
    "Retirement",
    "Wedding Expenses",
    "Home Purchase",
    "Electronics Purchase",
    "Vehicle Maintenance",
    "Home Maintenance",
    "Home Upgrades",
    "Home Renovation",
    "Dental Expenses",
    "Veterinary Expenses",
    "Conferences",
    "Business Expansion",
    "Product Development",
    "Childbirth Expenses",
    "Medical Bills",
    "Student Expenses",
    "Computer Equipment",
    "Phone Bill",
    "Internet Bill",
    "Legal Expenses",
    "Tax Payments",
    "Child Support",
    "Alimony",
    "Investment Opportunities",
    "Home Security",
    "Home Cleaning Services",
    "Child Adoption",
    "Bank Fees",
    "Credit Score Improvement",
    "Legal Representation",
    "Business Travel",
    "Transportation Expenses",
    "Art Education",
    "Music Lessons",
    "Family Reunion",
    "Funeral Expenses",
    "Language Classes",
    "Volunteer Work",
    "Retirement Travel",
    "Job Relocation",
    "Health and Wellness",
    "Home Energy Efficiency",
    "Kitchen Appliances",
    "Home Theater System",
    "Home Gym Equipment",
    "Green Energy Solutions",
    "Vacation Rental",
    "Camping Equipment",
    "Boat Repairs",
    "Motorcycle Repairs",
    "Emergency Home Repairs",
    "Emergency Car Repairs",
    "Emergency Medical Expenses",
    "Emergency Travel Expenses"
])


@router.get('/pre-requisites/{user_id}')
def get_pre_requisites(
    user_id: int,
    get_tags: bool,
    instalments: Annotated[dict, Depends(Calculator.get_weekly_instalments)]
):
    # in the future, user_id will be used to get preferential interest rates for
    # the specific user

    verified = User.is_stamped(user_id)
    eligibility = User.get_lo_eligibility(user_id)

    pre_requisites = {
        "verified": verified,
        "eligible": eligibility is LoEligibility.OK
    }

    if verified:
        match eligibility:
            case LoEligibility.PENDING_APPROVAL:
                pre_requisites['info'] = "Sorry, you currently have another pending loan application. Please wait to " \
                    "get a lender for your current loan application or cancel it first before applying for another one."
            case LoEligibility.HAS_DEBT:
                pre_requisites['info'] = "Sorry, you currently have an outstanding debt. Please settle your current " \
                    "debt first before applying for another loan."
            case LoEligibility.PLEASE_WAIT:
                pre_requisites['info'] = "Please wait at least 2 (two) days from your most recent loan application " \
                     "before applying for another loan."
            case LoEligibility.OK:
                # if user isn't verified or eligible, there's no need to return the rate and tags
                pre_requisites['base_rate'] = Calculator.base_daily_percent_interest_rate()
                pre_requisites['instalments'] = instalments

                if get_tags:
                    # only load tags if the user doesn't have a temporary copy
                    pre_requisites['lo_tags'] = lo_tags

    return pre_requisites


@router.post('/propose/{user_id}')
def propose_lo(
    user_id: int,
    proposal: LoProposal
):
    proposal.set_proposer(user_id)

    proposal.save()

    return proposal.id


# we're really just using post to be able to include the body. but this should actually be a get request
@router.post('/proposals')
def discover_proposals(history: list[int]) -> list:
    return LoProposal.feed(history)


# should've been a get request too
@router.post('/analytics')
def get_proposer_analytics(proposal: LoProposal):
    # todo get debt and lend history
    # get interest rate and instalments

    # term: int = loan_info['term']   # term is no. of months
    # amount: int = loan_info['amount']

    print("Getting analytics for lo proposal:", proposal)

    proposer_id = proposal.user if isinstance(proposal.user, int) else proposal.user.id
    term = proposal.term
    amount = proposal.amount

    instalments = Calculator.get_weekly_instalments(amount)
    num_instalments = term * 4

    # e.g if term is 2 months, get the weekly instalments for the specific term
    weekly_instalment_for_term = instalments[f"{term}"]

    # then multiply the weekly instalments by no. of weeks to get total payout.
    # we could call get_total_payout_based_on_months() but the result could be a deviation from the one calculated
    # through adding the instalments, due to math.ceil
    total_payout = weekly_instalment_for_term * num_instalments
    interest = total_payout - amount

    return {
        "amount": amount,
        "base_rate": Calculator.base_daily_percent_interest_rate(),
        "base_weekly_rate": Calculator.base_weekly_percent_interest_rate(),
        "weekly_instalment": weekly_instalment_for_term,
        "num_instalments": num_instalments,
        "total_payout": total_payout,
        "interest": interest
    }


@router.get('/terms')
async def get_terms_and_conditions(amount: int, base_rate: float, num_instalments: int, weekly_instalment: int,
                                   total_payout: int):

    return f"""Terms and Conditions

1. By accepting this loan of KSH {amount}, you agree to repay the loan fully in {num_instalments} instalments (one instalment every week for {num_instalments} weeks).

2. Repayment Schedule: KSH {weekly_instalment} due every week (7 days) from the time when the loan is received.

3. Interest rate: {base_rate}% daily (loan to be repaid weekly, not daily).

4. Total loan repayment: KSH {total_payout}

5. Late Payment: A late fee of 3% of your outstanding balance per week will be charged for late payments.

6. Default: Failure to repay within the stated schedule will be considered a default.

7. Consequences of Default: Credit reporting, collections and legal action may be pursued to recover outstanding amounts.

8. Representations: You warrant that the information you provided while applying for the loan is accurate, and the loan is for the disclosed purpose.


By accepting this loan, you confirm understanding and agreeing to the above terms.
"""
