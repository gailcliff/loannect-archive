from .. import cache
import json

# todo replace python list with numpy array


class TempProposal:
    id: int
    proposer_id: int
    score: int

    def __init__(self, proposal):   # this is a schemas.LoProposal object
        self.id = proposal.id   # the id of the proposal
        # the id of the borrower
        self.proposer_id = proposal.user if isinstance(proposal.user, int) else proposal.user.id
        self.score = proposal.h

    def __eq__(self, other):
        if isinstance(other, TempProposal):
            return self.id == other.id
        return False

    def __ne__(self, other):
        return not self.__eq__(other)

    def __str__(self):
        return f"TempProposal(id={self.id}, proposer_id={self.proposer_id}, score={self.score})"


temp_proposals: list[TempProposal] = []


class ProposalIterator:
    curr_idx: int

    def __init__(self):
        self.curr_idx = 0

    def mov(self):
        if self.curr_idx == len(temp_proposals) - 1:
            self.curr_idx = 0
        else:
            self.curr_idx += 1

    def __iter__(self):
        return self

    def __next__(self):
        next_proposal: TempProposal | None
        try:
            next_proposal = temp_proposals[self.curr_idx]
        except:
            # anticipating an exception that could occur when list state changes when it's being accessed
            next_proposal = None

        return next_proposal

    def next_chunk(self, sz: int, history: list[int]):
        chunk = []

        temp_proposals_len = len(temp_proposals)

        if temp_proposals_len > 0:
            # only return results if proposals is not an empty list
            for _ in range(temp_proposals_len if sz > temp_proposals_len else sz):
                temp_proposal = next(self)

                if temp_proposal is not None:
                    # only add items to the result if they haven't already been viewed
                    if temp_proposal.id not in history:
                        print("adding proposal id not in history:", temp_proposal.id)

                        # only add if item is not in history
                        chunk.append(temp_proposal)

                        # just add the id to the history just in case to prevent duplicating
                        # the data in the result if there's duplicates in the list.
                        # ideally we won't have a situation where there's duplicates of the same proposal (proposer id)
                        # in this temp proposals list, cause each proposal is unique. and, side-note, there can't be two
                        # proposals from the same user in this list at the same time (**not relevant to this situation).
                        history.append(temp_proposal.id)
                    else:
                        # print(f"temp id {temp_proposal.id } in history {history}")
                        pass

                # shift index
                self.mov()

        if len(chunk) == 0:
            print("oops! popped empty chunk :(")

        return chunk


__proposal_iterator__ = ProposalIterator()


# add a proposal to the loop
def push_to_algo(proposal):
    # proposal is a LoProposal object
    temp_proposals.append(TempProposal(proposal))


# remove a proposal from the loop
def delete_from_algo(proposal):
    # proposal is a LoProposal object
    temp_proposals.remove(proposal)


# load proposals from their copy in the database to add to memory
def preload_proposal_loop():
    global temp_proposals

    if len(temp_proposals) == 0:
        print("pre-loading proposal loop...")

        from ..schemas import LoProposal
        from . import cache_status_is_green_flag, green_flag_the_cache

        lo_proposals_from_db: list[LoProposal] = LoProposal.from_db()

        if not cache_status_is_green_flag():
            # the cache doesn't exist. this could be because it was deleted
            # due to the server being shutdown for example
            for lo_proposal in lo_proposals_from_db:
                print("caching:", lo_proposal, "to redis")
                lo_proposal.cache()

            # set the flag to status ok - cache is locked and loaded
            green_flag_the_cache()

        temp_proposals = list(map(lambda proposal: TempProposal(proposal), lo_proposals_from_db))


def get_feed(*, sz: int = 20, history: list[int]) -> list:
    """
    Get the next chunk of proposals from the loop
    :param sz: the size of the chunk. default is 20
    :param history: the list of proposals that the client has already viewed
    :return: the next chunk of proposals (the user is scrolling a list or sumn)
    """
    print(f"popping from algo...(current no. of items in algo {len(temp_proposals)})")

    from ..schemas import LoProposal

    chunk: list[TempProposal] = __proposal_iterator__.next_chunk(sz, history)

    def transform_temp_proposal(temp_proposal: TempProposal) -> dict:

        item_map = cache.get_map(temp_proposal.proposer_id)

        # what's in the cache is basically just serialized schemas.LoProposal objects
        lo_proposal = LoProposal(
            # id=int(item_map['id']),
            id=temp_proposal.id,     # todo alternative to above. either works perfect. no actually, this one's better.
            user=temp_proposal.proposer_id,  # the borrower's id. user=int(item_map['user']) also works
            amount=int(item_map['amount']),
            purpose=item_map['purpose'],
            tags=json.loads(item_map['tags']),
            term=int(item_map['term']),
            repayment_plan=item_map['repayment_plan'],
            destination=json.loads(item_map['destination']),
            proposed_on=int(item_map['proposed_on']),

            # score gets updated when proposer is cued. don't use score in redis cache because it's not the latest value
            h=temp_proposal.score   # this is the updated value. gets updated each time a cue is received
        )
        lo_proposal_dict = lo_proposal.model_dump()
        lo_proposal_dict['user_profile'] = json.loads(item_map['user_profile'])

        print("proposal map from cache:", lo_proposal_dict)

        return lo_proposal_dict

    # return []
    return list(map(lambda item: transform_temp_proposal(item), chunk))
