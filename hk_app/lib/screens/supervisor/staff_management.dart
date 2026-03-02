import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/supabase_client.dart';
import '../../models/user_model.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<UserModel> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await supabase
        .from('users')
        .select()
        .eq('role', 'maid')
        .order('name');
    setState(() {
      _users = (data as List).map((e) => UserModel.fromMap(e)).toList();
      _loading = false;
    });
  }

  Future<void> _toggleActive(UserModel u) async {
    await supabase
        .from('users')
        .update({'active': !u.active})
        .eq('id', u.id);
    _load();
  }

  void _showDialog({UserModel? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user == null ? 'Yeni Personel' : 'Personeli Düzenle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'E-posta'),
                enabled: user == null,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Geçersiz e-posta' : null,
              ),
              if (user == null)
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              if (user == null) {
                // Use a separate, non-persistent client so the supervisor's
                // active session is never replaced by the new maid's session.
                final tempClient = SupabaseClient(
                  dotenv.env['SUPABASE_URL'] ?? '',
                  dotenv.env['SUPABASE_ANON_KEY'] ?? '',
                  authOptions: const AuthClientOptions(
                    autoRefreshToken: false,
                    detectSessionInUri: false,
                  ),
                );
                try {
                  final res = await tempClient.auth.signUp(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                  );
                  if (res.user != null) {
                    // Insert runs under the supervisor's session (main client)
                    await supabase.from('users').insert({
                      'id': res.user!.id,
                      'name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'role': 'maid',
                      'active': true,
                    });
                  }
                } finally {
                  await tempClient.dispose();
                }
              } else {
                await supabase
                    .from('users')
                    .update({'name': nameCtrl.text.trim()})
                    .eq('id', user.id);
              }
              _load();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = _users[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(u.name[0])),
                  title: Text(u.name),
                  subtitle: Text(u.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(u.active ? 'Aktif' : 'Pasif'),
                        backgroundColor:
                            u.active ? Colors.green[100] : Colors.red[100],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showDialog(user: u),
                      ),
                      IconButton(
                        icon: Icon(u.active
                            ? Icons.person_off_outlined
                            : Icons.person_outlined),
                        tooltip: u.active ? 'Pasife Al' : 'Aktifleştir',
                        onPressed: () => _toggleActive(u),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Personel'),
      ),
    );
  }
}
