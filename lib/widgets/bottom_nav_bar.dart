// File: lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double itemWidth = MediaQuery.of(context).size.width / 5;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(0, Icons.favorite, 'Favorite'),
              _buildNavItem(1, Icons.person, 'Profile'),
              _buildNavItem(2, Icons.home, 'Home'),
              _buildNavItem(3, Icons.library_add_check_outlined, 'Booking'),
              _buildNavItem(4, Icons.help, 'Help'),
            ],
          ),
        ),
        if (widget.currentIndex >= 0 && widget.currentIndex <= 4)
          Positioned(
            top: -20,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(
                    (widget.currentIndex - 2) * itemWidth,
                    0,
                  ),
                  child: Transform.scale(
                    scale: value,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 33, 115, 72),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(255, 33, 115, 72).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        _getIcon(widget.currentIndex),
                        color: Colors.white,
                        size: 26,
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

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.group;
      case 1:
        return Icons.person;
      case 2:
        return Icons.home;
      case 3:
        return Icons.menu_book;
      case 4:
        return Icons.help;
      default:
        return Icons.circle;
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = widget.currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _animationController.reset();
          _animationController.forward();
          widget.onTap(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSelected
                ? SizedBox(height: 26)
                : SizedBox(
                    height: 26,
                    child: Icon(
                      icon,
                      color: Colors.grey,
                      size: 22,
                    ),
                  ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? Color.fromARGB(255, 33, 115, 72) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSelected ? 12 : 11,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
