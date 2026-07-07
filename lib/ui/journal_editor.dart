import 'package:flutter/material.dart';

class JournalEditor extends StatelessWidget {
  final TextEditingController titleCtrl;

  final TextEditingController contentCtrl;

  const JournalEditor({
    Key? key,

    required this.titleCtrl,

    required this.contentCtrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.symmetric(horizontal: 24),

      decoration: BoxDecoration(
        color: Colors.yellow.shade50,

        borderRadius: BorderRadius.circular(12),

        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4)),
        ],
      ),

      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            controller: titleCtrl,

            decoration: const InputDecoration(
              border: InputBorder.none,

              hintText: "Title...",

              hintStyle: TextStyle(fontWeight: FontWeight.bold),
            ),

            style: const TextStyle(
              fontFamily: "Courier",

              fontSize: 18,

              fontWeight: FontWeight.bold,
            ),
          ),

          const Divider(),

          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: NotebookLinesPainter()),
                ),

                TextField(
                  cursorColor: Colors.transparent,

                  controller: contentCtrl,

                  maxLines: null,

                  expands: true,

                  decoration: const InputDecoration(
                    border: InputBorder.none,

                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,

                      vertical: 14,
                    ),
                  ),

                  style: const TextStyle(
                    fontFamily: "Courier",

                    fontSize: 16,

                    height: 1.6,

                    color: Colors.brown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,

      text: const TextSpan(
        text: "Sample",

        style: TextStyle(fontSize: 16, height: 1.6, fontFamily: "Courier"),
      ),
    );

    textPainter.layout();

    // THIS is the real line height Flutter uses — exact, reliable

    final double actualLineHeight = textPainter.height;

    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.25)
      ..strokeWidth = 1;

    // Start slightly below padding, then adjust with your 10px upward shift

    const double paddingTop = 20;

    const double upwardShift = 10;

    double y = paddingTop - upwardShift;

    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

      y += actualLineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
