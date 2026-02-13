part of loannect_api;

class _ApiImpl implements Api {

  _ApiImpl._();

  static final _ApiImpl _apiImpl = _ApiImpl._();

  factory _ApiImpl() => _apiImpl;


  RetryClient? _httpClient;

  static const _allowableStatusCodes = <int>[
    200,
    // 404,
  ];

  bool statusIsNotAllowed(int statusCode) => !_allowableStatusCodes.contains(statusCode);


  @override
  Future<ApiResponse> registerUser(UserProfile user) async {
    return fetch(
        Api.POST,
        "/people",
        body: user.dict,
        transformer: (data) => int.parse(data)
    );
  }

  @override
  Future<ApiResponse> getLoPreRequisites(UserProfile user, int amount, {required bool getTags}) {
    return fetch(
      Api.GET,
      "/lo/pre-requisites/${user.id!}",
      params: {
        "amount": "$amount",
        "get_tags": "$getTags"
      },
      transformer: (data) {
        return LoPreRequisites.fromJson(encoding.jsonDecode(data) as Map<String, dynamic>);
      }
    );
  }

  @override
  Future<ApiResponse> proposeLo(int userId, LoProposal proposal) {
    return fetch(
      Api.POST,
      "/lo/propose/$userId",
      body: proposal.dict,
      transformer: (data) => int.parse(data)
    );
  }

  @override
  Future<ApiResponse> discoverProposals({required List<int> history}) {
    return fetch(
      Api.POST,
      "/lo/proposals",
      body: history,
      transformer: (data) {
        return (encoding.jsonDecode(data) as List).map((json) => LoProposal.fromJson(json)).toList(growable: false);
      }
    );
  }

  @override
  Future<ApiResponse> stampUser(UserProfile user, UserInsights userInsights) {
    return fetch(
      Api.PUT,
      "/people/stamp/${user.id!}",
      body: userInsights.dict,
      transformer: (data) => encoding.jsonDecode(data)
    );
  }

  @override
  Future<ApiResponse> getBorrowerAnalytics(LoProposal proposal) {
    return fetch(
      Api.POST,
      "/lo/analytics",
      body: proposal.dict,
      transformer: (data) => encoding.jsonDecode(data)
    );
  }

  @override
  Future<ApiResponse> acceptLendRequest(Bid bid) {
    return fetch(
      Api.POST,
      "/auction/bid",
      body: bid.dict,
      transformer: (data) => bool.parse(data)
    );
  }

  @override
  Future<ApiResponse> getUnsealedBids(UserProfile bidder) {
    return fetch(
      Api.GET,
      "/auction/bids/${bidder.id!}",
      transformer: (data) => (encoding.jsonDecode(data) as List).map((json) => Bid.fromJson(json)).toList(growable: false)
    );
  }

  @override
  Future<ApiResponse> getLendRequestUpdates(UserProfile borrower) {
    return fetch(
      Api.GET,
      "/auction/bids/auctioneer/${borrower.id!}",
      transformer: (data) => LoAppUpdate.fromJson(encoding.jsonDecode(data) as Map<String, dynamic>)
    );
  }

  @override
  Future<ApiResponse> confirmBid(Bid bid) {
    return fetch(
      Api.PUT,
      "/auction/bids/confirm/${bid.bidId!}",
      params: {
        "proposal": "${bid.proposal!.proposalId!}"
      },
      transformer: (data) => bool.parse(data)
    );
  }

  @override
  Future<ApiResponse> getLoTerms(Map repaymentInfo) {
    return fetch(
      Api.GET,
      "/lo/terms",
      params: repaymentInfo.map((key, value) => MapEntry(key.toString(), value.toString())),
      transformer: (data) => encoding.jsonDecode(data)
    );
  }

  @override
  Future<ApiResponse> getLeTerms(Map repaymentInfo) {
    return fetch(
      Api.GET,
      "/auction/terms",
      params: repaymentInfo.map((key, value) => MapEntry(key.toString(), value.toString())),
      transformer: (data) => encoding.jsonDecode(data)
    );
  }

  @override
  Future<ApiResponse> initiateTransaction(Bid bid) {
    return fetch(
      Api.POST,
      "/le/initiate/${bid.bidId!}",
      transformer: (data) => bool.parse(data)
    );
  }

