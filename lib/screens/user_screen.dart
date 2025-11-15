import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserScreen extends StatefulWidget {
  final ApiService apiService;
  final String currentUserRole;

  const UserScreen({
    Key? key,
    required this.apiService,
    required this.currentUserRole,
  }) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<dynamic> users = [];
  int currentPage = 0;
  int totalPages = 1;
  int pageSize = 5;
  bool isLoading = false;
  String searchQuery = '';

  // Form Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;
  int? editingUserId;
  final List<String> allowedRoles = ['ADMIN', 'TEACHER', 'STUDENT'];

  @override
  void initState() {
    super.initState();
    fetchUsers(reset: true);
  }

  Future<void> fetchUsers({bool reset = false}) async {
    if (reset) {
      currentPage = 0;
      users = [];
      totalPages = 1;
    }

    setState(() => isLoading = true);

    try {
      final data = await widget.apiService.getUsersPaged(
        page: currentPage,
        size: pageSize,
        username: searchQuery.isEmpty ? null : searchQuery,
      );

      final content = (data['content'] is List) ? data['content'] : [];
      setState(() {
        users = content.where((u) => (u['role'] ?? '') != 'EMPLOYEE').toList();
        totalPages = data['totalPages'] ?? 1;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  void onSearchChanged(String value) {
    searchQuery = value.trim();
    fetchUsers(reset: true);
  }

  void _goToPreviousPage() {
    if (currentPage > 0) {
      currentPage--;
      fetchUsers();
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPages - 1) {
      currentPage++;
      fetchUsers();
    }
  }

  Future<void> refresh() async => fetchUsers(reset: true);

  void openUserForm({Map<String, dynamic>? user}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    if (user != null) {
      // EDIT
      editingUserId = user['id'];
      firstNameController.text = user['firstName'] ??
          user['student']?['firstName'] ??
          ''; // fallback if nested
      lastNameController.text =
          user['lastName'] ?? user['student']?['lastName'] ?? '';
      usernameController.text = user['username'] ?? '';
      emailController.text = user['email'] ?? '';
      selectedRole = user['role'] ?? '';
      passwordController.clear();
      confirmPasswordController.clear();
    } else {
      // CREATE
      editingUserId = null;
      firstNameController.clear();
      lastNameController.clear();
      usernameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      selectedRole = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editingUserId == null ? 'Create User' : 'Edit User'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'First name is required' : null,
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Last name is required' : null,
                ),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Username is required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    return emailRegex.hasMatch(val.trim()) ? null : 'Enter a valid email';
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: editingUserId == null ? 'Password' : 'New Password',
                  ),
                  validator: (val) {
                    if (editingUserId == null && (val == null || val.isEmpty)) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                if (editingUserId == null)
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Confirm password is required';
                      if (val != passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: allowedRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Role'),
                  onChanged: (val) => setState(() => selectedRole = val),
                  validator: (val) => val == null ? 'Role is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                saveUser(confirmPasswordController: confirmPasswordController);
              }
            },
            child: Text(editingUserId == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> saveUser({TextEditingController? confirmPasswordController}) async {
    if (selectedRole == null) return;

    final Map<String, dynamic> data = {
      'firstName': firstNameController.text.trim(),
      'lastName': lastNameController.text.trim(),
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'role': selectedRole!,
    };

    if (passwordController.text.trim().isNotEmpty) {
      data['password'] = passwordController.text.trim();
    } else if (editingUserId == null) {
      data['password'] = '123@'; // default password for new user
    }

    try {
      if (editingUserId == null) {
        await widget.apiService.createUser(data);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User created')));
      } else {
        await widget.apiService.updateUser(editingUserId!, data);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User updated')));
      }
      Navigator.pop(context);
      fetchUsers(reset: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await widget.apiService.deleteUser(id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User deleted')));
      fetchUsers(reset: true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: () => openUserForm(), icon: const Icon(Icons.add))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final u = users[index];
                            final firstName = u['firstName'] ?? u['student']?['firstName'] ?? '';
                            final lastName = u['lastName'] ?? u['student']?['lastName'] ?? '';
                            final username = u['username'] ?? '';
                            final email = u['email'] ?? '';
                            final role = u['role'] ?? '';

                            if (role == 'EMPLOYEE') return const SizedBox.shrink();

                            return Card(
                              margin: const EdgeInsets.all(10),
                              child: ListTile(
                                title: Text('$firstName $lastName'),
                                subtitle: Text('$username • $email • $role'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => openUserForm(user: u),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteUser(u['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 0 ? _goToPreviousPage : null,
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 12),
                  Text('Page ${currentPage + 1} of $totalPages'),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: currentPage < totalPages - 1 ? _goToNextPage : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
