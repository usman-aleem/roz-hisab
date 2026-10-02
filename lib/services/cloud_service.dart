import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'app_data.dart';

/// Google login + automatic cloud backup (Firestore).
///
/// Layout in Firestore (each user can only see THEIR OWN data):
///   users/{uid}                      -> profile (name, phone, email, budget)
///   users/{uid}/shoppingLists/{id}
///   users/{uid}/contacts/{id}        (entries are inside the contact)
///   users/{uid}/bills/{id}
///   users/{uid}/dailyItems/{id}
///
/// Rules of the game:
///  - The app ALWAYS works offline/without login. Cloud is optional.
///  - After login, the CLOUD is the source of truth on app start.
///  - Every local change is pushed ~2 seconds later; only changed
///    documents are written (keeps you inside the free quota).
class CloudService extends ChangeNotifier {
  CloudService._();
  static final CloudService instance = CloudService._();

  static const _cols = ['shoppingLists', 'contacts', 'bills', 'dailyItems'];

  bool available = false; // Firebase configured & initialised
  bool syncing = false;
  String? lastError;
  DateTime? lastSynced;

  bool _ready = false; // initial sync finished -> safe to push
  bool _applying = false;
  Timer? _debounce;
  Map<String, Map<String, String>>? _pushed; // col -> id -> json

