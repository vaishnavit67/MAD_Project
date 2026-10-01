import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String destination =
        arguments?['name'] ?? 'Central Library';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Campus Navigation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      body: Column(
        children: [

          // ------------------------------------------------------------
          // MAP AREA
          // ------------------------------------------------------------

          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(22),
              ),

              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [

                      // Route
                      CustomPaint(
                        size: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        painter: CampusRoutePainter(),
                      ),

                      // --------------------------------------------------
                      // CURRENT LOCATION
                      // --------------------------------------------------

                      const Align(
                        alignment: Alignment(-0.76, 0.50),
                        child: _MapMarker(
                          icon: Icons.my_location,
                          label: 'You',
                          isCurrentLocation: true,
                        ),
                      ),

                      // --------------------------------------------------
                      // CHECKPOINT 1
                      // --------------------------------------------------

                      const Align(
                        alignment: Alignment(-0.45, 0.22),
                        child: _Checkpoint(label: '1'),
                      ),

                      // --------------------------------------------------
                      // CHECKPOINT 2
                      // --------------------------------------------------

                      const Align(
                        alignment: Alignment(-0.04, -0.04),
                        child: _Checkpoint(label: '2'),
                      ),

                      // --------------------------------------------------
                      // CHECKPOINT 3
                      // --------------------------------------------------

                      const Align(
                        alignment: Alignment(0.36, -0.30),
                        child: _Checkpoint(label: '3'),
                      ),

                      // --------------------------------------------------
                      // CHECKPOINT 4
                      // --------------------------------------------------

                      const Align(
                        alignment: Alignment(0.76, -0.63),
                        child: _Checkpoint(label: '4'),
                      ),

                      // --------------------------------------------------
                      // DESTINATION
                      // --------------------------------------------------

                      Align(
                        alignment: const Alignment(0.78, -0.82),
                        child: _MapMarker(
                          icon: Icons.location_on,
                          label: destination,
                        ),
                      ),

                      // --------------------------------------------------
                      // MAP LABEL
                      // --------------------------------------------------

                      const Positioned(
                        top: 18,
                        left: 18,
                        child: Text(
                          'Campus Map',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ------------------------------------------------------------
          // BOTTOM INFORMATION PANEL
          // ------------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),

            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Your destination',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // --------------------------------------------------------
                // RESPONSIVE DISTANCE / TIME
                // --------------------------------------------------------

                const Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          color: Color(0xFF155EEF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '850 m',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Color(0xFF155EEF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '~10 min',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 17),

                // --------------------------------------------------------
                // START ROUTE
                // --------------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Backend / real navigation will be added later.
                    },

                    icon: const Icon(Icons.navigation),

                    label: const Text(
                      'Start Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155EEF),
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

// ------------------------------------------------------------
// CHECKPOINT
// ------------------------------------------------------------

class _Checkpoint extends StatelessWidget {
  final String label;

  const _Checkpoint({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 30,
          height: 30,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: const Color(0xFF155EEF),
              width: 3,
            ),
          ),

          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF155EEF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'Checkpoint $label',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// MAP MARKER
// ------------------------------------------------------------

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCurrentLocation;

  const _MapMarker({
    required this.icon,
    required this.label,
    this.isCurrentLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: isCurrentLocation
                ? const Color(0xFF155EEF)
                : Colors.white,

            shape: BoxShape.circle,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),

          child: Icon(
            icon,
            size: 22,
            color: isCurrentLocation
                ? Colors.white
                : const Color(0xFF155EEF),
          ),
        ),

        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),

          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// ROUTE PAINTER
// ------------------------------------------------------------

class CampusRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    final routePaint = Paint()
      ..color = const Color(0xFF155EEF)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Starting point
    path.moveTo(
      size.width * 0.12,
      size.height * 0.75,
    );

    // Checkpoint 1
    path.lineTo(
      size.width * 0.27,
      size.height * 0.61,
    );

    // Checkpoint 2
    path.lineTo(
      size.width * 0.48,
      size.height * 0.48,
    );

    // Checkpoint 3
    path.lineTo(
      size.width * 0.68,
      size.height * 0.35,
    );

    // Destination
    path.lineTo(
      size.width * 0.88,
      size.height * 0.12,
    );

    canvas.drawPath(
      path,
      routePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}