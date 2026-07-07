import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/background.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: BackgroundHeader(),
                ),

                const SizedBox(height: 20),

                _buildProfileHeader(),

                const SizedBox(height: 20),

                // More detailed profile sections:
                _buildInfoSection(
                  title: "Basic Information",
                  children: [
                    _infoTile("Name", user?.displayName ?? "User"),
                    _infoTile("Email", user?.email ?? "Unknown"),
                  ],
                ),

                _buildInfoSection(
                  title: "Account Details",
                  children: [
                    _infoTile("UID", user?.uid ?? "Unknown"),
                    _infoTile(
                      "Last Login",
                      user?.metadata.lastSignInTime?.toLocal().toString() ??
                          "N/A",
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                _buildEditButton(),

                const SizedBox(height: 20),

                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // PROFILE HEADER (avatar + name)
  // ---------------------------
  Widget _buildProfileHeader() {
    return _glassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white.withOpacity(0.35),
            child: const Icon(Icons.person, size: 58, color: Colors.white),
          ),

          const SizedBox(height: 18),

          Text(
            user?.displayName ?? "User",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            user?.email ?? "Unknown email",
            style: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // GLASS INFORMATION SECTIONS
  // ---------------------------
  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _glassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // EDIT PROFILE BUTTON
  // ---------------------------
  Widget _buildEditButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.25),
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withOpacity(0.15),
        elevation: 3,
      ),
      icon: const Icon(Icons.edit),
      label: const Text(
        "Edit Profile",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
        ).then((_) => setState(() {})); // Refresh after edit
      },
    );
  }

  // ---------------------------
  // LOGOUT BUTTON
  // ---------------------------
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.85),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: const Text(
          "Logout",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ---------------------------
  // GLASS CONTAINER WIDGET
  // ---------------------------
  Widget _glassContainer({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.1,
            ),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =====================================================================
//                    EDIT PROFILE PAGE (within same file)
// =====================================================================

class EditProfilePage extends StatefulWidget {
  final User? user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.user?.displayName ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Display Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                await widget.user?.updateDisplayName(nameController.text);
                await widget.user?.reload(); // 🔥 force refresh
                Navigator.pop(context, true); // tell caller to refresh
                // Go back to ProfilePage
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