  @override
  Future<ApiResponse> getPendingTransaction(UserProfile user, {required String type}) {
    // once a transaction has been initiated, both borrower and lender have to
    // confirm completion of transaction.
    // every time app resumes, check server for any pending transaction.
    // a transaction can either be 'send' or 'receipt'.
    // if there's any pending transaction, 'force' user to confirm (they can't access
    // other parts of the app). once they have confirmed, proceed to next step.

    return fetch(
      Api.GET,
      "/fin/pending/${user.id!}",
      params: {
        "transaction_type": type
      },
      transformer: (data) {
        if(data == null.toString()) {
          return false;
        }
        return Bid.fromJson(encoding.jsonDecode(data));
      }
    );
  }

  @override
  Future<ApiResponse> userIsExpectingReceipt(UserProfile user) {
    return fetch(
      Api.GET,
      "/fin/expecting_receipt/${user.id}",
      transformer: (data) => bool.parse(data)
    );
  }

  @override
  Future<ApiResponse> confirmTransactionSent(Bid bid, Map source) {
    return fetch(
      Api.PUT,
      "/le/complete",
      body: {
        "bid": bid.dict,
        "source": source
      },
      transformer: (data) => int.parse(data)
    );
  }

  @override
  Future<ApiResponse> confirmTransactionReceipt(Bid bid) {
    return fetch(
      Api.PUT,
      "/le/received",
      body: bid.dict,
      transformer: (data) => int.parse(data)
    );
  }

  @override
  Future<ApiResponse> getUserCurrentLoan(UserProfile user) {
    return fetch(
      Api.GET,
      "/fin/debt/${user.id!}",
      transformer: (data) => data == null.toString() ? false : Lo.fromJson(encoding.jsonDecode(data))
    );
  }

  @override
  Future<ApiResponse> getUserCurrentLendOuts(UserProfile user) {
    return fetch(
      Api.GET,
      "/fin/lends/${user.id!}",
      transformer: (data) => (encoding.jsonDecode(data) as List).map((json) => Lo.fromJson(json)).toList(growable: false)
    );
  }

  @override
  Future<ApiResponse> payInstalment(Lo lo, int amount, Map source) {
    return fetch(
      Api.POST,
      "/fin/repay/${lo.id}",
      body: {
        "amount": amount,
        "source": source
      },
      transformer: (data) => int.parse(data)
    );
  }

  @override
  Future<ApiResponse> checkIfUserIsOwed(UserProfile user) {
    return fetch(
      Api.GET,
      "/fin/owed/${user.id!}",
      transformer: (data) => bool.parse(data)
    );
  }

  @override
  Future<ApiResponse> confirmInstalmentReceipt(Instalment instalment) {
    return fetch(
      Api.PUT,
      "/fin/confirm-instalment/${instalment.id}",
      transformer: (data) => data
    );
  }

  RetryClient get client {
    return _httpClient
      ?? RetryClient(
          http.Client(),
          delay: (retryCount) => const Duration(seconds: 3),
          when: (response) => statusIsNotAllowed(response.statusCode),
          onRetry: (request, response, retryCount) {
            print("Retrying api request the $retryCount time");
          },
        );
  }

  Future<ApiResponse> fetch(
      String requestMethod,
      String path,
      {
        String url = Api.URL,
        int port = Api.PORT,
        Map<String, String>? params,
        Object? body,
        required Object? Function(String) transformer
      }) async {
    Uri uri = Uri(scheme: "http", host: url, path: path, port: port, queryParameters: params);

    final request = http.Request(requestMethod, uri);
    request.headers.clear();
    request.headers.addAll({
      "Content-Type": "application/json"
    });

    if(body != null) {
      request.body = encoding.jsonEncode(body);

      print("Body Data to send: ${request.body}");
    }

    print("Requesting from URL: ${uri.toString()}");

    ApiResponse apiResponse = ApiResponse();

    try {
      final response = await client.send(request);

      apiResponse.statusCode = response.statusCode;

      if(statusIsNotAllowed(response.statusCode)) {
        throw HttpException(response.reasonPhrase ?? "err");
      }

      String responseStr = await response.stream.bytesToString();

      print("Data received: $responseStr");

      await destroy();

      apiResponse.data = transformer.call(responseStr);
    } on SocketException {
      apiResponse._error = "No internet connection. Please connect and try again...";
    } on HttpException {
      apiResponse._error = "Oops! An error occurred :( \nPlease try again :)";
    } on Exception {
      apiResponse._error = "Oops! Something went wrong:( \nPlease try again :)";
    }

    return apiResponse;
  }

  @override
  Future<void> destroy() async {
    try {
      _httpClient?.close();
      _httpClient = null;

      print("Destroyed the api client");
    } catch (e) {
      //do nothing
    }
  }
}
