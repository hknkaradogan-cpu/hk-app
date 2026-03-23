import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel?> signIn(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) return null;
    return _fetchUserProfile(res.user!.id);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<UserModel?> currentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return _fetchUserProfile(user.id);
  }

  Future<UserModel?> _fetchUserProfile(String uid) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await supabase
        .from('users')
        .update({'fcm_token': token})
        .eq('id', userId);
  }
}
