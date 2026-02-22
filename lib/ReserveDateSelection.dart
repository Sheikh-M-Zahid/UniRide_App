import 'package:flutter/material.dart';

class ReserveDateSelection extends StatefulWidget {
  const ReserveDateSelection({super.key});

  @override
  State<ReserveDateSelection> createState() =>
      _ReserveDateSelectionState();
}

class _ReserveDateSelectionState
    extends State<ReserveDateSelection> {

  DateTime selectedDateTime =
  DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Column(
        children: [

          const SizedBox(height: 20),

          const Padding(
            padding:
            EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Choose a time",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () async {

                  DateTime? picked =
                  await showDatePicker(
                    context: context,
                    initialDate:
                    DateTime.now(),
                    firstDate:
                    DateTime.now(),
                    lastDate:
                    DateTime.now()
                        .add(const Duration(
                        days: 90)),
                  );

                  if (picked != null) {
                    setState(() {
                      selectedDateTime =
                          picked;
                    });
                  }
                },
                child: const Text(
                    "Select Date"),
              ),
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.black,
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                      color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}