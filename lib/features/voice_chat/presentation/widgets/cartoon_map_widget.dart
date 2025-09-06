import 'package:flutter/material.dart';

class CartoonMapWidget extends StatelessWidget {
  final double size;
  
  const CartoonMapWidget({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CartoonMapPainter(
          primaryColor: theme.colorScheme.primary,
          surfaceColor: theme.colorScheme.surface,
          onSurfaceColor: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class CartoonMapPainter extends CustomPainter {
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  
  CartoonMapPainter({
    required this.primaryColor,
    required this.surfaceColor, 
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Ground/grass base
    paint.color = Colors.green.shade300;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      paint,
    );
    
    // Road
    paint.color = Colors.grey.shade600;
    final roadPath = Path();
    roadPath.moveTo(0, size.height * 0.85);
    roadPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.75,
      size.width * 0.6, size.height * 0.8,
    );
    roadPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.85,
      size.width, size.height * 0.9,
    );
    roadPath.lineTo(size.width, size.height * 0.95);
    roadPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.9,
      size.width * 0.6, size.height * 0.85,
    );
    roadPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.8,
      0, size.height * 0.9,
    );
    roadPath.close();
    canvas.drawPath(roadPath, paint);
    
    // Castle
    _drawCastle(canvas, size, paint);
    
    // Tree
    _drawTree(canvas, size, paint);
    
    // Cloud above everything
    _drawCloud(canvas, size, paint);
  }
  
  void _drawCastle(Canvas canvas, Size size, Paint paint) {
    final castleX = size.width * 0.65;
    final castleY = size.height * 0.45;
    final castleWidth = size.width * 0.25;
    final castleHeight = size.height * 0.25;
    
    // Castle main body
    paint.color = Colors.grey.shade400;
    canvas.drawRect(
      Rect.fromLTWH(castleX, castleY, castleWidth, castleHeight),
      paint,
    );
    
    // Castle towers
    final towerWidth = castleWidth * 0.3;
    final towerHeight = castleHeight * 0.4;
    
    // Left tower
    canvas.drawRect(
      Rect.fromLTWH(
        castleX - towerWidth * 0.5, 
        castleY - towerHeight * 0.5, 
        towerWidth, 
        castleHeight + towerHeight * 0.5,
      ),
      paint,
    );
    
    // Right tower
    canvas.drawRect(
      Rect.fromLTWH(
        castleX + castleWidth - towerWidth * 0.5, 
        castleY - towerHeight * 0.5, 
        towerWidth, 
        castleHeight + towerHeight * 0.5,
      ),
      paint,
    );
    
    // Castle door
    paint.color = Colors.brown.shade800;
    canvas.drawRect(
      Rect.fromLTWH(
        castleX + castleWidth * 0.4,
        castleY + castleHeight * 0.5,
        castleWidth * 0.2,
        castleHeight * 0.5,
      ),
      paint,
    );
    
    // Castle windows
    paint.color = Colors.blue.shade800;
    final windowSize = castleWidth * 0.08;
    canvas.drawRect(
      Rect.fromLTWH(
        castleX + castleWidth * 0.2,
        castleY + castleHeight * 0.3,
        windowSize,
        windowSize,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        castleX + castleWidth * 0.7,
        castleY + castleHeight * 0.3,
        windowSize,
        windowSize,
      ),
      paint,
    );
  }
  
  void _drawTree(Canvas canvas, Size size, Paint paint) {
    final treeX = size.width * 0.2;
    final treeY = size.height * 0.5;
    
    // Tree trunk
    paint.color = Colors.brown.shade600;
    canvas.drawRect(
      Rect.fromLTWH(
        treeX - size.width * 0.02,
        treeY + size.height * 0.1,
        size.width * 0.04,
        size.height * 0.2,
      ),
      paint,
    );
    
    // Tree foliage (simple circular shapes)
    paint.color = Colors.green.shade600;
    canvas.drawCircle(
      Offset(treeX, treeY),
      size.width * 0.06,
      paint,
    );
    canvas.drawCircle(
      Offset(treeX - size.width * 0.04, treeY + size.height * 0.05),
      size.width * 0.05,
      paint,
    );
    canvas.drawCircle(
      Offset(treeX + size.width * 0.04, treeY + size.height * 0.05),
      size.width * 0.05,
      paint,
    );
  }
  
  void _drawCloud(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white;
    
    final cloudCenterX = size.width * 0.5;
    final cloudCenterY = size.height * 0.2;
    final cloudRadius = size.width * 0.08;
    
    // Main cloud body (multiple overlapping circles)
    canvas.drawCircle(
      Offset(cloudCenterX, cloudCenterY),
      cloudRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(cloudCenterX - cloudRadius * 0.6, cloudCenterY + cloudRadius * 0.2),
      cloudRadius * 0.8,
      paint,
    );
    canvas.drawCircle(
      Offset(cloudCenterX + cloudRadius * 0.6, cloudCenterY + cloudRadius * 0.2),
      cloudRadius * 0.8,
      paint,
    );
    canvas.drawCircle(
      Offset(cloudCenterX - cloudRadius * 0.3, cloudCenterY - cloudRadius * 0.4),
      cloudRadius * 0.6,
      paint,
    );
    canvas.drawCircle(
      Offset(cloudCenterX + cloudRadius * 0.3, cloudCenterY - cloudRadius * 0.4),
      cloudRadius * 0.6,
      paint,
    );
    
    // Add a subtle shadow/outline
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    paint.color = Colors.grey.shade300;
    
    canvas.drawCircle(
      Offset(cloudCenterX, cloudCenterY),
      cloudRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(cloudCenterX - cloudRadius * 0.6, cloudCenterY + cloudRadius * 0.2),
      cloudRadius * 0.8,
      paint,
    );
    canvas.drawCircle(
      Offset(cloudCenterX + cloudRadius * 0.6, cloudCenterY + cloudRadius * 0.2),
      cloudRadius * 0.8,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}