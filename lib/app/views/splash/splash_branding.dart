import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Presentation only. Session restoration and routing belong to SplashView.
class SplashBranding extends StatelessWidget {
  final Animation<double> scale;
  final Widget? error;
  const SplashBranding({super.key, required this.scale, this.error});
  static const admin = false;
  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF082D25), lime = Color(0xFFC4ED93);
    final ink = admin ? Colors.white : emerald;
    final muted = admin ? const Color(0xFFA9C5B9) : const Color(0xFF64786E);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: admin ? [emerald, const Color(0xFF124C3C)] : [const Color(0xFFF8FAF5), const Color(0xFFE6F1E3)],
      )),
      child: Stack(fit: StackFit.expand, children: [
        Positioned(right: -150, top: -160, child: _Orbit(color: ink.withValues(alpha: .06), diameter: 440)),
        Positioned(left: -200, bottom: -220, child: _Orbit(color: ink.withValues(alpha: .07), diameter: 540)),
        SafeArea(child: LayoutBuilder(builder: (context, bounds) {
          return SingleChildScrollView(child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: bounds.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: admin ? lime : const Color(0xFF258B59), shape: BoxShape.circle)),
                    const SizedBox(width: 9),
                    Flexible(child: Text(admin ? 'INVESTPRO  /  ADMIN' : 'INVESTPRO  /  INVESTOR', style: GoogleFonts.poppins(fontSize: 10, letterSpacing: 2.3, fontWeight: FontWeight.w600, color: muted), textAlign: TextAlign.center)),
                  ]),
                  SizedBox(height: bounds.maxHeight < 460 ? 28 : 64),
                  ScaleTransition(scale: scale, child: Container(
                    width: 116, height: 116,
                    decoration: BoxDecoration(
                      color: admin ? lime : emerald,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [BoxShadow(color: emerald.withValues(alpha: admin ? .25 : .14), blurRadius: 38, offset: const Offset(0, 18))],
                    ),
                    child: CustomPaint(painter: _GrowthMark(color: admin ? emerald : lime)),
                  )),
                  const SizedBox(height: 30),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Invest', style: TextStyle(color: ink)),
                    TextSpan(text: 'Pro', style: TextStyle(color: admin ? lime : const Color(0xFF27855A))),
                  ]), style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.8)),
                  const SizedBox(height: 12),
                  Text(admin ? 'A clearer view.\nBetter decisions.' : 'Small steps.\nGreater possibilities.', textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 21, height: 1.4, fontWeight: FontWeight.w500, color: ink)),
                  const SizedBox(height: 14),
                  Text(admin ? 'Your investment workspace, connected.' : 'Your investment journey starts here.', textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, height: 1.6, color: muted)),
                  SizedBox(height: bounds.maxHeight < 460 ? 24 : 54),
                  SizedBox(width: 42, child: LinearProgressIndicator(minHeight: 3, borderRadius: BorderRadius.circular(4), color: admin ? lime : const Color(0xFF27855A), backgroundColor: ink.withValues(alpha: .10))),
                  const SizedBox(height: 14),
                  Text(admin ? 'Opening your workspace' : 'Getting things ready', style: GoogleFonts.poppins(fontSize: 10, letterSpacing: .5, color: muted)),
                  if (error != null) Padding(padding: const EdgeInsets.only(top: 20), child: error!),
                  const SizedBox(height: 28),
                  Text('INVEST WITH PERSPECTIVE', style: GoogleFonts.poppins(fontSize: 8, letterSpacing: 2, color: muted.withValues(alpha: .8))),
                ],
              ))),
            ),
          ));
        })),
      ]),
    );
  }
}

class _Orbit extends StatelessWidget {
  final Color color;
  final double diameter;
  const _Orbit({required this.color, required this.diameter});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: Container(width: diameter, height: diameter,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1)),
    padding: const EdgeInsets.all(40),
    child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1))),
  ));
}

class _GrowthMark extends CustomPainter {
  final Color color;
  const _GrowthMark({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var i = 0; i < 3; i++) {
      final height = 20.0 + i * 14;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28 + i * 22, 82 - height, 13, height), const Radius.circular(4)), paint);
    }
    final line = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..moveTo(30, 40)..lineTo(51, 27)..lineTo(65, 30)..lineTo(85, 17)..moveTo(74, 17)..lineTo(85, 17)..lineTo(85, 28), line);
  }
  @override
  bool shouldRepaint(_GrowthMark oldDelegate) => oldDelegate.color != color;
}
