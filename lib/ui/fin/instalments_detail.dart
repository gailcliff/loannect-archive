import 'package:flutter/material.dart';
import 'package:loannect/dat/Instalment.dart';

class InstalmentsDetail extends StatelessWidget {
  final List<Instalment> instalments;

  const InstalmentsDetail({super.key, required this.instalments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Instalments"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40,),
          Expanded(
            child: ListView.separated(
              itemCount: instalments.length,
              itemBuilder: (context, pos) {
                final instalment = instalments[pos];
                return Ink(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "KSH ${instalment.amountStr}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Paid ${instalment.instalmentTimeAgo}"
                      )
                    ],
                  ),
                );
              },
              separatorBuilder: (context, pos) => const Divider(),
            ),
          )
        ],
      ),
    );
  }
}