  User? get user => available ? FirebaseAuth.instance.currentUser : null;
  bool get signedIn => user != null;

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      available = true;
      // Wait for a saved login session to load (max 5 s).
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (!available) debugPrint('Roz Hisab: cloud disabled ($e)');
    }
  }

  // ---------------- auth ----------------
  Future<bool> signIn() async {
    if (!available) {
      lastError = 'Cloud sync is not configured';
      return false;
    }
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
      lastError = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request')
          ? null
          : (e.message ?? e.code);
      notifyListeners();
      return false;
    } catch (e) {
      lastError = '$e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    _ready = false;
    _pushed = null;
    if (available) await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  // ---------------- helpers ----------------
  DocumentReference<Map<String, dynamic>> get _root =>
      FirebaseFirestore.instance.collection('users').doc(user!.uid);

  Map<String, List<Map<String, dynamic>>> _localMaps(AppData d) => {
        'shoppingLists': d.shoppingLists.map((e) => e.toJson()).toList(),
        'contacts': d.contacts.map((e) => e.toJson()).toList(),
        'bills': d.bills.map((e) => e.toJson()).toList(),
        'dailyItems': d.dailyItems.map((e) => e.toJson()).toList(),
      };

  void _rememberPushed(AppData d) {
    final maps = _localMaps(d);
    _pushed = {
      for (final c in _cols)
        c: {for (final m in maps[c]!) m['id'] as String: jsonEncode(m)},
    };
  }

  String _friendly(Object e) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'Permission denied. Check the Firestore rules.';
      }
      if (e.code == 'unavailable') return 'No internet connection';
      if (e.code == 'not-found' || e.code == 'failed-precondition') {
        return 'Firestore database has not been created';
      }
      return e.message ?? e.code;
    }
    return '$e';
  }

  // ---------------- push (local -> cloud) ----------------
  void onLocalChange(AppData d) {
    if (!_ready || _applying || !signedIn) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => pushAll(d));
  }

  Future<void> pushAll(AppData d) async {
    if (!signedIn) return;
    syncing = true;
    notifyListeners();
    try {
      final root = _root;
      final maps = _localMaps(d);
      final next = <String, Map<String, String>>{};
      final ops = <void Function(WriteBatch)>[];

      for (final col in _cols) {
        final ref = root.collection(col);
        Map<String, String> prev;
        final known = _pushed?[col];
        if (known == null) {
          final snap = await ref.get();
          prev = {for (final x in snap.docs) x.id: ''};
        } else {
          prev = known;
        }
        final byId = {for (final m in maps[col]!) m['id'] as String: m};
        final cur = {for (final e in byId.entries) e.key: jsonEncode(e.value)};

        for (final id in prev.keys) {
          if (!cur.containsKey(id)) ops.add((b) => b.delete(ref.doc(id)));
        }
        for (final e in cur.entries) {
          if (prev[e.key] != e.value) {
            final data = byId[e.key]!;
            ops.add((b) => b.set(ref.doc(e.key), data));
          }
        }
        next[col] = cur;
      }

      ops.add((b) => b.set(
            root,
            {
              'userName': d.userName,
              'userPhone': d.userPhone,
              'userEmail': d.userEmail,
              'monthlyBudget': d.monthlyBudget,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          ));

      for (var i = 0; i < ops.length; i += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final op in ops.skip(i).take(400)) {
          op(batch);
        }
        await batch.commit();
      }
      _pushed = next;
      lastSynced = DateTime.now();
      lastError = null;
    } catch (e) {
      lastError = _friendly(e);
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  // ---------------- pull (cloud -> local) ----------------
  Future<bool> cloudHasData() async => (await _root.get()).exists;

  Future<void> pull(AppData d, {required bool merge}) async {
    final root = _root;
    Future<List<Map<String, dynamic>>> read(String col) async {
      final s = await root.collection(col).get();
      return s.docs.map((x) => x.data()).toList();
    }

    final shopping = await read('shoppingLists');
    final contacts = await read('contacts');
    final bills = await read('bills');
    final daily = await read('dailyItems');
    final profile = (await root.get()).data();

    _applying = true;
    try {
      await d.applyCloud(
        shopping: shopping,
        contacts: contacts,
        bills: bills,
        daily: daily,
        profile: profile,
        merge: merge,
      );
    } finally {
      _applying = false;
    }
    _rememberPushed(d);
    lastSynced = DateTime.now();
  }

  // ---------------- flows ----------------
  /// App start: if already logged in, make this device match the cloud.
  Future<void> startupSync(AppData d) async {
    if (!signedIn) return;
    try {
      if (await cloudHasData()) {
        await pull(d, merge: false);
        _ready = true;
      } else {
        _ready = true;
        await pushAll(d);
      }
      lastError = null;
    } catch (e) {
      _ready = false;
      lastError = _friendly(e);
    }
    notifyListeners();
  }

  /// Login + first link. [askChoice] is only called when BOTH the
  /// cloud and this device already have data:
  /// 0 = take cloud, 1 = send this device, 2 = merge both, null = cancel.
  /// Returns an error message, or null on success.
  Future<String?> connect(AppData d, Future<int?> Function() askChoice) async {
    if (!await signIn()) return lastError;
    try {
      final cloud = await cloudHasData();
      final local = d.hasLocalData;

      if (!cloud) {
        _ready = true;
        await pushAll(d);
      } else if (!local) {
        await pull(d, merge: false);
        _ready = true;
      } else {
        final choice = await askChoice();
        if (choice == null) {
          await signOut();
          return null;
        }
        if (choice == 0) {
          await pull(d, merge: false);
          _ready = true;
        } else if (choice == 1) {
          _pushed = null; // forces cloud to be replaced by this device
          _ready = true;
          await pushAll(d);
        } else {
          await pull(d, merge: true);
          _ready = true;
          await pushAll(d);
        }
      }

      final gName = user?.displayName ?? '';
      if (d.userName.isEmpty && gName.isNotEmpty) {
        await d.setUserName(gName);
      }
      lastError = null;
      notifyListeners();
      return null;
    } catch (e) {
      lastError = _friendly(e);
      notifyListeners();
      return lastError;
    }
  }

  /// "Abhi sync karo": send pending changes, then fetch the newest.
  Future<void> syncNow(AppData d) async {
    if (!signedIn) return;
    syncing = true;
    notifyListeners();
    try {
      if (_ready) await pushAll(d);
      await pull(d, merge: false);
      _ready = true;
      lastError = null;
    } catch (e) {
      lastError = _friendly(e);
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
