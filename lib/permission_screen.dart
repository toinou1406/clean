
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // For ActionButton & Aurora colors
import 'aurora_widgets.dart'; // For AuroraPainter

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _auroraController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    final result = await PhotoManager.requestPermissionExtend();

    if (result.hasAccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permission_granted', true);
      widget.onPermissionGranted();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Full photo access is required to use this app.'),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                PhotoManager.openSetting();
              },
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: AuroraPainter(
                        animation: _auroraController,
                        colors: const [etherealGreen, deepCyan, etherealGreen],
                        stops: const [0.2, 0.6, 1.0],
                        isAnimating: true,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Privacy First',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FastClean analyzes your photos directly on your device. Nothing is ever uploaded to a server.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: _isLoading
          ? const CircularProgressIndicator(
              key: ValueKey('loader'),
              valueColor: AlwaysStoppedAnimation<Color>(etherealGreen),
            )
          : ActionButton(
              key: const ValueKey('button'),
              label: 'Grant Access & Continue',
              onPressed: _requestPermission,
            ),
    );
  }
}
