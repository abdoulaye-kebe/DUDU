import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../themes/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _iconController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Widget _buildFloatingIcon(IconData icon, double angle, double distance, Color color) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        final animatedAngle = angle + (_iconController.value * 2 * math.pi);
        final x = math.cos(animatedAngle) * distance;
        final y = math.sin(animatedAngle) * distance;
        
        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              icon,
              size: 40,
              color: color,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Icônes animées en arrière-plan
          Positioned.fill(
            child: Stack(
              children: [
                Center(child: _buildFloatingIcon(Icons.local_taxi, 0, 120, AppTheme.primaryColor)),
                Center(child: _buildFloatingIcon(Icons.directions_car, math.pi / 3, 140, AppTheme.secondaryColor)),
                Center(child: _buildFloatingIcon(Icons.person_pin_circle, 2 * math.pi / 3, 130, AppTheme.primaryColor)),
                Center(child: _buildFloatingIcon(Icons.route, math.pi, 125, AppTheme.secondaryColor)),
                Center(child: _buildFloatingIcon(Icons.attach_money, 4 * math.pi / 3, 135, AppTheme.primaryColor)),
                Center(child: _buildFloatingIcon(Icons.star, 5 * math.pi / 3, 145, AppTheme.secondaryColor)),
              ],
            ),
          ),
          
          // Contenu principal
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(25),
                                child: Image.asset(
                                  'assets/images/logo_dudu_off.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Titre DUDU PRO
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'DUDU PRO',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Message motivant en majuscule
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: const [
                                  Text(
                                    'GAGNEZ EN TOUTE LIBERTÉ',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Acceptez les courses qui vous conviennent',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textColor,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Indicateur de chargement
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
