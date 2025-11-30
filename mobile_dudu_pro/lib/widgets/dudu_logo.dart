import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class DuduLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;
  final Color? primaryColor;
  final Color? secondaryColor;
  final TextStyle? textStyle;
  final TextStyle? subtitleStyle;

  const DuduLogo({
    Key? key,
    this.size = 80.0,
    this.showText = true,
    this.showSubtitle = false,
    this.primaryColor,
    this.secondaryColor,
    this.textStyle,
    this.subtitleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AppTheme.primaryColor;
    final secondary = secondaryColor ?? AppTheme.secondaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo avec gradient moderne
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: size * 0.25,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Icon(
            Icons.local_taxi_rounded,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        
        if (showText) ...[
          SizedBox(height: size * 0.3),
          // Titre avec gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [primary, secondary],
            ).createShader(bounds),
            child: Text(
              'DUDU',
              style: textStyle ?? TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.35,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
        
        if (showSubtitle) ...[
          SizedBox(height: size * 0.1),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size * 0.2,
              vertical: size * 0.05,
            ),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
            child: Text(
              '🚀 Ton prix, ton choix, ton taxi',
              style: subtitleStyle ?? TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

// Logo compact pour les barres d'outils
class DuduLogoCompact extends StatelessWidget {
  final double size;
  final Color? color;

  const DuduLogoCompact({
    Key? key,
    this.size = 32.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppTheme.primaryColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Icon(
        Icons.local_taxi_rounded,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}

// Logo avec animation
class DuduLogoAnimated extends StatefulWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;
  final Duration animationDuration;

  const DuduLogoAnimated({
    Key? key,
    this.size = 80.0,
    this.showText = true,
    this.showSubtitle = false,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<DuduLogoAnimated> createState() => _DuduLogoAnimatedState();
}

class _DuduLogoAnimatedState extends State<DuduLogoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: DuduLogo(
              size: widget.size,
              showText: widget.showText,
              showSubtitle: widget.showSubtitle,
            ),
          ),
        );
      },
    );
  }
}












