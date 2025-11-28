// lib/widgets/navbar.dart
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const MyNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      // ⭐ LOCAL OVERRIDE (fixes Material3 surface issue)
      data: Theme.of(context).copyWith(
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xffCABEF4),
          elevation: 0,
          selectedItemColor: Color(0xFF273F71),
          unselectedItemColor: Color(0x80273F71),
          type: BottomNavigationBarType.fixed,
        ),
        colorScheme: Theme.of(context).colorScheme.copyWith(
          surface: Colors.transparent, // ⭐ forces the container to show
        ),
      ),

      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFC5CAE9), // Your fixed pastel navbar color
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF273F71).withOpacity(0.1),
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: const Offset(0, -5),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            selectedItemColor: const Color(0xFF273F71),
            unselectedItemColor: const Color(0xFF273F71).withOpacity(0.5),
            currentIndex: widget.selectedIndex,
            onTap: widget.onTap,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: ' ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_outlined),
                label: ' ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.coffee_outlined),
                label: ' ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.adjust),
                label: ' ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                label: ' ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
