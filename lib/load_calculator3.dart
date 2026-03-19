import 'package:flutter/material.dart';

void main() {
  runApp(const LoadCalculator3App());
}

class LoadCalculator3App extends StatelessWidget {
  const LoadCalculator3App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoadCalculator3(),
    );
  }
}

class LoadCalculator3 extends StatefulWidget {
  const LoadCalculator3({super.key});

  @override
  State<LoadCalculator3> createState() => _LoadCalculator3State();
}

class _LoadCalculator3State extends State<LoadCalculator3> {
  int activeStep = 0;
  bool showMoreCalcTypes = false;

  String calcType = "Basic Circuit";
  String loadStyle = "Mixed Load";

  int breaker = 20;
  int voltage = 120;

  void openStep(int step) {
    setState(() {
      activeStep = step;
    });
  }

  Widget stepCard(int step, String title, Widget content) {
    final bool open = activeStep == step;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: open ? Colors.red : Colors.grey.shade600,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => openStep(step),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: open
                      ? const [Color(0xFFFF4B4B), Color(0xFFDD2C2C)]
                      : const [Color(0xFF4A4A4F), Color(0xFF2F2F34)],
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "${step + 1}. $title",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    open ? Icons.remove : Icons.add,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: content,
            ),
        ],
      ),
    );
  }

  Widget button(String text, bool selected, VoidCallback tap) {
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade600,
              width: 1.2,
            ),
            gradient: LinearGradient(
              colors: selected
                  ? const [Color(0xFFFF4B4B), Color(0xFFDD2C2C)]
                  : const [Color(0xFF4A4A4F), Color(0xFF2F2F34)],
            ),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget equalButtonRow<T>({
    required String label,
    required List<T> values,
    required T selectedValue,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(values.length, (index) {
            final value = values[index];
            final selected = value == selectedValue;

            return Expanded(
              child: Padding(
                padding:
                EdgeInsets.only(right: index == values.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => onSelected(value),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade600,
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        colors: selected
                            ? const [Color(0xFFFF4B4B), Color(0xFFDD2C2C)]
                            : const [Color(0xFF4A4A4F), Color(0xFF2F2F34)],
                      ),
                    ),
                    child: Text(
                      labelBuilder(value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget horizontalSelector<T>({
    required String label,
    required List<T> values,
    required T selectedValue,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = values[index];
              final selected = value == selectedValue;

              return GestureDetector(
                onTap: () => onSelected(value),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 78),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade600,
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      colors: selected
                          ? const [Color(0xFFFF4B4B), Color(0xFFDD2C2C)]
                          : const [Color(0xFF4A4A4F), Color(0xFF2F2F34)],
                    ),
                  ),
                  child: Text(
                    labelBuilder(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget modeSection() {
    final List<String> visibleCalcTypes = showMoreCalcTypes
        ? const ["Load Calc Dwelling", "Load Calc Commercial"]
        : const ["Basic Circuit", "Service Check"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Calculation Type",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  showMoreCalcTypes = !showMoreCalcTypes;

                  if (!showMoreCalcTypes &&
                      (calcType == "Load Calc Dwelling" ||
                          calcType == "Load Calc Commercial")) {
                    calcType = "Basic Circuit";
                  }

                  if (showMoreCalcTypes &&
                      (calcType == "Basic Circuit" ||
                          calcType == "Service Check")) {
                    calcType = "Load Calc Dwelling";
                  }
                });
              },
              icon: Icon(
                showMoreCalcTypes
                    ? Icons.keyboard_arrow_left
                    : Icons.keyboard_arrow_right,
                color: Colors.white70,
                size: 18,
              ),
              label: Text(
                showMoreCalcTypes ? "Back" : "More",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            button(
              visibleCalcTypes[0],
              calcType == visibleCalcTypes[0],
                  () => setState(() => calcType = visibleCalcTypes[0]),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => calcType = visibleCalcTypes[1]),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade600,
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      colors: calcType == visibleCalcTypes[1]
                          ? const [Color(0xFFFF4B4B), Color(0xFFDD2C2C)]
                          : const [Color(0xFF4A4A4F), Color(0xFF2F2F34)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          visibleCalcTypes[1],
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!showMoreCalcTypes) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Load Style",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            button(
              "Repeating Load",
              loadStyle == "Repeating Load",
                  () => setState(() => loadStyle = "Repeating Load"),
            ),
            button(
              "Mixed Load",
              loadStyle == "Mixed Load",
                  () => setState(() => loadStyle = "Mixed Load"),
            ),
          ],
        ),
      ],
    );
  }


  Widget circuitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        horizontalSelector<int>(
          label: "Breaker Size",
          values: const [15, 20, 30, 40, 50, 60, 70, 80, 90, 100],
          selectedValue: breaker,
          labelBuilder: (value) => "${value}A",
          onSelected: (value) {
            setState(() {
              breaker = value;
            });
          },
        ),
        const SizedBox(height: 18),
        equalButtonRow<int>(
          label: "Voltage",
          values: const [120, 208, 240, 277],
          selectedValue: voltage,
          labelBuilder: (value) => "$value",
          onSelected: (value) {
            setState(() {
              voltage = value;
            });
          },
        ),
      ],
    );
  }

  Widget instructionBar() {
    String text;

    if (activeStep == 0) {
      text =
      "Choose the calculation type first, then choose whether this will be a repeating load or a mixed load.";
    } else if (activeStep == 1) {
      text =
      "Select the breaker size and circuit voltage. Load behavior like continuous use will be entered later under Load Inputs.";
    } else {
      text = "Continue building the calculation step by step.";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Load Calculator"),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              "NEC",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                stepCard(0, "MODE", modeSection()),
                stepCard(1, "CIRCUIT INPUTS", circuitSection()),
                stepCard(2, "LOAD INPUTS", const SizedBox(height: 60)),
                stepCard(3, "CALCULATE", const SizedBox(height: 60)),
                stepCard(4, "RESULTS", const SizedBox(height: 60)),
              ],
            ),
          ),
          instructionBar(),
        ],
      ),
    );
  }
}